from fastapi import APIRouter, HTTPException, UploadFile, File, Request, Form
from pydantic import BaseModel
from typing import List, Optional
import logging
import os
import tempfile

import numpy as np

router = APIRouter()
logger = logging.getLogger(__name__)


# NOTE:
# Prefer loading model once at startup via app.state.models (recommended).
# This routes file uses `services.model_loader.get_model(request, "hearing_impairment")`.
# Ensure your model_loader.get_model is implemented to read from request.app.state.models.

# Request/Response models
class PredictionRequest(BaseModel):
    """Request model for sign number prediction"""
    features: List[float]
    description: Optional[str] = None

class PredictionResponse(BaseModel):
    """Response model for predictions"""
    prediction: int
    confidence: Optional[float] = None
    success: bool
    message: str


# ---------------------------
# Helpers
# ---------------------------

def _normalize_landmarks_42(vec42: List[float]) -> List[float]:
    """
    Normalize 42 floats (21 landmarks x,y):
    - reshape (21,2)
    - subtract wrist (index 0)
    - divide by max distance (scale)
    """
    pts = np.asarray(vec42, dtype=np.float32).reshape(21, 2)
    origin = pts[0].copy()
    pts = pts - origin
    max_dist = float(np.max(np.linalg.norm(pts, axis=1)))
    if max_dist > 0:
        pts = pts / max_dist
    return pts.reshape(-1).astype(np.float32).tolist()


