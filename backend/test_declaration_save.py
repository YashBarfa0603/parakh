from __future__ import annotations

from app.database import SessionLocal
from app.models import InspectionOCRItem
from app.services.declaration_extraction_service import (
    build_ocr_lines,
    extract_declarations,
    save_extracted_declarations
)


db = SessionLocal()

try:

    ocr_result_id = 2
    inspection_id = 6

    ocr_items = (
        db.query(InspectionOCRItem)
        .filter(
            InspectionOCRItem.ocr_result_id == ocr_result_id
        )
        .all()
    )

    print(f"OCR items found: {len(ocr_items)}")

    # Build spatially grouped OCR lines
    lines = build_ocr_lines(ocr_items)

    print("\nOCR lines:")

    for index, line in enumerate(lines, start=1):
        print(f"{index}: {line}")

    # Extract declarations
    declarations = extract_declarations(lines)

    print("\nExtracted declarations:")

    if not declarations:
        print("No declarations detected.")

    for declaration in declarations:
        print(declaration)

    # Save declarations to database
    saved = save_extracted_declarations(
        db=db,
        inspection_id=inspection_id,
        ocr_result_id=ocr_result_id,
        declarations=declarations
    )

    print("\nSaved declarations:")

    if not saved:
        print("No declarations saved.")

    for declaration in saved:
        print(
            f"ID: {declaration.id} | "
            f"Field: {declaration.field_name} | "
            f"Value: {declaration.value} | "
            f"Confidence: {declaration.confidence} | "
            f"BBox: "
            f"({declaration.bbox_x}, "
            f"{declaration.bbox_y}, "
            f"{declaration.bbox_width}, "
            f"{declaration.bbox_height})"
        )

finally:
    db.close()