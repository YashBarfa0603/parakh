from __future__ import annotations

import os
import sys

backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app.services.declaration_extraction_service import (
    extract_declarations_from_multi_image_ocr,
)
from app.services.ner_service import run_ner, merge_ner_with_regex

class MockOCRItem:
    def __init__(self, id, text, bbox_x, bbox_y, bbox_width, bbox_height, confidence=0.95, source_image_id=None, angle=None):
        self.id = id
        self.text = text
        self.bbox_x = bbox_x
        self.bbox_y = bbox_y
        self.bbox_width = bbox_width
        self.bbox_height = bbox_height
        self.confidence = confidence
        self.source_image_id = source_image_id
        self.angle = angle

def test_front_and_back_separation():
    # FRONT Image items (image_id=1, angle="FRONT")
    front_items = [
        MockOCRItem(1, "LAY'S", bbox_x=100, bbox_y=100, bbox_width=300, bbox_height=50, source_image_id=1, angle="FRONT"),
        MockOCRItem(2, "CLASSIC SALTED", bbox_x=100, bbox_y=160, bbox_width=400, bbox_height=40, source_image_id=1, angle="FRONT"),
        MockOCRItem(3, "Net Wt. 50 g", bbox_x=100, bbox_y=220, bbox_width=200, bbox_height=25, source_image_id=1, angle="FRONT"),
    ]

    # BACK Image items (image_id=2, angle="BACK")
    # Notice bbox_y overlapping with FRONT items! In old code, they would merge horizontally!
    back_items = [
        MockOCRItem(4, "NUTRITION FACTS", bbox_x=50, bbox_y=100, bbox_width=400, bbox_height=45, source_image_id=2, angle="BACK"),
        MockOCRItem(5, "Protein 5g", bbox_x=50, bbox_y=150, bbox_width=200, bbox_height=20, source_image_id=2, angle="BACK"),
        MockOCRItem(6, "Serving Size 30g", bbox_x=50, bbox_y=175, bbox_width=200, bbox_height=20, source_image_id=2, angle="BACK"),
        MockOCRItem(7, "Manufactured by: PepsiCo India Holdings Pvt Ltd, Gurgaon, Haryana 122001", bbox_x=50, bbox_y=220, bbox_width=700, bbox_height=22, source_image_id=2, angle="BACK"),
        MockOCRItem(8, "MRP Rs 20.00 (incl. of all taxes)", bbox_x=50, bbox_y=270, bbox_width=400, bbox_height=24, source_image_id=2, angle="BACK"),
        MockOCRItem(9, "Batch No: PK-1092", bbox_x=50, bbox_y=310, bbox_width=300, bbox_height=20, source_image_id=2, angle="BACK"),
        MockOCRItem(10, "Mfg Date: 01/2026", bbox_x=50, bbox_y=340, bbox_width=300, bbox_height=20, source_image_id=2, angle="BACK"),
        MockOCRItem(11, "Expiry Date: 12/2026", bbox_x=50, bbox_y=370, bbox_width=300, bbox_height=20, source_image_id=2, angle="BACK"),
        MockOCRItem(12, "Consumer Care: 1800-222-3333 feedback@pepsico.com", bbox_x=50, bbox_y=410, bbox_width=600, bbox_height=20, source_image_id=2, angle="BACK"),
        MockOCRItem(13, "Country of Origin: India", bbox_x=50, bbox_y=450, bbox_width=350, bbox_height=20, source_image_id=2, angle="BACK"),
    ]

    all_items = front_items + back_items
    image_ocr_data = [
        {"image_id": 1, "angle": "FRONT", "items": front_items},
        {"image_id": 2, "angle": "BACK", "items": back_items},
    ]

    # Run extraction with image_ocr_data
    extracted = extract_declarations_from_multi_image_ocr(all_items, image_ocr_data=image_ocr_data)

    # Run NER strictly on FRONT items
    ner_result = run_ner(front_items)
    print("NER result on FRONT items:", ner_result)
    if ner_result:
        extracted = merge_ner_with_regex(extracted, ner_result)

    result_map = {d["field_name"]: d for d in extracted}

    print("\nExtracted Declarations:")
    for field, d in sorted(result_map.items()):
        print(f"  {field}: {d['value']} (conf={d.get('confidence')}, angle={d.get('angle')})")

    # Assertions
    # 1. Product Name must be "CLASSIC SALTED" (from FRONT, NOT Nutrition Facts!)
    assert "product_name" in result_map, "Missing product_name"
    assert "NUTRITION" not in result_map["product_name"]["value"].upper(), f"Corrupted product_name: {result_map['product_name']['value']}"
    assert "CLASSIC SALTED" in result_map["product_name"]["value"].upper(), f"Unexpected product_name: {result_map['product_name']['value']}"

    # 2. Brand must be "LAY'S"
    assert "brand" in result_map, "Missing brand"
    assert "LAY" in result_map["brand"]["value"].upper(), f"Unexpected brand: {result_map['brand']['value']}"

    # 3. Net quantity must be 50 g (NOT Protein 5g or Serving size 30g)
    assert "net_quantity" in result_map, "Missing net_quantity"
    assert "50" in result_map["net_quantity"]["value"], f"Wrong net quantity: {result_map['net_quantity']['value']}"
    assert "5g" not in result_map["net_quantity"]["value"], f"Extracted protein as net quantity: {result_map['net_quantity']['value']}"

    # 4. MRP must be 20.00
    assert "mrp" in result_map, "Missing mrp"
    assert "20" in result_map["mrp"]["value"], f"Wrong MRP: {result_map['mrp']['value']}"

    # 5. Manufacturer details
    assert "manufacturer_name" in result_map, "Missing manufacturer_name"
    assert "PepsiCo" in result_map["manufacturer_name"]["value"], f"Wrong manufacturer: {result_map['manufacturer_name']['value']}"

    # 6. Batch & Dates
    assert "batch_number" in result_map, "Missing batch_number"
    assert "PK-1092" in result_map["batch_number"]["value"]
    assert "expiry_date" in result_map, "Missing expiry_date"
    assert "12/2026" in result_map["expiry_date"]["value"]

    # 7. Customer Care
    assert "consumer_care_phone" in result_map, "Missing consumer_care_phone"
    assert "1800" in result_map["consumer_care_phone"]["value"]

    print("\nALL ASSERTIONS PASSED PERFECTLY!")

if __name__ == "__main__":
    test_front_and_back_separation()
