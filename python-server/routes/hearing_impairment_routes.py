from fastapi import APIRouter, HTTPException, UploadFile, File, Request, Form
from pydantic import BaseModel
from typing import List, Optional
import logging
import os
import tempfile

import numpy as np

router = APIRouter()
logger = logging.getLogger(__name__)

# Class labels produced by sign_lang_model.tflite (88 classes, index → label)
TFLITE_CLASS_NAMES = [
    '1', '10', '100', '103', '105', '109', '11', '110', '12', '124',
    '13', '130', '135', '14', '140', '15', '150', '16', '160', '165',
    '17', '170', '18', '19', '190', '199', '2', '20', '200', '210',
    '220', '230', '24', '25', '26', '28', '3', '30', '32', '34',
    '35', '36', '38', '4', '40', '45', '5', '50', '52', '54',
    '55', '56', '58', '6', '60', '62', '64', '66', '68', '69',
    '7', '70', '72', '74', '75', '76', '78', '8', '80', '83',
    '84', '85', '88', '9', '90', '92', '94', '95', '96', '97',
    '98', '99', 'danta-ja na', 'murda-ja na', 'sa', 'saa', 'sha', 'shaa',
]

# Model expects (1, 40, 63): 40 frames, 21 landmarks × (x, y, z)
TFLITE_SEQ_LEN = 40
TFLITE_FEATURE_SIZE = 63


# Request/Response models
class PredictionRequest(BaseModel):
    features: List[float]
    description: Optional[str] = None

class PredictionResponse(BaseModel):
    prediction: str
    confidence: Optional[float] = None
    success: bool
    message: str


# ---------------------------
# Endpoints
# ---------------------------

