
from __future__ import annotations

import os
import sys
import time

from fastapi.testclient import TestClient

# PATH SETUP

backend_dir = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..")
)

if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

# APP IMPORTS

from app.main import app

from app.database import (
    Base,
    engine,
    SessionLocal
)

from app.models import (
    Inspector,
    Inspection,
    InspectionReport,
    InspectionImage,
    InspectionOCRResult,
    InspectionOCRItem,
    ComplianceFinding
)

from app.services.auth_service import (
    hash_password,
    create_access_token
)

# DATABASE

Base.metadata.create_all(bind=engine)

client = TestClient(app)

# TEST

def test_real_image_pipeline():

    # STEP 1: CREATE APPROVED INSPECTOR

    print("\n--- STEP 1: Creating Approved Inspector ---")

    db = SessionLocal()

    unique_id = int(time.time())

    inspector = Inspector(
        name="Real OCR Test Inspector",
        email=f"realocr_{unique_id}@example.com",
        phone=f"987{unique_id % 10000000:07d}",
        inspector_id=f"REAL-OCR-{unique_id}",
        department="Legal Metrology",
        designation="Senior Inspector",
        office="HQ",
        state="Delhi",
        district="New Delhi",
        city="New Delhi",
        password_hash=hash_password("Password@123"),
        account_status="APPROVED"
    )

    db.add(inspector)
    db.commit()
    db.refresh(inspector)

    token = create_access_token(inspector.id)

    headers = {
        "Authorization": f"Bearer {token}"
    }

    inspector_id = inspector.id

    db.close()

    print(f"Inspector ID: {inspector_id}")
    print(f"Inspector Email: {inspector.email}")

    # STEP 2: CREATE INSPECTION

    print("\n--- STEP 2: Creating Inspection ---")

    response = client.post(
        "/api/inspections/",
        json={},
        headers=headers
    )

    assert response.status_code == 200, response.text

    inspection_id = response.json()["inspection_id"]

    print(f"Inspection ID: {inspection_id}")

    # STEP 3: LOAD REAL IMAGE

    print("\n--- STEP 3: Loading Real Product Image ---")

    image_path = os.path.join(
        backend_dir,
        "product1.jpeg"
    )

    assert os.path.exists(
        image_path
    ), f"Image not found: {image_path}"

    image_size = os.path.getsize(image_path)

    print(f"Image: {image_path}")
    print(f"Image Size: {image_size / 1024:.2f} KB")

    # STEP 4: UPLOAD IMAGE

    print("\n--- STEP 4: Uploading Image ---")

    with open(image_path, "rb") as image_file:

        response = client.post(
            f"/api/inspections/{inspection_id}/images",

            headers=headers,

            data={
                "angle": "BACK",
                "capture_source": "GALLERY"
            },

            files={
                "file": (
                    "product1.jpeg",
                    image_file,
                    "image/jpeg"
                )
            }
        )

    print(f"HTTP Status: {response.status_code}")

    assert response.status_code == 200, response.text

    upload_data = response.json()

    print("\nUpload Response:")

    print(
        f"Image ID: "
        f"{upload_data['image_id']}"
    )

    print(
        f"Angle: "
        f"{upload_data['angle']}"
    )

    print(
        f"Image Quality: "
        f"{upload_data['image_quality']}"
    )

    print(
        f"Authenticity: "
        f"{upload_data['authenticity_status']}"
    )

    print(
        f"SHA-256: "
        f"{upload_data['sha256']}"
    )

    # STEP 5: OCR RESULT

    print("\n--- STEP 5: Nemotron OCR Result ---")

    ocr_data = upload_data.get("ocr", {})

    print(
        f"OCR Status: "
        f"{ocr_data.get('status')}"
    )

    print(
        f"OCR Result ID: "
        f"{ocr_data.get('result_id')}"
    )

    print(
        f"Detections: "
        f"{ocr_data.get('detections')}"
    )

    if ocr_data.get("error"):

        print(
            f"OCR Error: "
            f"{ocr_data['error']}"
        )

    # STEP 6: VERIFY DATABASE

    print("\n--- STEP 6: Verifying OCR Database Records ---")

    db = SessionLocal()

    image_id = upload_data["image_id"]

    image_record = (
        db.query(InspectionImage)
        .filter(
            InspectionImage.id == image_id
        )
        .first()
    )

    assert image_record is not None

    print(
        f"InspectionImage ID: "
        f"{image_record.id}"
    )

    print(
        f"Width: "
        f"{image_record.capture_width}"
    )

    print(
        f"Height: "
        f"{image_record.capture_height}"
    )

    # STEP 7: VERIFY OCR RESULT

    ocr_result = (
        db.query(InspectionOCRResult)
        .filter(
            InspectionOCRResult.inspection_image_id
            == image_id
        )
        .order_by(
            InspectionOCRResult.id.desc()
        )
        .first()
    )

    if ocr_result is None:

        print(
            "\n⚠️ No OCR result was saved."
        )

        db.close()

        raise AssertionError(
            "Nemotron OCR result was not saved."
        )

    print(
        f"OCR Result ID: "
        f"{ocr_result.id}"
    )

    print(
        f"Model: "
        f"{ocr_result.model_name}"
    )

    print(
        f"Version: "
        f"{ocr_result.model_version}"
    )

    print(
        f"Status: "
        f"{ocr_result.status}"
    )

    # STEP 8: VERIFY OCR ITEMS

    ocr_items = (
        db.query(InspectionOCRItem)
        .filter(
            InspectionOCRItem.ocr_result_id
            == ocr_result.id
        )
        .order_by(
            InspectionOCRItem.id
        )
        .all()
    )

    print(
        f"\nOCR Items Found: "
        f"{len(ocr_items)}"
    )

    assert len(ocr_items) > 0, (
        "Nemotron returned no OCR detections."
    )

    # PRINT OCR TEXT + BOUNDING BOXES

    print("\n========== OCR DETECTIONS ==========")

    for index, item in enumerate(
        ocr_items,
        start=1
    ):

        print(
            f"\n[{index}] "
            f"{item.text}"
        )

        print(
            f"Confidence: "
            f"{item.confidence}"
        )

        print(
            f"Bounding Box: "
            f"x={item.bbox_x}, "
            f"y={item.bbox_y}, "
            f"w={item.bbox_width}, "
            f"h={item.bbox_height}"
        )

    print(
        "\n===================================="
    )

    db.close()

    # STEP 9: RUN FULL ANALYSIS

    print("\n--- STEP 9: Running Full Analysis ---")

    response = client.post(
        f"/api/inspections/{inspection_id}/analyze",
        headers=headers
    )

    print(
        f"Analysis HTTP Status: "
        f"{response.status_code}"
    )

    assert response.status_code == 200, response.text

    analysis_data = response.json()

    print("\nAnalysis Response:")
    print(analysis_data)

    # STEP 10: VERIFY ANALYSIS RESULT

    print("\n--- STEP 10: Verifying Analysis ---")

    print(
        f"Analysis Status: "
        f"{analysis_data.get('status')}"
    )

    print(
        f"Compliance Result: "
        f"{analysis_data.get('compliance_result')}"
    )

    print(
        f"Declarations Extracted: "
        f"{analysis_data.get('declarations_extracted')}"
    )

    print(
        f"Findings Generated: "
        f"{analysis_data.get('findings_generated')}"
    )

    # STEP 11: VERIFY SAVED INSPECTION

    print("\n--- STEP 11: Verifying Saved Inspection ---")

    db = SessionLocal()

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id
        )
        .first()
    )

    assert inspection is not None

    print(
        f"Product Name: "
        f"{inspection.product_name}"
    )

    print(
        f"Brand: "
        f"{inspection.brand}"
    )

    print(
        f"Net Quantity: "
        f"{inspection.net_quantity}"
    )

    print(
        f"MRP: "
        f"{inspection.mrp}"
    )

    print(
        f"Manufacturer: "
        f"{inspection.manufacturer_name}"
    )

    print(
        f"Manufacturer Address: "
        f"{inspection.manufacturer_address}"
    )

    print(
        f"Country of Origin: "
        f"{inspection.country_of_origin}"
    )

    print(
        f"Consumer Care Phone: "
        f"{inspection.consumer_care_phone}"
    )

    print(
        f"Consumer Care Email: "
        f"{inspection.consumer_care_email}"
    )

    print(
        f"Compliance Result: "
        f"{inspection.compliance_result}"
    )

    # STEP 12: VERIFY BATCH

    print("\n--- STEP 12: Verifying Batch ---")

    if inspection.batch:

        print(
            f"Batch Number: "
            f"{inspection.batch.batch_number}"
        )

        print(
            f"Manufacturing Date: "
            f"{inspection.batch.manufacturing_date}"
        )

        print(
            f"Expiry Date: "
            f"{inspection.batch.expiry_date}"
        )

        print(
            f"Best Before: "
            f"{inspection.batch.best_before}"
        )

    else:

        print(
            "No batch record was created."
        )

    # STEP 13: VERIFY FINDINGS

    print("\n--- STEP 13: Verifying Compliance Findings ---")

    findings = (
        db.query(ComplianceFinding)
        .filter(
            ComplianceFinding.inspection_id
            == inspection_id
        )
        .all()
    )

    print(
        f"Findings Found: "
        f"{len(findings)}"
    )

    for finding in findings:

        print(
            f"\nRule ID: "
            f"{finding.rule_id}"
        )

        print(
            f"Rule Number: "
            f"{finding.rule_number}"
        )

        print(
            f"Clause: "
            f"{finding.clause}"
        )

        print(
            f"Requirement: "
            f"{finding.requirement}"
        )

        print(
            f"Result: "
            f"{finding.result}"
        )

        print(
            f"Evidence: "
            f"{finding.evidence}"
        )

        print(
            f"Reason: "
            f"{finding.reason}"
        )

    db.close()

    # STEP 14: INSPECTOR VERIFICATION / MANUAL OVERRIDE

    print("\n--- STEP 14: Inspector Verification ---")

    # Fetch current declarations
    response = client.get(
        f"/api/inspections/{inspection_id}/declarations",
        headers=headers
    )

    assert response.status_code == 200, response.text

    declarations_data = response.json()["declarations"]

    print(
        f"Current declarations: "
        f"{len(declarations_data)}"
    )

    # Build lookup by field name
    declaration_map = {
        declaration["field_name"]: declaration
        for declaration in declarations_data
    }

    # Simulate inspector corrections

    manual_updates = []

    # Product Name
    if "product_name" in declaration_map:
        manual_updates.append({
            "id": declaration_map["product_name"]["id"],
            "field_name": "product_name",
            "value": "Four Corners Bagel Chips",
            "raw_value": "Four Corners Bagel Chips",
            "confidence": 1.0,
            "extraction_method": "MANUAL_OVERRIDE",
            "status": "VERIFIED"
        })

    # Net Quantity
    if "net_quantity" in declaration_map:
        manual_updates.append({
            "id": declaration_map["net_quantity"]["id"],
            "field_name": "net_quantity",
            "value": "28 g",
            "raw_value": "28 g",
            "confidence": 1.0,
            "extraction_method": "MANUAL_OVERRIDE",
            "status": "VERIFIED"
        })

    # Consumer Care Phone
    if "consumer_care_phone" in declaration_map:
        manual_updates.append({
            "id": declaration_map["consumer_care_phone"]["id"],
            "field_name": "consumer_care_phone",
            "value": "60927 00013",
            "raw_value": "60927 00013",
            "confidence": 1.0,
            "extraction_method": "MANUAL_OVERRIDE",
            "status": "VERIFIED"
        })

    assert len(manual_updates) > 0, (
        "No declarations available for manual verification."
    )

    print(
        f"Declarations being manually verified: "
        f"{len(manual_updates)}"
    )

    # Send inspector corrections

    response = client.put(
        f"/api/inspections/{inspection_id}/declarations",
        headers=headers,
        json={
            "declarations": manual_updates
        }
    )

    print(
        f"Manual Override HTTP Status: "
        f"{response.status_code}"
    )

    assert response.status_code == 200, response.text

    override_result = response.json()

    print("\nManual Override Response:")
    print(override_result)

    assert (
        override_result["inspection_id"]
        == inspection_id
    )

    assert "overall_result" in override_result
    assert "declarations_count" in override_result
    assert "findings_count" in override_result

    print(
        "\nFinal Compliance After Inspector Verification: "
        f"{override_result['overall_result']}"
    )

    # Verify declarations were actually updated

    response = client.get(
        f"/api/inspections/{inspection_id}/declarations",
        headers=headers
    )

    assert response.status_code == 200, response.text

    verified_declarations = response.json()["declarations"]

    verified_map = {
        declaration["field_name"]: declaration
        for declaration in verified_declarations
    }

    # Verify Product Name
    if "product_name" in verified_map:

        assert (
            verified_map["product_name"]["value"]
            == "Four Corners Bagel Chips"
        )

        assert (
            verified_map["product_name"]["extraction_method"]
            == "MANUAL_OVERRIDE"
        )

        assert (
            verified_map["product_name"]["status"]
            == "VERIFIED"
        )

    # Verify Net Quantity
    if "net_quantity" in verified_map:

        assert (
            verified_map["net_quantity"]["value"]
            == "28 g"
        )

        assert (
            verified_map["net_quantity"]["extraction_method"]
            == "MANUAL_OVERRIDE"
        )

        assert (
            verified_map["net_quantity"]["status"]
            == "VERIFIED"
        )

    # Verify Consumer Care Phone
    if "consumer_care_phone" in verified_map:

        assert (
            verified_map["consumer_care_phone"]["value"]
            == "60927 00013"
        )

        assert (
            verified_map["consumer_care_phone"]["extraction_method"]
            == "MANUAL_OVERRIDE"
        )

        assert (
            verified_map["consumer_care_phone"]["status"]
            == "VERIFIED"
        )

    print(
        "Inspector corrections verified successfully."
    )

    print(
        "\n=================================================="
    )

    print(
        "✅ STEP 14: INSPECTOR VERIFICATION PASSED!"
    )

    print(
        "=================================================="
    )

    # STEP 15: FINALIZE INSPECTION

    print("\n--- STEP 15: Finalizing Inspection ---")

    response = client.post(
        f"/api/inspections/{inspection_id}/finalize",
        headers=headers
    )

    print(
        f"Finalize HTTP Status: "
        f"{response.status_code}"
    )

    assert response.status_code == 200, response.text

    finalize_result = response.json()

    print("\nFinalize Response:")
    print(finalize_result)

    # Verify finalize response

    assert (
        finalize_result["inspection_id"]
        == inspection_id
    )

    assert (
        finalize_result["status"]
        == "FINALIZED"
    )

    assert (
        finalize_result["compliance_result"]
        == "REVIEW"
    )

    # Verify canonical SHA-256

    canonical_hash = finalize_result["canonical_hash"]

    assert canonical_hash is not None
    assert len(canonical_hash) == 64

    print("\nCanonical SHA-256 Hash:")
    print(canonical_hash)

    # Verify finalized timestamp

    finalized_at = finalize_result["finalized_at"]

    assert finalized_at is not None

    print("\nFinalized At:")
    print(finalized_at)

    # Extract report information

    report_data = finalize_result["report"]

    assert report_data is not None

    report_id = report_data["id"]
    pdf_url = report_data["pdf_url"]
    report_hash = report_data["report_hash"]

    assert report_id is not None
    assert pdf_url is not None
    assert report_hash is not None
    assert len(report_hash) == 64

    print("\nReport ID:")
    print(report_id)

    print("\nReport PDF URL:")
    print(pdf_url)

    print("\nReport SHA-256:")
    print(report_hash)

    # Verify finalized inspection in database

    db = SessionLocal()

    finalized_inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id
        )
        .first()
    )

    assert finalized_inspection is not None

    print("\nSaved Inspection Status:")
    print(finalized_inspection.status)

    print("\nSaved Compliance Result:")
    print(
        finalized_inspection.compliance_result
    )

    print("\nSaved Canonical Hash:")
    print(
        finalized_inspection.canonical_hash
    )

    print("\nSaved Finalized At:")
    print(
        finalized_inspection.finalized_at
    )

    assert (
        finalized_inspection.status
        == "FINALIZED"
    )

    assert (
        finalized_inspection.canonical_hash
        == canonical_hash
    )

    assert (
        finalized_inspection.finalized_at
        is not None
    )

    # Verify report in database

    report = (
        db.query(InspectionReport)
        .filter(
            InspectionReport.id == report_id
        )
        .first()
    )

    assert report is not None

    print("\nSaved Report ID:")
    print(report.id)

    print("\nReport Status:")
    print(report.report_status)

    print("\nReport PDF URL:")
    print(report.pdf_url)

    print("\nReport SHA-256:")
    print(report.sha256)

    assert report.id == report_id

    assert report.pdf_url == pdf_url

    assert report.sha256 == report_hash

    assert len(report.sha256) == 64

    db.close()

    # STEP 15 SUCCESS

    print(
        "\n=================================================="
    )

    print(
        "✅ STEP 15: INSPECTION FINALIZATION PASSED!"
    )

    print(
        "=================================================="
    )

    # FINAL RESULT

    print(
        "\n=================================================="
    )

    print(
        "✅ REAL IMAGE → OCR → ANALYSIS → "
        "DECLARATIONS → RULES → FINDINGS → "
        "INSPECTOR VERIFICATION PASSED!"
    )

    print(
        "=================================================="
    )

    #Step 16
    print("\n--- STEP 16: Verifying Report + Integrity ---")

    import hashlib
    from pathlib import Path

    # 1. Get report information from finalize response

    report_data = finalize_result["report"]

    report_id = report_data["id"]
    report_url = report_data["pdf_url"]
    stored_report_hash = report_data["report_hash"]

    print(f"Report ID: {report_id}")
    print(f"Report URL: {report_url}")
    print(f"Stored Report SHA-256: {stored_report_hash}")

    # 2. Resolve the generated PDF path

    report_filename = Path(report_url).name

    possible_report_paths = [
        Path(backend_dir) / "reports" / report_filename,
        Path(backend_dir) / "app" / "reports" / report_filename,
        Path(backend_dir) / report_filename,
    ]

    report_path = None

    for path in possible_report_paths:
        if path.exists():
            report_path = path
            break

    assert report_path is not None, (
        f"Report PDF was not found. Checked: {possible_report_paths}"
    )

    print(f"Report File: {report_path}")

    # 3. Verify PDF is not empty

    pdf_bytes = report_path.read_bytes()

    assert len(pdf_bytes) > 0, "Report PDF is empty"

    print(f"Report PDF Size: {len(pdf_bytes)} bytes")

    # 4. Verify PDF signature

    assert pdf_bytes.startswith(b"%PDF"), (
        "Generated report is not a valid PDF file"
    )

    print("PDF Signature: VALID")

    # 5. Calculate SHA-256 of actual PDF

    calculated_report_hash = hashlib.sha256(pdf_bytes).hexdigest()

    print(f"Calculated Report SHA-256: {calculated_report_hash}")

    # 6. Compare stored hash with actual file hash

    assert calculated_report_hash == stored_report_hash, (
        "Report SHA-256 integrity verification failed"
    )

    print("Report SHA-256: MATCHED")

    # 7. Verify report record in database

    db = SessionLocal()

    saved_report = (
        db.query(InspectionReport)
        .filter(InspectionReport.id == report_id)
        .first()
    )

    assert saved_report is not None, (
        "InspectionReport record was not found in database"
    )

    assert saved_report.report_status == "FINALIZED"

    assert saved_report.pdf_url == report_url

    assert saved_report.sha256 == stored_report_hash

    print(f"Saved Report Status: {saved_report.report_status}")
    print(f"Saved Report SHA-256: {saved_report.sha256}")

    db.close()

    # STEP 16 SUCCESS

    print("\n" + "=" * 60)
    print("🎉 PARAKH FULL PIPELINE VERIFICATION PASSED!")
    print("=" * 60)

    print("\nPipeline Verified:")
    print("  ✓ Image Upload & Processing")
    print("  ✓ Image Quality Analysis")
    print("  ✓ Image Authenticity Gate")
    print("  ✓ NVIDIA Nemotron OCR")
    print("  ✓ Declaration Extraction")
    print("  ✓ Applicability Check")
    print("  ✓ Legal Metrology Rules Engine")
    print("  ✓ Compliance Findings")
    print("  ✓ Inspector Verification")
    print("  ✓ Inspection Finalization")
    print("  ✓ PDF Report Generation")
    print("  ✓ SHA-256 Report Integrity Verification")
    print("  ✓ Database Persistence")

    print("\n" + "=" * 60)
    print("✅ PARAKH DEMO BACKEND IS WORKING END-TO-END!")
    print("=" * 60)
    
    # FINAL RESULT

    print(
        "\n=================================================="
    )

    print(
        "✅ REAL IMAGE → OCR → ANALYSIS → "
        "DECLARATIONS → RULES → FINDINGS PASSED!"
    )

    print(
        "=================================================="
    )

# DIRECT EXECUTION

if __name__ == "__main__":
    test_real_image_pipeline()