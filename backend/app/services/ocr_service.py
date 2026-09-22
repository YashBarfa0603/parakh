from __future__ import annotations

import os
import base64
import mimetypes
import httpx

from sqlalchemy.orm import Session
from ..models import InspectionOCRResult, InspectionOCRItem
from dotenv import load_dotenv

load_dotenv()

NVIDIA_API_KEY = os.getenv("NVIDIA_API_KEY")

if not NVIDIA_API_KEY:
    raise RuntimeError("NVIDIA_API_KEY is not set")

NEMOTRON_OCR_URL = (
    "https://ai.api.nvidia.com/v1/cv/nvidia/nemotron-ocr-v2"
)
#image send to nemotron
def send_image_to_nemotron(image_bytes: bytes, filename: str) -> dict:
    mime_type = mimetypes.guess_type(filename)[0] or "image/jpeg"

    encoded_image = base64.b64encode(image_bytes).decode("utf-8")

    payload = {
        "input": [
            {
                "type": "image_url",
                "url": f"data:{mime_type};base64,{encoded_image}"
            }
        ],
        "merge_levels": ["word"]
    }

    headers = {
        "Authorization": f"Bearer {NVIDIA_API_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    response = httpx.post(
        NEMOTRON_OCR_URL,
        headers=headers,
        json=payload,
        timeout=120
    )

    response.raise_for_status()

    return response.json()

#parse nemotron
def parse_nemotron_response(
    response: dict,
    image_width: int,
    image_height: int
) -> list[dict]:
    detections = []

    for page in response.get("data", []):
        for detection in page.get("text_detections", []):

            text_prediction = detection.get("text_prediction", {})
            bounding_box = detection.get("bounding_box", {})
            points = bounding_box.get("points", [])

            text = text_prediction.get("text")
            confidence = text_prediction.get("confidence")

            if not text or len(points) != 4:
                continue

            x_values = [point["x"] for point in points]
            y_values = [point["y"] for point in points]

            x_min = min(x_values)
            y_min = min(y_values)
            x_max = max(x_values)
            y_max = max(y_values)

            x = int(x_min * image_width)
            y = int(y_min * image_height)

            width = int((x_max - x_min) * image_width)
            height = int((y_max - y_min) * image_height)

            detections.append({
                "text": text,
                "confidence": confidence,
                "bbox": {
                    "x": x,
                    "y": y,
                    "width": width,
                    "height": height
                }
            })

    return detections

#mow combine them 
def run_ocr(
    image_bytes: bytes,
    filename: str,
    image_width: int,
    image_height: int
) -> list[dict]:
    
    response = send_image_to_nemotron(
        image_bytes=image_bytes,
        filename=filename
    )

    detections = parse_nemotron_response(
        response,
        image_width,
        image_height
)

    return detections

#now save ocr result
def save_ocr_result(
    db: Session,
    inspection_image_id: int,
    detections: list[dict]
) -> InspectionOCRResult:

    ocr_result = InspectionOCRResult(
        inspection_image_id=inspection_image_id,
        model_name="nvidia/nemotron-ocr-v2",
        model_version="v2",
        status="COMPLETED"
    )

    db.add(ocr_result)
    db.flush()

    for detection in detections:
        bbox = detection["bbox"]

        ocr_item = InspectionOCRItem(
            ocr_result_id=ocr_result.id,
            text=detection["text"],
            confidence=detection["confidence"],
            bbox_x=bbox["x"],
            bbox_y=bbox["y"],
            bbox_width=bbox["width"],
            bbox_height=bbox["height"]
        )

        db.add(ocr_item)

    db.commit()
    db.refresh(ocr_result)

    return ocr_result