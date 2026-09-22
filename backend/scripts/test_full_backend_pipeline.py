from __future__ import annotations

import os
import sys
from fastapi.testclient import TestClient

# Add backend directory to sys.path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app.main import app
from app.database import Base, engine, SessionLocal
from app.models import (
    Inspector,
    InspectionImage,
    InspectionOCRResult,
    InspectionOCRItem,
)
from app.services.auth_service import hash_password, create_access_token

# Ensure all tables exist
Base.metadata.create_all(bind=engine)

client = TestClient(app)

def test_pipeline():

    # STEP 1: CREATE APPROVED INSPECTOR

    print("--- STEP 1: Creating Approved Inspector ---")

    db = SessionLocal()

    import time
    unique_id = int(time.time())

    inspector = Inspector(
        name="Test Inspector",
        email=f"inspector_{unique_id}@example.com",
        phone=f"987{unique_id % 10000000:07d}",
        inspector_id=f"INS-{unique_id}",
        department="Legal Metrology",
        designation="Senior Inspector",
        office="HQ",
        state="Delhi",
        district="New Delhi",
        city="New Delhi",
        password_hash=hash_password("Password@123"),
        account_status="APPROVED",
    )

    db.add(inspector)
    db.commit()
    db.refresh(inspector)

    token = create_access_token(inspector.id)
    headers = {"Authorization": f"Bearer {token}"}

    db.close()

    print(f"Inspector created: {inspector.email}")

    # STEP 2: CREATE INSPECTION

    print("\n--- STEP 2: Creating Inspection ---")

    res = client.post(
        "/api/inspections/",
        json={},
        headers=headers,
    )

    assert res.status_code == 200, res.text

    inspection_id = res.json()["inspection_id"]

    print(f"Inspection created with ID: {inspection_id}")

    # STEP 3: SEED MOCK IMAGE + OCR DATA

    print("\n--- STEP 3: Seeding Mock Active Image & OCR Items ---")

    db = SessionLocal()

    # Mock inspection image

    img = InspectionImage(
        inspection_id=inspection_id,
        angle="FRONT",
        capture_source="CAMERA",
        image_url="http://example.com/test.jpg",
        cloudinary_public_id="test_public_id",
        sha256="abc123sha256hash",
        capture_width=1080,
        capture_height=1920,
        image_quality="GOOD",
        authenticity_status="VERIFIED",
        is_active=True,
    )

    db.add(img)
    db.commit()
    db.refresh(img)

    # Mock OCR result

    ocr_res = InspectionOCRResult(
        inspection_image_id=img.id,
        model_name="NVIDIA Nemotron OCR v2",
        status="SUCCESS",
        full_text=(
            "BRAND: Haldiram's\n"
            "Potato Chips\n"
            "Net Wt: 500 g\n"
            "MRP Rs 120.00 (incl. of all taxes)\n"
            "Mfg Date: 12/2025\n"
            "Use by: 06/2026\n"
            "Batch No: BATCH-9988\n"
            "Country of Origin: India\n"
            "Consumer Care: 1800-111-2222 care@haldirams.com"
        ),
    )

    db.add(ocr_res)
    db.commit()
    db.refresh(ocr_res)

    # Mock OCR items
    #
    # IMPORTANT:
    # Each OCR item gets a different bbox_y value.
    #
    # This simulates actual OCR output where every text line
    # appears at a different vertical position.
    #
    # Previously all items had bbox_y=10, causing the extraction
    # service to treat the entire OCR result as ONE line.

    mock_texts = [
        ("BRAND: Haldiram's", 0.98),
        ("Potato Chips", 0.95),
        ("Net Wt: 500 g", 0.96),
        ("MRP Rs 120.00 (incl. of all taxes)", 0.97),
        ("Mfg Date: 12/2025", 0.94),
        ("Use by: 06/2026", 0.93),
        ("Batch No: BATCH-9988", 0.99),
        ("Country of Origin: India", 0.95),
        ("Consumer Care: 1800-111-2222 care@haldirams.com", 0.96),
    ]

    for index, (text, conf) in enumerate(mock_texts):

        item = InspectionOCRItem(
            ocr_result_id=ocr_res.id,
            text=text,
            confidence=conf,

            # Simulate realistic OCR bounding boxes
            bbox_x=10,
            bbox_y=50 + (index * 50),
            bbox_width=400,
            bbox_height=30,
        )

        db.add(item)

    db.commit()
    db.close()

    print("Mock OCR items seeded successfully.")

    # STEP 4: TRIGGER ANALYSIS

    print("\n--- STEP 4: Triggering Analysis (/analyze) ---")

    res = client.post(
        f"/api/inspections/{inspection_id}/analyze",
        headers=headers,
    )

    assert res.status_code == 200, res.text

    analysis_data = res.json()

    print(f"Analysis status: {analysis_data['status']}")
    print(f"Compliance result: {analysis_data['compliance_result']}")
    print(f"Declarations extracted: {analysis_data['declarations_extracted']}")
    print(f"Findings generated: {analysis_data['findings_generated']}")

    # STEP 5: VERIFY INSPECTION DETAILS

    print("\n--- STEP 5: Verifying GET /api/inspections/{id} ---")

    res = client.get(
        f"/api/inspections/{inspection_id}",
        headers=headers,
    )

    assert res.status_code == 200, res.text

    details = res.json()

    print(f"Product Name: {details['product_name']}")
    print(f"Net Quantity: {details['net_quantity']}")
    print(f"MRP: {details['mrp']}")

    print(
        f"Batch Number: "
        f"{details['batch']['batch_number'] if details['batch'] else None}"
    )

    # STEP 6: MANUAL DECLARATION UPDATE

    print("\n--- STEP 6: Updating Declarations Manually (PUT /declarations) ---")

    decl_update = {
        "declarations": [
            {
                "field_name": "PRODUCT_NAME",
                "value": "Haldiram Classic Potato Chips",
                "raw_value": "Potato Chips",
            }
        ]
    }

    res = client.put(
        f"/api/inspections/{inspection_id}/declarations",
        json=decl_update,
        headers=headers,
    )

    assert res.status_code == 200, res.text

    print(
        "Declarations updated manually and compliance "
        "re-evaluated successfully."
    )

    # STEP 7: FINALIZE INSPECTION

    print("\n--- STEP 7: Finalizing Inspection (/finalize) ---")

    res = client.post(
        f"/api/inspections/{inspection_id}/finalize",
        headers=headers,
    )

    assert res.status_code == 200, res.text

    fin_data = res.json()

    print(
        f"Canonical Integrity Hash (SHA-256): "
        f"{fin_data['canonical_hash']}"
    )

    print(f"Finalized At: {fin_data['finalized_at']}")

    print(
        f"Report URL: "
        f"{fin_data['report']['pdf_url']}"
    )

    # STEP 8: DOWNLOAD PDF REPORT

    print("\n--- STEP 8: Downloading PDF Report ---")

    res = client.get(
        f"/api/inspections/{inspection_id}/report",
        headers=headers,
    )

    assert res.status_code == 200, res.text

    print(f"Report PDF Size: {len(res.content)} bytes")

    # FINAL RESULT

    print(
        "\n✅ FULL PIPELINE INTEGRATION TEST "
        "PASSED SUCCESSFULLY!"
    )

if __name__ == "__main__":
    test_pipeline()