async def _extract_video_vectors_42(video_path: str, max_samples: int = 40) -> List[List[float]]:
    """
    Extract multiple 42-length (x,y) landmark vectors from a video using MediaPipe Tasks HandLandmarker.
    Requires: mediapipe + opencv-python
    Also requires a hand landmarker model file: hand_landmarker.task
    """
    logger.info(f"[EXTRACT_VIDEO] Starting video extraction from: {video_path}")
    
    try:
        import cv2
        import mediapipe as mp
        from mediapipe.tasks import python as mp_python
        from mediapipe.tasks.python import vision as mp_vision
        logger.debug("[EXTRACT_VIDEO] Successfully imported MediaPipe and OpenCV dependencies")
    except ImportError as e:
        logger.error(f"[EXTRACT_VIDEO] ImportError - Missing dependencies: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Backend missing dependencies: install opencv-python and mediapipe"
        ) from e

    # You MUST download this model file once and place it in your backend (example path below).
    # Try multiple possible paths for the model file
    possible_paths = [
        # Path 1: Relative to routes file (python-server/routes/)
        os.path.join(os.path.dirname(__file__), "../models/mediapipe/hand_landmarker.task"),
        # Path 2: Relative to python-server root
        os.path.join(os.path.dirname(__file__), "../../python-server/models/mediapipe/hand_landmarker.task"),
        # Path 3: Absolute path from workspace root
        os.path.join(os.path.dirname(__file__), "../../../models/mediapipe/hand_landmarker.task"),
        # Path 4: Direct path from cwd (when running python app.py from python-server/)
        os.path.join(os.getcwd(), "models/mediapipe/hand_landmarker.task"),
    ]
    
    TASK_MODEL_PATH = None
    logger.debug(f"[EXTRACT_VIDEO] Current working directory: {os.getcwd()}")
    logger.debug(f"[EXTRACT_VIDEO] Routes file directory: {os.path.dirname(__file__)}")
    logger.debug(f"[EXTRACT_VIDEO] Searching for hand_landmarker.task in multiple locations...")
    
    for path in possible_paths:
        logger.debug(f"[EXTRACT_VIDEO]   Checking: {path}")
        if os.path.exists(path):
            TASK_MODEL_PATH = path
            logger.debug(f"[EXTRACT_VIDEO]   ✓ Found at: {path}")
            break
    
    if TASK_MODEL_PATH is None:
        logger.error(f"[EXTRACT_VIDEO] Model file not found in any of these locations:")
        for path in possible_paths:
            logger.error(f"[EXTRACT_VIDEO]   - {path}")
        raise HTTPException(
            status_code=500,
            detail=f"Missing MediaPipe task model file: hand_landmarker.task. Searched in: {', '.join(possible_paths)}"
        )
    
    logger.info(f"[EXTRACT_VIDEO] Using hand_landmarker.task from: {TASK_MODEL_PATH}")

    # Create landmarker
    try:
        logger.debug("[EXTRACT_VIDEO] Creating HandLandmarker with model...")
        base_options = mp_python.BaseOptions(model_asset_path=TASK_MODEL_PATH)
        options = mp_vision.HandLandmarkerOptions(
            base_options=base_options,
            num_hands=1
        )
        landmarker = mp_vision.HandLandmarker.create_from_options(options)
        logger.info("[EXTRACT_VIDEO] HandLandmarker created successfully")
    except Exception as e:
        logger.error(f"[EXTRACT_VIDEO] Failed to create HandLandmarker: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to create HandLandmarker: {str(e)}")

    try:
        logger.debug(f"[EXTRACT_VIDEO] Opening video file: {video_path}")
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            logger.error(f"[EXTRACT_VIDEO] Could not open video file: {video_path}")
            raise HTTPException(status_code=400, detail="Could not open uploaded video")
        
        logger.debug("[EXTRACT_VIDEO] Video file opened successfully")
        
        # Get video info
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        logger.info(f"[EXTRACT_VIDEO] Video info - FPS: {fps}, Total frames: {total_frames}")

        vectors: List[List[float]] = []
        frame_idx = 0
        processed_frames = 0
        frames_with_hands = 0

        try:
            while cap.isOpened() and len(vectors) < max_samples:
                ret, frame = cap.read()
                if not ret:
                    logger.debug(f"[EXTRACT_VIDEO] End of video reached. Processed {frame_idx} total frames")
                    break

                frame_idx += 1
                # Sample every 2nd frame to reduce CPU
                if frame_idx % 2 != 0:
                    continue

                processed_frames += 1
                logger.debug(f"[EXTRACT_VIDEO] Processing frame {frame_idx}")

                try:
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    logger.debug(f"[EXTRACT_VIDEO] Frame {frame_idx} converted to RGB, shape: {rgb.shape}")
                except Exception as e:
                    logger.warning(f"[EXTRACT_VIDEO] Failed to convert frame {frame_idx} to RGB: {str(e)}")
                    continue

                try:
                    mp_image = mp.Image(
                        image_format=mp.ImageFormat.SRGB,
                        data=rgb
                    )
                    logger.debug(f"[EXTRACT_VIDEO] MediaPipe Image created for frame {frame_idx}")
                except Exception as e:
                    logger.warning(f"[EXTRACT_VIDEO] Failed to create MediaPipe Image for frame {frame_idx}: {str(e)}")
                    continue

                try:
                    logger.debug(f"[EXTRACT_VIDEO] Running landmarker detection on frame {frame_idx}")
                    result = landmarker.detect(mp_image)
                    logger.debug(f"[EXTRACT_VIDEO] Landmarker detection completed for frame {frame_idx}")
                except Exception as e:
                    logger.error(f"[EXTRACT_VIDEO] Landmarker detect failed on frame {frame_idx}: {str(e)}", exc_info=True)
                    raise HTTPException(status_code=500, detail=f"Landmarker detect failed on frame {frame_idx}: {str(e)}")

                if result.hand_landmarks and len(result.hand_landmarks) > 0:
                    frames_with_hands += 1
                    logger.debug(f"[EXTRACT_VIDEO] Hand landmarks detected in frame {frame_idx}")
                    hand = result.hand_landmarks[0]  # 21 landmarks
                    vec42: List[float] = []
                    try:
                        for lm in hand:
                            vec42.extend([lm.x, lm.y])  # 42 floats
                        
                        if len(vec42) != 42:
                            logger.warning(f"[EXTRACT_VIDEO] Expected 42 features, got {len(vec42)} in frame {frame_idx}")
                            continue
                        
                        logger.debug(f"[EXTRACT_VIDEO] Raw vector for frame {frame_idx}: min={min(vec42):.4f}, max={max(vec42):.4f}")
                        vec42 = _normalize_landmarks_42(vec42)  # same normalization
                        logger.debug(f"[EXTRACT_VIDEO] Normalized vector for frame {frame_idx}: min={min(vec42):.4f}, max={max(vec42):.4f}")
                        vectors.append(vec42)
                    except Exception as e:
                        logger.error(f"[EXTRACT_VIDEO] Failed to process landmarks from frame {frame_idx}: {str(e)}", exc_info=True)
                        continue
                else:
                    logger.debug(f"[EXTRACT_VIDEO] No hand landmarks detected in frame {frame_idx}")

        finally:
            cap.release()
            logger.info(f"[EXTRACT_VIDEO] Video capture released. Processed {processed_frames} frames, {frames_with_hands} with hands detected")
            landmarker.close()
            logger.debug("[EXTRACT_VIDEO] Landmarker closed")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[EXTRACT_VIDEO] Unexpected error during video extraction: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Video extraction failed: {str(e)}")

    logger.info(f"[EXTRACT_VIDEO] Extraction complete. Extracted {len(vectors)} feature vectors from {frames_with_hands} frames")
    
    if not vectors:
        logger.error("[EXTRACT_VIDEO] No hand landmarks were detected in the entire video")
        raise HTTPException(status_code=400, detail="No hand landmarks detected in the video")

    return vectors


