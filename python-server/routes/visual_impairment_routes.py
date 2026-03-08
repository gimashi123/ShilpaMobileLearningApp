from fastapi import APIRouter, HTTPException, UploadFile, File, Request
from pydantic import BaseModel
from typing import List
import numpy as np
import cv2
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

IMG_HEIGHT = 64
IMG_WIDTH = 64


class BraillePredictionResponse(BaseModel):
    digits: List[int]
    confidences: List[float]
    success: bool
    message: str


# -----------------------------
# Preprocess sheet
# -----------------------------
def preprocess_sheet(image_bytes):

    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        raise ValueError("Invalid image")

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    blur = cv2.GaussianBlur(gray,(5,5),0)

    binary = cv2.adaptiveThreshold(
        blur,
        255,
        cv2.ADAPTIVE_THRESH_MEAN_C,
        cv2.THRESH_BINARY_INV,
        11,
        2
    )

    return img, binary


# -----------------------------
# Detect braille dots
# -----------------------------
def detect_dots(binary):

    contours,_ = cv2.findContours(
        binary,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE
    )

    dots = []

    for cnt in contours:

        area = cv2.contourArea(cnt)

        if 30 < area < 400:

            x,y,w,h = cv2.boundingRect(cnt)

            cx = x + w//2
            cy = y + h//2

            dots.append((cx,cy))

    return dots


# -----------------------------
# Group dots into rows
# -----------------------------
def group_rows(dots):

    dots = sorted(dots,key=lambda x:x[1])

    rows = []
    current = []

    threshold = 60

    for dot in dots:

        if not current:
            current.append(dot)
            continue

        avg_y = sum([d[1] for d in current]) / len(current)

        if abs(dot[1] - avg_y) < threshold:
            current.append(dot)
        else:
            rows.append(current)
            current = [dot]

    if current:
        rows.append(current)

    return rows


# -----------------------------
# Crop cells around row center
# -----------------------------
def crop_cells(img, rows):

    crops = []

    height,width = img.shape[:2]

    for i,row in enumerate(rows):

        xs = [d[0] for d in row]
        ys = [d[1] for d in row]

        center_x = int(sum(xs)/len(xs))
        center_y = int(sum(ys)/len(ys))

        size = 90

        x1 = max(center_x - size,0)
        y1 = max(center_y - size,0)
        x2 = min(center_x + size,width)
        y2 = min(center_y + size,height)

        crop = img[y1:y2,x1:x2]

        crops.append(crop)

        # debug output
        cv2.imwrite(f"debug_cell_{i}.png", crop)

    return crops


# -----------------------------
# Preprocess cell for CNN
# -----------------------------
def preprocess_cell(cell):

    gray = cv2.cvtColor(cell, cv2.COLOR_BGR2GRAY)

    blur = cv2.GaussianBlur(gray,(5,5),0)

    _,thresh = cv2.threshold(
        blur,
        0,
        255,
        cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
    )

    thresh = cv2.resize(thresh,(IMG_WIDTH,IMG_HEIGHT))

    rgb = cv2.cvtColor(thresh,cv2.COLOR_GRAY2RGB)

    rgb = rgb.astype("float32") / 255.0

    rgb = np.expand_dims(rgb,axis=0)

    return rgb


# -----------------------------
# Predict digits
# -----------------------------
def predict_digits(model,crops):

    digits = []
    confidences = []

    for crop in crops:

        img = preprocess_cell(crop)

        probs = model.predict(img,verbose=0)[0]

        digit = int(np.argmax(probs))
        conf = float(np.max(probs))

        digits.append(digit)
        confidences.append(conf)

    return digits,confidences


# -----------------------------
# Health check
# -----------------------------
@router.get("/health")
async def health_check(request:Request):

    models = getattr(request.app.state,"models",{})

    loaded = "visual_impairment_braille_numbers" in models

    return {
        "status":"healthy" if loaded else "model_missing",
        "model_loaded":loaded
    }


# -----------------------------
# Predict sheet
# -----------------------------
@router.post("/predict-sheet",response_model=BraillePredictionResponse)
async def predict_sheet(
        request:Request,
        image:UploadFile = File(...)
):

    logger.info(f"Received sheet: {image.filename}")

    from services.model_loader import get_model
    model = get_model(request,"visual_impairment_braille_numbers")

    content = await image.read()

    img,binary = preprocess_sheet(content)

    dots = detect_dots(binary)

    if len(dots) == 0:
        raise HTTPException(status_code=400,detail="No braille dots detected")

    rows = group_rows(dots)

    crops = crop_cells(img,rows)

    digits,confidences = predict_digits(model,crops)

    logger.info(f"Predicted digits: {digits}")

    return BraillePredictionResponse(
        digits=digits,
        confidences=confidences,
        success=True,
        message="Sheet processed successfully"
    )