@router.get("/health")
async def health_check(request: Request):
    """Check whether the sign language TFLite model is loaded."""
    try:
        models = getattr(request.app.state, "models", {})
        loaded = "hearing_impairment_tflite" in models
        return {
            "status": "healthy" if loaded else "model_missing",
            "model": "sign_lang_model.h5",
            "loaded": loaded,
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
    Predict sign from uploaded video using the unified TFLite model.
    Extracts 40 frames × 63 MediaPipe hand landmark features, normalizes,
    and runs inference.
    """
    logger.info(
        f"==========================================================\n"
        f"     NEW VIDEO PREDICTION REQUEST RECEIVED\n"
        f"==========================================================\n"
        f"Filename    : {video.filename}\n"
        f"Description : {description}\n"
        f"=========================================================="
    )

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

    temp_video_path = None

    try:
        suffix = ".mp4"
        if video.filename and "." in video.filename:
            suffix = "." + video.filename.rsplit(".", 1)[-1].lower()

        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_video_path = tmp.name
            content = await video.read()
            tmp.write(content)

        if not content:
            raise HTTPException(status_code=400, detail="Uploaded video is empty")

        logger.info(f"[PREDICT_VIDEO] Received video: {video.filename} ({len(content)} bytes)")

        # Retrieve TFLite interpreter
        try:
            from services.model_loader import get_model
            interpreter = get_model(request, "hearing_impairment_tflite")
        except ValueError as e:
            raise HTTPException(status_code=500, detail=str(e))
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to load model: {str(e)}")

        # Extract raw (x, y, z) landmark vectors — normalization done separately
        try:
            vectors = await _extract_video_vectors(
                temp_video_path,
                max_samples=TFLITE_SEQ_LEN,
                include_z=True,
                normalize=False,
            )
            logger.info(f"[PREDICT_VIDEO] Extracted {len(vectors)} vectors from video")
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"[PREDICT_VIDEO] Vector extraction failed: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Vector extraction failed: {str(e)}")

        # Build fixed-length sequence and apply training-matched normalization
        try:
            seq = np.array(vectors, dtype=np.float32)

            if len(seq) >= TFLITE_SEQ_LEN:
                idx = np.linspace(0, len(seq) - 1, TFLITE_SEQ_LEN).astype(int)
                seq = seq[idx]
            else:
                pad = np.zeros((TFLITE_SEQ_LEN - len(seq), TFLITE_FEATURE_SIZE), dtype=np.float32)
                seq = np.vstack((seq, pad))

            seq = _normalize_sequence_tflite(seq)
            label, confidence = _run_inference(interpreter, seq)
            logger.info(f"[PREDICT_VIDEO] Prediction: {label}, confidence: {confidence:.4f}")
        except Exception as e:
            logger.error(f"[PREDICT_VIDEO] Inference failed: {str(e)}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

        return PredictionResponse(
            prediction=str(label),
            confidence=confidence,
            success=True,
            message="Prediction completed successfully",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[PREDICT_VIDEO] Unexpected error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Video processing failed: {str(e)}")

    finally:
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                os.unlink(temp_video_path)
            except Exception as e:
                logger.warning(f"[PREDICT_VIDEO] Failed to remove temp file: {temp_video_path} - {str(e)}")


# ---------------------------
# TFLite helpers
# ---------------------------

def _normalize_sequence_tflite(sequence: np.ndarray) -> np.ndarray:
    """
    Normalize a (40, 63) landmark sequence to match training preprocessing:
    - Reshape to (40, 21, 3)
    - Per frame: center on wrist (landmark 0), scale by max 3D distance from wrist
    - Flatten back to (40, 63)
    """
    seq = sequence.reshape(len(sequence), 21, 3)
    out = []
    for frame in seq:
        centered = frame - frame[0]
        scale = np.max(np.linalg.norm(centered, axis=1))
        if scale > 0:
            centered = centered / scale
        out.append(centered.flatten())
    return np.array(out, dtype=np.float32)


def _run_inference(model, sequence_40x63: np.ndarray):
    """
    Run Keras model inference on a normalized (40, 63) sequence.
    Returns (label_string, confidence_float).
    """
    inp = sequence_40x63.reshape(1, TFLITE_SEQ_LEN, TFLITE_FEATURE_SIZE).astype(np.float32)
    output = model.predict(inp, verbose=0)[0]  # (88,)
    class_idx = int(np.argmax(output))
    confidence = float(output[class_idx])
    label = TFLITE_CLASS_NAMES[class_idx]

    logger.debug(f"[INFERENCE] class_idx={class_idx}, label={label}, confidence={confidence:.4f}")
    return label, confidence


# ---------------------------
# Feature extraction
# ---------------------------

def _normalize_landmarks_42(vec42: List[float]) -> List[float]:
    pts = np.asarray(vec42, dtype=np.float32).reshape(21, 2)
    origin = pts[0].copy()
    pts = pts - origin
    max_dist = float(np.max(np.linalg.norm(pts, axis=1)))
    if max_dist > 0:
        pts = pts / max_dist
    return pts.reshape(-1).astype(np.float32).tolist()


def _normalize_landmarks_63(vec63: List[float]) -> List[float]:
    pts = np.asarray(vec63, dtype=np.float32).reshape(21, 3)
    origin = pts[0].copy()
    pts[:, :2] -= origin[:2]
    max_dist = float(np.max(np.linalg.norm(pts[:, :2], axis=1)))
    if max_dist > 0:
        pts[:, :2] /= max_dist
    return pts.reshape(-1).astype(np.float32).tolist()


async def _extract_video_vectors(
    video_path: str,
    max_samples: int = 40,
    include_z: bool = True,
    normalize: bool = False,
) -> List[List[float]]:
    """
    Extract hand landmark vectors from each frame of a video using MediaPipe.

    Args:
        video_path: Path to the video file.
        max_samples: Maximum number of frame vectors to return.
        include_z: If True, return (x, y, z) per landmark (63 features);
                   if False, return (x, y) only (42 features).
        normalize: If True, apply per-frame wrist-centred normalization.
    """
    expected_len = 63 if include_z else 42
    logger.info(
        f"[EXTRACT_VIDEO] Starting extraction from: {video_path} "
        f"(include_z={include_z}, feature_size={expected_len})"
    )

    try:
        import cv2
        import mediapipe as mp
        from mediapipe.tasks import python as mp_python
        from mediapipe.tasks.python import vision as mp_vision
    except ImportError as e:
        raise HTTPException(
            status_code=500,
            detail="Backend missing dependencies: install opencv-python and mediapipe",
        ) from e

    possible_paths = [
        os.path.join(os.path.dirname(__file__), "../models/mediapipe/hand_landmarker.task"),
        os.path.join(os.path.dirname(__file__), "../../python-server/models/mediapipe/hand_landmarker.task"),
        os.path.join(os.path.dirname(__file__), "../../../models/mediapipe/hand_landmarker.task"),
        os.path.join(os.getcwd(), "models/mediapipe/hand_landmarker.task"),
    ]

    TASK_MODEL_PATH = None
    for path in possible_paths:
        if os.path.exists(path):
            TASK_MODEL_PATH = path
            break

    if TASK_MODEL_PATH is None:
        raise HTTPException(
            status_code=500,
            detail=f"Missing MediaPipe task model file: hand_landmarker.task. Searched: {possible_paths}",
        )

    logger.info(f"[EXTRACT_VIDEO] Using hand_landmarker.task from: {TASK_MODEL_PATH}")

    try:
        base_options = mp_python.BaseOptions(model_asset_path=TASK_MODEL_PATH)
        options = mp_vision.HandLandmarkerOptions(base_options=base_options, num_hands=1)
        landmarker = mp_vision.HandLandmarker.create_from_options(options)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create HandLandmarker: {str(e)}")

    try:
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise HTTPException(status_code=400, detail="Could not open uploaded video")

        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        logger.info(f"[EXTRACT_VIDEO] Video info — FPS: {fps}, Total frames: {total_frames}")

        vectors: List[List[float]] = []
        frame_idx = 0
        frames_with_hands = 0

        try:
            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break

                frame_idx += 1

                try:
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                except Exception:
                    continue

                try:
                    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
                    result = landmarker.detect(mp_image)
                except Exception as e:
                    raise HTTPException(
                        status_code=500,
                        detail=f"Landmarker detect failed on frame {frame_idx}: {str(e)}",
                    )

                if result.hand_landmarks and len(result.hand_landmarks) > 0:
                    frames_with_hands += 1
                    hand = result.hand_landmarks[0]
                    vec: List[float] = []
                    try:
                        for lm in hand:
                            if include_z:
                                vec.extend([lm.x, lm.y, lm.z])
                            else:
                                vec.extend([lm.x, lm.y])

                        if len(vec) != expected_len:
                            continue

                        if normalize:
                            if include_z:
                                vec = _normalize_landmarks_63(vec)
                            else:
                                vec = _normalize_landmarks_42(vec)

                        vectors.append(vec)
                    except Exception:
                        continue

        finally:
            cap.release()
            landmarker.close()
            logger.info(
                f"[EXTRACT_VIDEO] Processed {frame_idx} frames, "
                f"{frames_with_hands} with hands detected"
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[EXTRACT_VIDEO] Unexpected error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Video extraction failed: {str(e)}")

    if not vectors:
        raise HTTPException(status_code=400, detail="No hand landmarks detected in the video")

    logger.info(f"[EXTRACT_VIDEO] Extracted {len(vectors)} feature vectors")
    return vectors
