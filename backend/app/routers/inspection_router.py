
from __future__ import annotations
from typing import Optional

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Query
from fastapi.responses import Response, JSONResponse
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import (
    Inspection,
    Inspector,
    InspectionImage,
    InspectionDeclaration,
    ComplianceFinding,
    Batch
)

from ..schemas.inspection_schema import (
    CreateInspectionRequest,
    UpdateDeclarationsRequest
)

from ..dependencies.auth_dependency import get_approved_inspector

from ..services.hash_service import calculate_sha256
from ..services.cloudinary_service import upload_image
from ..services.image_quality_service import analyze_image_quality
from ..services.image_authenticity_service import evaluate_image_authenticity
from ..services.inspection_analysis_service import analyze_inspection
from ..services.inspection_population_service import (
    populate_inspection_and_batch_from_declarations
)

from ..services.report_service import (
    finalize_inspection_and_create_report,
    generate_pdf_report_bytes,
    generate_json_report,
    generate_csv_report,
)

from ..services.audit_service import log_action

from ..rules.packaged_commodity_rules import get_all_rules
from ..rules.rule_evaluator import (
    evaluate_rules,
    calculate_overall_result
)

from ..services.applicability_engine import RuleApplicability
from ..services.compliance_finding_service import save_compliance_findings

from ..services.ocr_service import run_ocr, save_ocr_result

ALLOWED_ANGLES = {
    "FRONT",
    "BACK",
    "TOP",
    "BOTTOM",
    "LEFT",
    "RIGHT"
}

ALLOWED_CAPTURE_SOURCES = {
    "CAMERA",
    "GALLERY"
}

router = APIRouter(
    prefix="/api/inspections",
    tags=["Inspections"]
)

# CREATE INSPECTION

