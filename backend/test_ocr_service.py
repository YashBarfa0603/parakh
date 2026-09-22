from __future__ import annotations

from app.services.ocr_service import run_ocr
from app.services.image_quality_service import get_image_dimensions


IMAGE_PATH = "product.png"


with open(IMAGE_PATH, "rb") as file:
    image_bytes = file.read()


image_width, image_height = get_image_dimensions(image_bytes)


detections = run_ocr(
    image_bytes=image_bytes,
    filename=IMAGE_PATH,
    image_width=image_width,
    image_height=image_height
)


print(f"Image size: {image_width} x {image_height}")
print(f"Total detections: {len(detections)}")

for detection in detections:
    print(detection)