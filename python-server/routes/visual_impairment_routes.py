from fastapi import APIRouter, HTTPException, UploadFile, File, Request
from pydantic import BaseModel
from typing import List, Optional
import logging
import numpy as np

router = APIRouter()
logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------
# Model info:
#   - CNN: 3x Conv2D (32, 64, 128 filters) + MaxPool, Dense(128), Dropout(0.4)
#   - Output: Softmax over 10 classes → digits 0–9
#   - Input: 64×64 RGB image, pixel values rescaled to [0, 1]
# -----------------------------------------------------------------------

# Expected input dimensions (must match training config)
IMG_HEIGHT = 64
IMG_WIDTH = 64
NUM_CLASSES = 10  # digits 0-9


# ---------------------------
# Response models
# ---------------------------

class BraillePredictionResponse(BaseModel):
    """Response model for Braille digit/number prediction."""
    number: int                  # e.g. 10 for two images predicting 1 and 0
    digits: List[int]            # individual digit results, e.g. [1, 0]
    confidences: List[float]     # per-digit softmax confidence, e.g. [0.94, 0.87]
    success: bool
    message: str


# ---------------------------
# Helper functions
# ---------------------------

def _load_and_preprocess_image(image_bytes: bytes) -> np.ndarray:
    """
    Decode raw image bytes, resize to 64×64, normalise pixel values to [0, 1].

    Args:
        image_bytes: Raw bytes of the uploaded image file.

    Returns:
        np.ndarray of shape (1, 64, 64, 3) — ready to feed into the model.

    Raises:
        ValueError: If the image cannot be decoded or has unexpected shape.
    """
    try:
        import cv2
    except ImportError as e:
        raise HTTPException(
            status_code=500,
            detail="Backend missing dependency: install opencv-python"
        ) from e

    # Decode compressed image bytes into a BGR numpy array
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        raise ValueError("Could not decode image. Ensure the file is a valid image (JPEG/PNG/etc.).")

    logger.debug(f"[PREPROCESS] Decoded image shape: {img.shape}")

    # Convert BGR → RGB (model was trained on RGB via ImageDataGenerator)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    # Resize to 64×64
    img_resized = cv2.resize(img_rgb, (IMG_WIDTH, IMG_HEIGHT), interpolation=cv2.INTER_AREA)
    logger.debug(f"[PREPROCESS] Resized image shape: {img_resized.shape}")

    # Rescale pixel values from [0, 255] → [0.0, 1.0]
    img_normalised = img_resized.astype(np.float32) / 255.0

    # Add batch dimension → (1, 64, 64, 3)
    img_batch = np.expand_dims(img_normalised, axis=0)
    logger.debug(f"[PREPROCESS] Final batch shape: {img_batch.shape}")

    return img_batch


def _predict_single_digit(model, image_bytes: bytes) -> tuple[int, float]:
    """
    Predict a single Braille digit (0–9) from image bytes.

    Args:
        model:       Loaded Keras Braille number model.
        image_bytes: Raw bytes of the uploaded image file.

    Returns:
        Tuple of (predicted_digit: int, confidence: float).
    """
    img_batch = _load_and_preprocess_image(image_bytes)

    # Run inference — output shape: (1, 10)
    probs = model.predict(img_batch, verbose=0)   # shape (1, 10)
    logger.debug(f"[PREDICT_DIGIT] Raw probabilities: {probs[0]}")

    predicted_class = int(np.argmax(probs[0]))          # class index == digit value (0-9)
    confidence = float(np.max(probs[0]))

    logger.info(f"[PREDICT_DIGIT] Predicted digit: {predicted_class}, confidence: {confidence:.4f}")
    return predicted_class, confidence


def _predict_multi_digit(model, images_bytes_list: List[bytes]) -> tuple[int, List[int], List[float]]:
    """
    Predict a multi-digit number from a list of image byte sequences.

    Each image in the list represents one digit in left-to-right order.
    For example, two images predicting '1' and '0' yield the number 10.

    This handles the edge case where numbers ≥ 10 cannot be represented
    by a single Braille digit image — the caller supplies one image per digit.

    Args:
        model:             Loaded Keras Braille number model.
        images_bytes_list: Ordered list of raw image bytes, one per digit.

    Returns:
        Tuple of:
          - number      (int):        The full assembled number (e.g. 10, 23)
          - digits      (List[int]):  Individual digit predictions (e.g. [1, 0])
          - confidences (List[float]): Per-digit softmax confidence
    """
    digits: List[int] = []
    confidences: List[float] = []

    for idx, img_bytes in enumerate(images_bytes_list):
        logger.info(f"[PREDICT_MULTI] Predicting digit {idx + 1}/{len(images_bytes_list)}...")
        digit, confidence = _predict_single_digit(model, img_bytes)
        digits.append(digit)
        confidences.append(confidence)

    # Assemble digits into the full number by treating them as decimal places
    # e.g. digits=[1, 0] → "10" → 10
    number = int("".join(str(d) for d in digits))
    logger.info(f"[PREDICT_MULTI] Assembled number: {number} from digits: {digits}")

    return number, digits, confidences