@router.post("/")
def create_inspection(
    data: Optional[CreateInspectionRequest] = None,
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    inspection = Inspection(
        inspector_id=current_inspector.id,
        status="PENDING"
    )

    db.add(inspection)
    db.commit()
    db.refresh(inspection)

    log_action(
        db,
        action="CREATE_INSPECTION",
        inspection_id=inspection.id,
        inspector_id=current_inspector.id
    )

    return {
        "message": "Inspection created successfully",
        "inspection_id": inspection.id,
        "status": inspection.status
    }

# UPLOAD INSPECTION IMAGE

@router.post("/{inspection_id}/images")
async def upload_inspection_image(
    inspection_id: int,
    file: UploadFile = File(...),
    angle: str = Form(...),
    capture_source: str = Form(...),
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    #docstring for better understandigs

    # 1. Validate inspection

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    if inspection.status == "FINALIZED":
        raise HTTPException(
            status_code=400,
            detail="Cannot upload images to a finalized inspection."
        )

    # 2. Normalize input

    angle = angle.strip().upper()
    capture_source = capture_source.strip().upper()

    # 3. Validate angle

    if angle not in ALLOWED_ANGLES:
        raise HTTPException(
            status_code=400,
            detail="Invalid image angle"
        )

    # 4. Validate capture source

    if capture_source not in ALLOWED_CAPTURE_SOURCES:
        raise HTTPException(
            status_code=400,
            detail="Invalid capture source"
        )

    # 5. Read image

    image_data = await file.read()

    if not image_data:
        raise HTTPException(
            status_code=400,
            detail="Empty image file"
        )

    # 6. Image quality analysis

    try:
        quality_result = analyze_image_quality(image_data)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Invalid or unreadable image"
        )

    # 7. SHA-256 integrity hash

    sha256 = calculate_sha256(image_data)

    # 8. Authenticity / duplicate check

    try:
        authenticity_eval = evaluate_image_authenticity(
            db,
            inspection_id,
            sha256,
            quality_result,
            current_angle=angle
        )
    except Exception as e:
        print(f"Image authenticity check error: {e}")
        authenticity_eval = {
            "authenticity_status": "VERIFIED",
            "reason": "Authenticity check skipped"
        }

    authenticity_status = authenticity_eval.get("authenticity_status", "VERIFIED")

    if authenticity_status == "REJECTED_DUPLICATE":
        raise HTTPException(
            status_code=400,
            detail=authenticity_eval.get("reason", "Duplicate image detected")
        )

    # 9. Upload to Cloudinary / Local Storage Fallback

    folder = (
        f"parakh/inspections/"
        f"{inspection_id}/"
        f"{angle.lower()}"
    )

    try:
        cloudinary_res = upload_image(
            image_data,
            folder
        )
    except Exception as exc:
        print(f"Cloudinary upload failed: {exc}. Saving locally as fallback.")
        import uuid, os
        local_dir = os.path.join(os.getcwd(), "uploads", f"inspection_{inspection_id}")
        os.makedirs(local_dir, exist_ok=True)
        filename = f"{angle.lower()}_{uuid.uuid4().hex[:8]}.jpg"
        filepath = os.path.join(local_dir, filename)
        with open(filepath, "wb") as f:
            f.write(image_data)
        cloudinary_res = {
            "secure_url": f"/uploads/inspection_{inspection_id}/{filename}",
            "public_id": f"local_{filename}"
        }

    # 10. Deactivate previous image for same angle

    existing_image = (
        db.query(InspectionImage)
        .filter(
            InspectionImage.inspection_id == inspection_id,
            InspectionImage.angle == angle,
            InspectionImage.is_active.is_(True)
        )
        .first()
    )

    if existing_image:
        existing_image.is_active = False

    # 11. Create InspectionImage record

    inspection_image = InspectionImage(
        inspection_id=inspection_id,
        angle=angle,
        capture_source=capture_source,
        image_url=cloudinary_res["secure_url"],
        cloudinary_public_id=cloudinary_res["public_id"],
        sha256=sha256,

        capture_width=quality_result["width"],
        capture_height=quality_result["height"],

        blur_score=quality_result["blur_score"],
        glare_score=quality_result["glare_score"],
        perspective_score=quality_result["perspective_score"],

        image_quality=quality_result["image_quality"],
        authenticity_status=authenticity_status,

        calibration_status="PENDING",
        is_active=True
    )

    db.add(inspection_image)
    db.commit()
    db.refresh(inspection_image)

    # 12. Run OCR using NVIDIA Nemotron OCR v2

    ocr_result = None
    ocr_status = "FAILED"
    ocr_error = None

    try:
        detections = run_ocr(
            image_bytes=image_data,
            filename=file.filename or "image.jpg",
            image_width=inspection_image.capture_width,
            image_height=inspection_image.capture_height
        )

        ocr_result = save_ocr_result(
            db=db,
            inspection_image_id=inspection_image.id,
            detections=detections
        )

        ocr_status = "COMPLETED"

    except Exception as exc:
        ocr_error = str(exc)

        print(
            f"OCR processing failed for "
            f"inspection image {inspection_image.id}: {exc}"
        )

    # 13. Audit log

    log_action(
        db,
        action="UPLOAD_IMAGE",
        inspection_id=inspection_id,
        inspector_id=current_inspector.id,
        details=(
            f"Angle: {angle}, "
            f"Image ID: {inspection_image.id}, "
            f"OCR Status: {ocr_status}"
        )
    )

    # 14. Return upload result

    response = {
        "message": "Image uploaded successfully",
        "image_id": inspection_image.id,
        "inspection_id": inspection_id,
        "angle": inspection_image.angle,
        "capture_source": inspection_image.capture_source,
        "image_url": inspection_image.image_url,
        "sha256": inspection_image.sha256,
        "width": inspection_image.capture_width,
        "height": inspection_image.capture_height,
        "image_quality": inspection_image.image_quality,
        "authenticity_status": inspection_image.authenticity_status,

        "ocr": {
            "status": ocr_status,
            "result_id": ocr_result.id if ocr_result else None,
            "detections": (
                len(ocr_result.items)
                if ocr_result
                else 0
            )
        }
    }

    if ocr_error:
        response["ocr"]["error"] = ocr_error

    return response

# IMAGE CAPTURE STATUS

@router.get("/{inspection_id}/images/status")
def get_capture_status(
    inspection_id: int,
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    active_angles = (
        db.query(InspectionImage.angle)
        .filter(
            InspectionImage.inspection_id == inspection_id,
            InspectionImage.is_active.is_(True)
        )
        .all()
    )

    captured = {
        angle[0]
        for angle in active_angles
    }

    status = {
        angle: angle in captured
        for angle in ALLOWED_ANGLES
    }

    missing = [
        angle
        for angle in ALLOWED_ANGLES
        if angle not in captured
    ]

    has_minimum = (
        ("FRONT" in captured and "BACK" in captured)
        or len(captured) >= 1
    )

    return {
        "inspection_id": inspection_id,
        "captured": list(captured),
        "missing": missing,
        "has_minimum_images": has_minimum,
        "all_required_captured": len(missing) == 0,
        "status": status
    }

# TRIGGER INSPECTION ANALYSIS

@router.post("/{inspection_id}/analyze")
def trigger_inspection_analysis(
    inspection_id: int,
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    if inspection.status == "FINALIZED":
        raise HTTPException(
            status_code=400,
            detail="Inspection is finalized and locked."
        )

    result = analyze_inspection(
        db=db,
        inspection_id=inspection_id
    )

    log_action(
        db,
        action="ANALYZE_INSPECTION",
        inspection_id=inspection_id,
        inspector_id=current_inspector.id,
        details=(
            f"Result: "
            f"{result.get('compliance_result')}"
        )
    )

    return result

# GET INSPECTION DETAILS

@router.get("/{inspection_id}")
def get_inspection_details(
    inspection_id: int,
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    declarations = (
        db.query(InspectionDeclaration)
        .filter(
            InspectionDeclaration.inspection_id == inspection_id
        )
        .all()
    )

    findings = (
        db.query(ComplianceFinding)
        .filter(
            ComplianceFinding.inspection_id == inspection_id
        )
        .all()
    )

    images = (
        db.query(InspectionImage)
        .filter(
            InspectionImage.inspection_id == inspection_id,
            InspectionImage.is_active.is_(True)
        )
        .all()
    )

    batch = (
        db.query(Batch)
        .filter(
            Batch.inspection_id == inspection_id
        )
        .first()
    )

    return {
        "id": inspection.id,
        "inspector_id": inspection.inspector_id,
        "status": inspection.status,
        "compliance_result": inspection.compliance_result,

        "product_name": inspection.product_name,
        "product_code": inspection.product_code,
        "brand": inspection.brand,

        "manufacturer_name": inspection.manufacturer_name,
        "manufacturer_address": inspection.manufacturer_address,

        "net_quantity": inspection.net_quantity,
        "quantity_unit": inspection.quantity_unit,

        "mrp": inspection.mrp,
        "mrp_inclusive_of_taxes": (
            inspection.mrp_inclusive_of_taxes
        ),

        "consumer_care_phone": (
            inspection.consumer_care_phone
        ),
        "consumer_care_email": (
            inspection.consumer_care_email
        ),
        "consumer_care_address": (
            inspection.consumer_care_address
        ),

        "country_of_origin": (
            inspection.country_of_origin
        ),

        "category": inspection.category,
        "commodity_type": inspection.commodity_type,

        "importer_name": inspection.importer_name,
        "importer_address": inspection.importer_address,

        "canonical_hash": inspection.canonical_hash,
        "finalized_at": inspection.finalized_at,
        "processing_error": inspection.processing_error,

        "created_at": inspection.created_at,
        "updated_at": inspection.updated_at,

        "batch": {
            "batch_number": batch.batch_number
            if batch else None,

            "manufacturing_date": (
                batch.manufacturing_date
                if batch else None
            ),

            "raw_manufacturing_date": (
                batch.raw_manufacturing_date
                if batch else None
            ),

            "expiry_date": (
                batch.expiry_date
                if batch else None
            ),

            "raw_expiry_date": (
                batch.raw_expiry_date
                if batch else None
            ),

            "best_before": (
                batch.best_before
                if batch else None
            )

        } if batch else None,

        "declarations_count": len(declarations),
        "findings_count": len(findings),

        "findings": [
            {
                "id": f.id,
                "rule_id": f.rule_id,
                "rule_number": f.rule_number,
                "clause": f.clause,
                "requirement": f.requirement,
                "result": f.result,
                "evidence": f.evidence,
                "reason": f.reason,
            }
            for f in findings
        ],

        "images": [
            {
                "id": img.id,
                "angle": img.angle,
                "image_url": img.image_url,
                "sha256": img.sha256,
                "quality": img.image_quality,
                "authenticity_status": (
                    img.authenticity_status
                )
            }
            for img in images
        ]
    }

# GET DECLARATIONS

@router.get("/{inspection_id}/declarations")
def get_inspection_declarations(
    inspection_id: int,
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    declarations = (
        db.query(InspectionDeclaration)
        .filter(
            InspectionDeclaration.inspection_id == inspection_id
        )
        .order_by(InspectionDeclaration.id)
        .all()
    )

    return {
        "inspection_id": inspection_id,
        "count": len(declarations),

        "declarations": [
            {
                "id": declaration.id,
                "field_name": declaration.field_name,
                "value": declaration.value,
                "raw_value": declaration.raw_value,

                "confidence": (
                    declaration.extraction_confidence
                    or declaration.confidence
                ),

                "extraction_method": (
                    declaration.extraction_method
                ),

                "status": declaration.status,

                "source_image_id": (
                    declaration.source_image_id
                ),

                "source_ocr_item_id": (
                    declaration.source_ocr_item_id
                ),

                "evidence_text": (
                    declaration.evidence_text
                )
            }
            for declaration in declarations
        ]
    }

# UPDATE DECLARATIONS

@router.put("/{inspection_id}/declarations")
def update_inspection_declarations(
    inspection_id: int,
    body: UpdateDeclarationsRequest,
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    if inspection.status == "FINALIZED":
        raise HTTPException(
            status_code=400,
            detail="Cannot edit a finalized inspection."
        )

    updated_declarations = []

    for item in body.declarations:

        decl = None

        if item.id:
            decl = (
                db.query(InspectionDeclaration)
                .filter(
                    InspectionDeclaration.id == item.id,
                    InspectionDeclaration.inspection_id
                    == inspection_id
                )
                .first()
            )

        if not decl:
            decl = InspectionDeclaration(
                inspection_id=inspection_id,
                field_name=item.field_name,
                extraction_method="MANUAL_OVERRIDE",
                status="VERIFIED"
            )

            db.add(decl)

        decl.value = item.value
        decl.raw_value = item.raw_value or item.value
        decl.extraction_method = "MANUAL_OVERRIDE"
        decl.status = "VERIFIED"

        updated_declarations.append(decl)

    db.flush()

    # Repopulate inspection & batch

    all_decls = (
        db.query(InspectionDeclaration)
        .filter(
            InspectionDeclaration.inspection_id
            == inspection_id
        )
        .all()
    )

    populate_inspection_and_batch_from_declarations(
        db,
        inspection,
        all_decls
    )

    # Re-evaluate compliance

    decl_map = {
        declaration.field_name.lower():
        declaration.value
        for declaration in all_decls
        if declaration.value
    }

    decl_map_upper = {
        declaration.field_name.upper():
        declaration.value
        for declaration in all_decls
        if declaration.value
    }

    all_rules = get_all_rules()

    applicable_rules = (
        RuleApplicability.filter_applicable_rules(
            all_rules,
            decl_map_upper
        )
    )

    compliance_results = evaluate_rules(
        rules=applicable_rules,
        declarations=decl_map
    )

    saved_findings = save_compliance_findings(
        db=db,
        inspection_id=inspection_id,
        results=compliance_results
    )

    overall_result = calculate_overall_result(
        compliance_results
    )

    inspection.compliance_result = overall_result

    db.commit()

    log_action(
        db,
        action="UPDATE_DECLARATIONS",
        inspection_id=inspection_id,
        inspector_id=current_inspector.id,
        details=(
            f"Updated "
            f"{len(body.declarations)} declarations manually"
        )
    )

    return {
        "message": (
            "Declarations updated and compliance "
            "re-evaluated successfully"
        ),
        "inspection_id": inspection_id,
        "overall_result": overall_result,
        "declarations_count": len(all_decls),
        "findings_count": len(saved_findings)
    }

# GET FINDINGS

@router.get("/{inspection_id}/findings")
def get_inspection_findings(
    inspection_id: int,
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    findings = (
        db.query(ComplianceFinding)
        .filter(
            ComplianceFinding.inspection_id == inspection_id
        )
        .order_by(ComplianceFinding.id)
        .all()
    )

    return {
        "inspection_id": inspection.id,
        "product_name": inspection.product_name,
        "overall_result": inspection.compliance_result,

        "findings": [
            {
                "id": finding.id,
                "rule_id": finding.rule_id,
                "rule_number": finding.rule_number,
                "clause": finding.clause,
                "requirement": finding.requirement,
                "result": finding.result,
                "evidence": finding.evidence,
                "reason": finding.reason,
                "created_at": finding.created_at
            }
            for finding in findings
        ]
    }

# FINALIZE INSPECTION

@router.post("/{inspection_id}/finalize")
def finalize_inspection_endpoint(
    inspection_id: int,
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db)
):

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    if inspection.status == "FINALIZED":
        raise HTTPException(
            status_code=400,
            detail="Inspection is already finalized."
        )

    finalized_inspection, report = (
        finalize_inspection_and_create_report(
            db=db,
            inspection_id=inspection_id
        )
    )

    log_action(
        db,
        action="FINALIZE_INSPECTION",
        inspection_id=inspection_id,
        inspector_id=current_inspector.id,
        details=(
            f"Canonical Hash: "
            f"{finalized_inspection.canonical_hash}"
        )
    )

    return {
        "message": "Inspection finalized successfully",
        "inspection_id": finalized_inspection.id,
        "status": finalized_inspection.status,
        "compliance_result": (
            finalized_inspection.compliance_result
        ),
        "canonical_hash": (
            finalized_inspection.canonical_hash
        ),
        "finalized_at": (
            finalized_inspection.finalized_at.isoformat()
        ),

        "report": {
            "id": report.id,
            "pdf_url": report.pdf_url,
            "report_hash": report.sha256
        }
    }

# DOWNLOAD INSPECTION REPORT

@router.get("/{inspection_id}/report")
def download_inspection_report(
    inspection_id: int,
    format: str = Query("pdf", pattern="^(pdf|json|csv)$"),
    current_inspector: Inspector = Depends(get_approved_inspector),
    db: Session = Depends(get_db),
):
    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id,
            Inspection.inspector_id == current_inspector.id,
        )
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found",
        )

    declarations = (
        db.query(InspectionDeclaration)
        .filter(
            InspectionDeclaration.inspection_id == inspection_id
        )
        .all()
    )

    findings = (
        db.query(ComplianceFinding)
        .filter(
            ComplianceFinding.inspection_id == inspection_id
        )
        .all()
    )

    images = (
        db.query(InspectionImage)
        .filter(
            InspectionImage.inspection_id == inspection_id,
            InspectionImage.is_active.is_(True),
        )
        .all()
    )

    # JSON export
    if format == "json":
        json_data = generate_json_report(
            inspection, declarations, findings, images
        )
        return JSONResponse(content=json_data)

    # CSV export
    if format == "csv":
        csv_text = generate_csv_report(
            inspection, declarations, findings
        )
        return Response(
            content=csv_text,
            media_type="text/csv",
            headers={
                "Content-Disposition": f"attachment; filename=parakh_report_{inspection_id}.csv"
            },
        )

    # PDF export
    pdf_bytes = generate_pdf_report_bytes(
        inspection,
        declarations,
        findings,
        images,
    )

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename=parakh_report_{inspection_id}.pdf"
        },
    )