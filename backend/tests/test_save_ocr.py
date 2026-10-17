from __future__ import annotations

from app.database import SessionLocal
from app.services.ocr_service import run_ocr, save_ocr_result
from app.services.image_quality_service import get_image_dimensions


IMAGE_PATH = "product.png"


with open(IMAGE_PATH, "rb") as file:
    image_bytes = file.read()


image_width, image_height = get_image_dimensions(image_bytes)

db = SessionLocal()

try:
    detections = run_ocr(
        image_bytes=image_bytes,
        filename=IMAGE_PATH,
        image_width=image_width,
        image_height=image_height
    )

    ocr_result = save_ocr_result(
        db=db,
        inspection_image_id=7,
        detections=detections
    )

    print("OCR Result ID:", ocr_result.id)
    print("Status:", ocr_result.status)
    print("Detections saved:", len(ocr_result.items))

finally:
    db.close()