# ---------------------------
# Endpoints
# ---------------------------

@router.get("/health")
async def health_check(request: Request):
    """
    Check whether the Braille number model is loaded and ready.
    """
    try:
        models = getattr(request.app.state, "models", {})
        model_key = "visual_impairment_braille_numbers"
        is_loaded = model_key in models
        return {
            "status": "healthy" if is_loaded else "model_missing",
            "model_loaded": is_loaded,
            "model_key": model_key,
        }
    except Exception as e:
        logger.exception("[HEALTH] Health check error")
        return {"status": "unhealthy", "error": str(e)}


@router.post("/predict-image", response_model=BraillePredictionResponse)
async def predict_braille_number(
    request: Request,
    images: List[UploadFile] = File(
        ...,
        description=(
            "One or more Braille digit images. "
            "Supply a single image for digits 0–9. "
            "Supply multiple images (left-to-right) for multi-digit numbers, "
            "e.g. two images for '1' and '0' to represent the number 10."
        ),
    ),
):
    """
    Predict a Braille digit or multi-digit number from uploaded image(s).

    - **Single image**: predicts a digit between 0 and 9.
    - **Multiple images**: each image is predicted as one digit; digits are
      concatenated in order to form the full number (e.g. images for '1' + '0'
      → number 10).

    The model is a CNN trained on 64×64 Braille digit images (classes 0–9,
    ~88.5 % validation accuracy).
    """
    logger.info(
        f"[PREDICT_IMAGE] Received request with {len(images)} image(s): "
        f"{[img.filename for img in images]}"
    )

    # --- Validate at least one image ---
    if not images:
        raise HTTPException(status_code=400, detail="At least one image must be provided.")

    # --- Validate content types ---
    ALLOWED_CONTENT_TYPES = {
        "image/jpeg", "image/jpg", "image/png", "image/bmp",
        "image/webp", "image/tiff",
    }
    for img in images:
        ct = (img.content_type or "").lower()
        if ct and ct not in ALLOWED_CONTENT_TYPES:
            logger.warning(f"[PREDICT_IMAGE] Rejected unsupported content type: {ct} for file: {img.filename}")
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported image type '{ct}' for file '{img.filename}'. "
                       f"Allowed types: {', '.join(sorted(ALLOWED_CONTENT_TYPES))}",
            )

    # --- Retrieve the model ---
    try:
        from services.model_loader import get_model
        model = get_model(request, "visual_impairment_braille_numbers")
        logger.debug("[PREDICT_IMAGE] Braille number model retrieved successfully")
    except ValueError as e:
        logger.error(f"[PREDICT_IMAGE] Model not found: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        logger.error(f"[PREDICT_IMAGE] Failed to retrieve model: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to load model: {e}")

    # --- Read image bytes ---
    try:
        images_bytes_list: List[bytes] = []
        for img in images:
            content = await img.read()
            if not content:
                raise HTTPException(
                    status_code=400,
                    detail=f"Uploaded image '{img.filename}' is empty.",
                )
            logger.debug(f"[PREDICT_IMAGE] Read {len(content)} bytes from '{img.filename}'")
            images_bytes_list.append(content)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[PREDICT_IMAGE] Failed to read image bytes: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to read uploaded image(s): {e}")

    # --- Run prediction ---
    try:
        number, digits, confidences = _predict_multi_digit(model, images_bytes_list)
    except ValueError as e:
        logger.error(f"[PREDICT_IMAGE] Preprocessing error: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"[PREDICT_IMAGE] Prediction failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Prediction failed: {e}")

    n_images = len(images)
    msg = (
        f"Predicted digit {number} from 1 image."
        if n_images == 1
        else f"Predicted number {number} from {n_images} digit images: {digits}."
    )
    logger.info(f"[PREDICT_IMAGE] Success — {msg}")

    return BraillePredictionResponse(
        number=number,
        digits=digits,
        confidences=confidences,
        success=True,
        message=msg,
    )