def _majority_vote(preds: np.ndarray) -> int:
    values, counts = np.unique(preds, return_counts=True)
    return int(values[np.argmax(counts)])


# ---------------------------
# Endpoints
# ---------------------------

@router.post("/predict", response_model=PredictionResponse)
async def predict_sign_number(request: Request, body: PredictionRequest):
    """
    Predict sign number from a single 42-feature vector (client-side extracted).
    """
    logger.info(f"[PREDICT] Received prediction request with description: {body.description}")
    
    try:
        if not body.features:
            logger.warning("[PREDICT] Prediction request rejected: Features list is empty")
            raise HTTPException(status_code=400, detail="Features list cannot be empty")

        # Optional strict validation (recommended)
        if len(body.features) != 42:
            logger.warning(f"[PREDICT] Prediction request rejected: Expected 42 features, got {len(body.features)}")
            raise HTTPException(status_code=400, detail=f"Expected 42 features, got {len(body.features)}")

        logger.debug(f"[PREDICT] Raw features: min={min(body.features):.4f}, max={max(body.features):.4f}")

        # Get model loaded at startup
        try:
            logger.debug("[PREDICT] Attempting to retrieve hearing_impairment model...")
            from services.model_loader import get_model
            model = get_model(request, "hearing_impairment")
            logger.debug("[PREDICT] Model retrieved successfully")
        except ValueError as e:
            logger.error(f"[PREDICT] Model not found: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=str(e))
        except Exception as e:
            logger.error(f"[PREDICT] Failed to get model: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Failed to load model: {str(e)}")

        # If your model was trained on normalized features, normalize here too:
        try:
            features = _normalize_landmarks_42(body.features)
            logger.debug(f"[PREDICT] Normalized features: min={min(features):.4f}, max={max(features):.4f}")
        except Exception as e:
            logger.error(f"[PREDICT] Failed to normalize features: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Feature normalization failed: {str(e)}")

        try:
            logger.debug("[PREDICT] Running model prediction...")
            pred = model.predict([features])[0]
            logger.debug(f"[PREDICT] Raw prediction: {pred}")
        except Exception as e:
            logger.error(f"[PREDICT] Prediction failed: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

        confidence = None
        try:
            if hasattr(model, "predict_proba"):
                logger.debug("[PREDICT] Calculating confidence with predict_proba...")
                probs = model.predict_proba([features])[0]
                confidence = float(np.max(probs))
                logger.debug(f"[PREDICT] Prediction confidence: {confidence}")
        except Exception as e:
            logger.warning(f"[PREDICT] Failed to calculate confidence: {str(e)}", exc_info=True)
            # Don't fail the whole request if confidence calculation fails

        logger.info(f"[PREDICT] Prediction completed successfully: sign={pred}, confidence={confidence}")
        
        return PredictionResponse(
            prediction=int(pred),
            confidence=confidence,
            success=True,
            message="Prediction completed successfully",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[PREDICT] Unexpected error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@router.get("/health")
async def health_check(request: Request):
    """
    Checks whether the hearing impairment model is loaded in app.state.models
    """
    try:
        models = getattr(request.app.state, "models", {})
        ok = "hearing_impairment" in models
        return {
            "status": "healthy" if ok else "model_missing",
            "model_loaded": ok,
            "model_name": "hearing_impairment",
        }
    except Exception as e:
        logger.exception("Health check error")
        return {"status": "unhealthy", "error": str(e)}


@router.post("/predict-video", response_model=PredictionResponse)
async def predict_from_video(
    request: Request,
    video: UploadFile = File(...),
    description: Optional[str] = Form(None),
):
    """
    Predict sign number from uploaded video:
    - extract multiple 42-feature vectors using MediaPipe
    - predict each vector
    - majority vote for final prediction
    - optional confidence from predict_proba
    """
    logger.info(f"[PREDICT_VIDEO] Starting video prediction request. Filename: {video.filename}, Description: {description}")
    
    ALLOWED_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv", ".webm"}

    ext = os.path.splitext(video.filename)[1].lower() if video.filename else ""

    logger.info(
        f"[PREDICT_VIDEO] filename={video.filename}, "
        f"content_type={video.content_type}, detected_ext={ext}"
    )

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file extension: {ext}. Allowed: {', '.join(ALLOWED_EXTENSIONS)}",
    )



    # allowed_types = {
    #     "video/mp4",
    #     "video/quicktime",
    #     "video/x-msvideo",
    #     "video/x-matroska",
    #     "video/webm",
    # }

    # if video.content_type not in allowed_types:
    #     logger.warning(f"[PREDICT_VIDEO] Invalid video type rejected: {video.content_type}")
    #     raise HTTPException(
    #         status_code=400,
    #         detail=f"Invalid file type: {video.content_type}. Allowed: {', '.join(sorted(allowed_types))}",
    #     )

    temp_video_path = None

    try:
        # Save uploaded file to temp path
        suffix = ".mp4"
        if video.filename and "." in video.filename:
            suffix = "." + video.filename.rsplit(".", 1)[-1].lower()

        logger.debug(f"[PREDICT_VIDEO] Creating temp file with suffix: {suffix}")
        
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_video_path = tmp.name
            logger.debug(f"[PREDICT_VIDEO] Temp file created at: {temp_video_path}")
            
            content = await video.read()
            logger.debug(f"[PREDICT_VIDEO] Read {len(content)} bytes from uploaded file")
            
            tmp.write(content)
            logger.debug(f"[PREDICT_VIDEO] Wrote {len(content)} bytes to temp file")

        if not content:
            logger.warning("[PREDICT_VIDEO] Empty video file uploaded")
            raise HTTPException(status_code=400, detail="Uploaded video is empty")

        logger.info(f"[PREDICT_VIDEO] Received video: {video.filename} ({len(content)} bytes, type: {video.content_type})")

        # Extract feature vectors (each length=42)
        logger.info("[PREDICT_VIDEO] Starting video vector extraction...")
        try:
            vectors = await _extract_video_vectors_42(temp_video_path, max_samples=40)
            logger.info(f"[PREDICT_VIDEO] Successfully extracted {len(vectors)} vectors from video")
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"[PREDICT_VIDEO] Vector extraction failed: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Vector extraction failed: {str(e)}")

        # Get model loaded at startup
        try:
            logger.debug("[PREDICT_VIDEO] Attempting to retrieve hearing_impairment model...")
            from services.model_loader import get_model
            model = get_model(request, "hearing_impairment")
            logger.info("[PREDICT_VIDEO] Model retrieved successfully")
        except ValueError as e:
            logger.error(f"[PREDICT_VIDEO] Model not found or not loaded: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=str(e))
        except Exception as e:
            logger.error(f"[PREDICT_VIDEO] Failed to get model: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Failed to load model: {str(e)}")

        # Predict per-vector and majority vote
        try:
            logger.debug(f"[PREDICT_VIDEO] Running prediction on {len(vectors)} vectors...")
            preds = model.predict(vectors)
            logger.debug(f"[PREDICT_VIDEO] Raw predictions: {preds}")
            
            final_pred = _majority_vote(np.asarray(preds))
            logger.info(f"[PREDICT_VIDEO] Predictions from {len(vectors)} vectors: final prediction={final_pred}")
        except Exception as e:
            logger.error(f"[PREDICT_VIDEO] Prediction failed: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

        confidence = None
        try:
            if hasattr(model, "predict_proba"):
                logger.debug("[PREDICT_VIDEO] Model has predict_proba method, calculating confidence...")
                probs = model.predict_proba(vectors)  # (n_frames, n_classes)
                logger.debug(f"[PREDICT_VIDEO] Probabilities shape: {probs.shape}")
                confidence = float(np.mean(np.max(probs, axis=1)))
                logger.info(f"[PREDICT_VIDEO] Mean confidence from video: {confidence}")
            else:
                logger.debug("[PREDICT_VIDEO] Model does not have predict_proba method")
        except Exception as e:
            logger.warning(f"[PREDICT_VIDEO] Failed to calculate confidence: {str(e)}", exc_info=True)
            # Don't fail the whole request if confidence calculation fails

        logger.info(f"[PREDICT_VIDEO] Video prediction completed successfully: sign={final_pred}, confidence={confidence}")
        
        return PredictionResponse(
            prediction=int(final_pred),
            confidence=confidence,
            success=True,
            message="Prediction from video completed successfully",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[PREDICT_VIDEO] Unexpected error in video prediction: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Video processing failed: {str(e)}")

    finally:
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                os.unlink(temp_video_path)
                logger.debug(f"[PREDICT_VIDEO] Cleaned up temp video file: {temp_video_path}")
            except Exception as e:
                logger.warning(f"[PREDICT_VIDEO] Failed to remove temp video file: {temp_video_path} - {str(e)}")
