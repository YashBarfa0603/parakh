from __future__ import annotations

from app.database import SessionLocal
from app.models import InspectionOCRItem
from app.services.declaration_extraction_service import (
    build_ocr_lines
)


db = SessionLocal()

try:
    ocr_items = (
        db.query(InspectionOCRItem)
        .filter(InspectionOCRItem.ocr_result_id == 2)
        .all()
    )

    print(f"OCR items found: {len(ocr_items)}")

    lines = build_ocr_lines(ocr_items)

    print(f"\nLines found: {len(lines)}")

    print("\nOCR lines:")

    for index, line in enumerate(lines, start=1):
        print(f"{index}: {line}")

finally:
    db.close()