
from __future__ import annotations

from typing import Dict, Any, List

import httpx

from fastapi import HTTPException
from sqlalchemy.orm import Session

from ..models import (
    Inspection,
    InspectionImage,
    InspectionOCRResult,
    InspectionOCRItem,
    InspectionDeclaration,
)

from .ocr_service import (
    run_ocr,
    save_ocr_result,
)

from .declaration_extraction_service import (
    extract_declarations_from_multi_image_ocr,
)

from .inspection_population_service import (
    populate_inspection_and_batch_from_declarations,
)

from .applicability_engine import RuleApplicability

from ..rules.packaged_commodity_rules import (
    get_all_rules,
)

from ..rules.rule_evaluator import (
    evaluate_rules,
    calculate_overall_result,
)

from .compliance_finding_service import (
    save_compliance_findings,
)

from .measurement_service import analyze_readability

from .ner_service import run_ner, merge_ner_with_regex

def analyze_inspection(
    db: Session,
    inspection_id: int
) -> Dict[str, Any]:

    # 1. Fetch inspection

    inspection = (
        db.query(Inspection)
        .filter(Inspection.id == inspection_id)
        .first()
    )

    if not inspection:
        raise HTTPException(
            status_code=404,
            detail="Inspection not found"
        )

    # 2. Fetch all active images

    active_images = (
        db.query(InspectionImage)
        .filter(
            InspectionImage.inspection_id == inspection_id,
            InspectionImage.is_active.is_(True)
        )
        .order_by(InspectionImage.id)
        .all()
    )

    if not active_images:
        raise HTTPException(
            status_code=400,
            detail=(
                "No active images found for this inspection. "
                "Please upload package images first."
            )
        )

    # 3. Mark inspection as ANALYZING

    inspection.status = "ANALYZING"
    inspection.processing_error = None

    db.commit()

    try:

        # 4. Get OCR from ALL active images
        #
        # If OCR already exists, reuse it.
        # Otherwise, run Nemotron OCR.

        all_ocr_items: List[InspectionOCRItem] = []

        processed_images: List[int] = []

        for image in active_images:

            # Skip images that require retake

            if image.image_quality == "RETAKE":
                continue

            # Check for existing successful OCR

            existing_ocr_result = (
                db.query(InspectionOCRResult)
                .filter(
                    InspectionOCRResult.inspection_image_id
                    == image.id,
                    InspectionOCRResult.status.in_(
                        [
                            "SUCCESS",
                            "COMPLETED"
                        ]
                    )
                )
                .order_by(
                    InspectionOCRResult.id.desc()
                )
                .first()
            )

            # Reuse existing OCR

            if existing_ocr_result:

                ocr_items = (
                    db.query(InspectionOCRItem)
                    .filter(
                        InspectionOCRItem.ocr_result_id
                        == existing_ocr_result.id
                    )
                    .order_by(
                        InspectionOCRItem.id
                    )
                    .all()
                )

                all_ocr_items.extend(
                    ocr_items
                )

                processed_images.append(
                    image.id
                )

                continue

            # No OCR exists → run Nemotron OCR

            if not image.image_url:
                raise ValueError(
                    f"Image URL missing for image {image.id}"
                )

            # Download image from Cloudinary

            response = httpx.get(
                image.image_url,
                timeout=60
            )

            response.raise_for_status()

            image_bytes = response.content

            # Validate image dimensions

            if (
                not image.capture_width
                or not image.capture_height
            ):
                raise ValueError(
                    f"Image dimensions missing "
                    f"for image {image.id}"
                )

            # Run Nemotron OCR

            detections = run_ocr(
                image_bytes=image_bytes,
                filename=(
                    f"inspection_{inspection_id}"
                    f"_image_{image.id}.jpg"
                ),
                image_width=image.capture_width,
                image_height=image.capture_height
            )

            # Save OCR result + OCR items

            ocr_result = save_ocr_result(
                db=db,
                inspection_image_id=image.id,
                detections=detections
            )

            db.flush()

            # Fetch OCR items for this result

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

            # Add to combined OCR collection

            all_ocr_items.extend(
                ocr_items
            )

            processed_images.append(
                image.id
            )

        # 5. Check whether OCR found any text

        if not all_ocr_items:

            inspection.status = "COMPLETED"

            inspection.compliance_result = "REVIEW"

            inspection.processing_error = (
                "No readable text detected "
                "in uploaded images."
            )

            db.commit()

            return {
                "inspection_id": inspection_id,

                "status": inspection.status,

                "compliance_result": (
                    inspection.compliance_result
                ),

                "processed_images": (
                    processed_images
                ),

                "ocr_items_count": 0,

                "declarations_extracted": 0,

                "findings_generated": 0,

                "message": (
                    "No readable text detected "
                    "in uploaded images."
                )
            }

        # 6. Extract declarations from ALL OCR items

        extracted_decls = (
            extract_declarations_from_multi_image_ocr(
                all_ocr_items
            )
        )

        # 6b. LLM NER — refine extractions using Llama
        #
        # Run LLM-based NER on the combined OCR text and merge
        # results with regex extraction. This corrects common
        # heuristic errors like putting Nutrition Facts text
        # into product_name.

        try:
            ner_result = run_ner(all_ocr_items)
            if ner_result:
                extracted_decls = merge_ner_with_regex(
                    extracted_decls, ner_result
                )
        except Exception as ner_err:
            import logging
            logging.getLogger(__name__).warning(
                "NER step failed (non-fatal): %s", ner_err
            )

        # 7. Remove previous declarations

        db.query(
            InspectionDeclaration
        ).filter(
            InspectionDeclaration.inspection_id
            == inspection_id
        ).delete(
            synchronize_session=False
        )

        # 8. Save extracted declarations

        declaration_objects: List[
            InspectionDeclaration
        ] = []

        for decl_dict in extracted_decls:

            decl_obj = InspectionDeclaration(

                inspection_id=inspection_id,

                field_name=decl_dict[
                    "field_name"
                ],

                value=decl_dict[
                    "value"
                ],

                raw_value=decl_dict.get(
                    "raw_value"
                ),

                source_image_id=decl_dict.get(
                    "source_image_id"
                ),

                source_ocr_item_id=decl_dict.get(
                    "source_ocr_item_id"
                ),

                source_ocr_result_id=decl_dict.get(
                    "source_ocr_result_id"
                ),

                evidence_text=decl_dict.get(
                    "evidence_text"
                ),

                extraction_confidence=(
                    decl_dict.get(
                        "extraction_confidence"
                    )
                ),

                confidence=decl_dict.get(
                    "ocr_confidence"
                ),

                bbox_x=decl_dict.get(
                    "bbox_x"
                ),

                bbox_y=decl_dict.get(
                    "bbox_y"
                ),

                bbox_width=decl_dict.get(
                    "bbox_width"
                ),

                bbox_height=decl_dict.get(
                    "bbox_height"
                ),

                extraction_method=(
                    decl_dict.get(
                        "extraction_method",
                        "REGEX"
                    )
                ),

                status=decl_dict.get(
                    "status",
                    "EXTRACTED"
                )
            )

            db.add(decl_obj)

            declaration_objects.append(
                decl_obj
            )

        db.flush()

        # 9. Populate Inspection + Batch
        populate_inspection_and_batch_from_declarations(
            db,
            inspection,
            declaration_objects
        )

        # 9b. Readability analysis
        image_heights = {
            img.id: img.capture_height
            for img in active_images
            if img.capture_height
        }

        readability = analyze_readability(
            declaration_objects,
            image_heights,
        )

        legibility_decl = InspectionDeclaration(
            inspection_id=inspection_id,
            field_name="legibility",
            value=readability["overall"],
            raw_value=str(readability["field_results"]),
            extraction_method="MEASUREMENT",
            status="EXTRACTED",
        )
        db.add(legibility_decl)
        declaration_objects.append(legibility_decl)
        db.flush()

        # 10. Build declaration map
        decl_map = {
            d.field_name.lower(): d.value
            for d in declaration_objects
            if d.value
        }

        decl_map_upper = {
            d.field_name.upper(): d.value
            for d in declaration_objects
            if d.value
        }

        # 11. Get all rules

        all_rules = get_all_rules()

        # 12. Filter applicable rules

        applicable_rules = (
            RuleApplicability.filter_applicable_rules(
                all_rules,
                decl_map_upper
            )
        )

        # 13. Evaluate compliance rules

        compliance_results = evaluate_rules(
            rules=applicable_rules,
            declarations=decl_map
        )

        # 14. Save compliance findings

        saved_findings = save_compliance_findings(
            db=db,
            inspection_id=inspection_id,
            results=compliance_results
        )

        # 15. Calculate overall result

        overall_result = calculate_overall_result(
            compliance_results
        )

        inspection.compliance_result = (
            overall_result
        )

        inspection.status = "COMPLETED"

        inspection.processing_error = None

        # 16. Commit everything

        db.commit()

        # 17. Return analysis response

        return {

            "inspection_id": inspection_id,

            "status": inspection.status,

            "compliance_result": (
                inspection.compliance_result
            ),

            "processed_images": (
                processed_images
            ),

            "ocr_items_count": len(
                all_ocr_items
            ),

            "declarations_extracted": len(
                declaration_objects
            ),

            "findings_generated": len(
                saved_findings
            ),

            "declarations": [

                {
                    "id": declaration.id,

                    "field_name": (
                        declaration.field_name
                    ),

                    "value": (
                        declaration.value
                    ),

                    "raw_value": (
                        declaration.raw_value
                    ),

                    "confidence": (
                        declaration.extraction_confidence
                        or declaration.confidence
                    ),

                    "extraction_method": (
                        declaration.extraction_method
                    ),

                    "source_image_id": (
                        declaration.source_image_id
                    ),

                    "source_ocr_item_id": (
                        declaration.source_ocr_item_id
                    ),

                    "source_ocr_result_id": (
                        declaration.source_ocr_result_id
                    ),

                    "evidence_text": (
                        declaration.evidence_text
                    ),

                    "bbox": {

                        "x": declaration.bbox_x,

                        "y": declaration.bbox_y,

                        "width": declaration.bbox_width,

                        "height": declaration.bbox_height,

                    }

                }

                for declaration
                in declaration_objects
            ],

            "findings": [

                {
                    "id": finding.id,

                    "rule_id": finding.rule_id,

                    "rule_number": (
                        finding.rule_number
                    ),

                    "clause": (
                        finding.clause
                    ),

                    "requirement": (
                        finding.requirement
                    ),

                    "result": (
                        finding.result
                    ),

                    "evidence": (
                        finding.evidence
                    ),

                    "reason": (
                        finding.reason
                    )

                }

                for finding
                in saved_findings
            ]
        }

    except Exception as e:

        # 18. Rollback failed analysis

        db.rollback()

        inspection = (
            db.query(Inspection)
            .filter(
                Inspection.id == inspection_id
            )
            .first()
        )

        if inspection:

            inspection.status = (
                "ANALYSIS_FAILED"
            )

            inspection.processing_error = (
                str(e)
            )

            db.commit()

        raise HTTPException(
            status_code=500,
            detail=(
                f"Inspection analysis failed: "
                f"{str(e)}"
            )
        )