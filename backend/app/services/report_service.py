
from __future__ import annotations

import json
import csv
import hashlib
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from io import BytesIO, StringIO
from pathlib import Path
from typing import Tuple, Optional, List, Dict, Any

def format_utc_iso(dt: Optional[datetime]) -> Optional[str]:
    if dt is None:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.isoformat()

import httpx
from sqlalchemy.orm import Session
from fastapi import HTTPException

from ..models import (
    Inspection,
    InspectionReport,
    InspectionDeclaration,
    ComplianceFinding,
    InspectionImage,
)

try:
    from reportlab.lib.pagesizes import letter
    from reportlab.lib import colors
    from reportlab.platypus import (
        SimpleDocTemplate,
        Paragraph,
        Spacer,
        Table,
        TableStyle,
        Image as RLImage,
    )
    from reportlab.lib.styles import (
        getSampleStyleSheet,
        ParagraphStyle,
    )

    HAS_REPORTLAB = True

except ImportError:
    HAS_REPORTLAB = False

# Fetch image
def _fetch_image_bytes(image: InspectionImage) -> Optional[bytes]:
    if not image or not image.image_url:
        return None
    url = image.image_url
    if url.startswith("http://") or url.startswith("https://"):
        try:
            resp = httpx.get(url, timeout=5.0)
            if resp.status_code == 200:
                return resp.content
        except Exception:
            return None
    else:
        try:
            backend_dir = Path(__file__).resolve().parents[2]
            local_path = backend_dir / url.lstrip("/")
            if local_path.exists():
                return local_path.read_bytes()
            direct = Path(url)
            if direct.exists():
                return direct.read_bytes()
        except Exception:
            return None
    return None

# CANONICAL INSPECTION HASH

def calculate_canonical_inspection_hash(
    inspection: Inspection,
    declarations: list,
    findings: list,
    images: list,
) -> str:

    canonical_dict = {
        "inspection_id": inspection.id,
        "inspector_id": inspection.inspector_id,
        "product_name": inspection.product_name or "",
        "brand": inspection.brand or "",
        "mrp": inspection.mrp or "",
        "net_quantity": inspection.net_quantity or "",
        "country_of_origin": inspection.country_of_origin or "",
        "compliance_result": inspection.compliance_result or "",
        "created_at": (
            inspection.created_at.isoformat()
            if inspection.created_at
            else ""
        ),

        "declarations": sorted(
            [
                {
                    "field": d.field_name,
                    "value": d.value or "",
                }
                for d in declarations
            ],
            key=lambda x: x["field"],
        ),

        "findings": sorted(
            [
                {
                    "rule_id": f.rule_id,
                    "result": f.result,
                }
                for f in findings
            ],
            key=lambda x: x["rule_id"],
        ),

        "images": sorted(
            [
                img.sha256
                for img in images
                if img.sha256
            ]
        ),
    }

    canonical_json = json.dumps(
        canonical_dict,
        sort_keys=True,
    )

    return hashlib.sha256(
        canonical_json.encode("utf-8")
    ).hexdigest()

# PDF GENERATION

def generate_pdf_report_bytes(
    inspection: Inspection,
    declarations: list,
    findings: list,
    images: Optional[list] = None,
) -> bytes:

    # Fallback if ReportLab is unavailable

    if not HAS_REPORTLAB:

        report_text = (
            "PARAKH LEGAL METROLOGY INSPECTION REPORT\n"
            f"Inspection ID: {inspection.id}\n"
            f"Result: {inspection.compliance_result}\n"
        )

        return report_text.encode("utf-8")

    # Create PDF in memory

    buffer = BytesIO()

    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36,
    )

    styles = getSampleStyleSheet()

    story = []

    # TITLE

    title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Heading1"],
        fontSize=18,
        textColor=colors.HexColor("#1e293b"),
        alignment=1,
        spaceAfter=12,
    )

    story.append(
        Paragraph(
            "<b>PARAKH — Legal Metrology Inspection Report</b>",
            title_style,
        )
    )

    story.append(
        Spacer(1, 10)
    )

    # META INFORMATION

    meta_data = [
        [
            "Inspection ID:",
            str(inspection.id),
            "Date:",
            (
                (
                    (
                        inspection.created_at.replace(tzinfo=timezone.utc).astimezone(ZoneInfo("Asia/Kolkata"))
                        if inspection.created_at.tzinfo is None
                        else inspection.created_at.astimezone(ZoneInfo("Asia/Kolkata"))
                    ).strftime("%Y-%m-%d %I:%M %p IST")
                )
                if inspection.created_at
                else "N/A"
            ),
        ],

        [
            "Inspector ID:",
            str(inspection.inspector_id),
            "Status:",
            inspection.status,
        ],

        [
            "Product Name:",
            inspection.product_name or "N/A",
            "Compliance Result:",
            inspection.compliance_result or "N/A",
        ],

        [
            "Brand:",
            inspection.brand or "N/A",
            "Net Quantity:",
            inspection.net_quantity or "N/A",
        ],

        [
            "MRP:",
            f"Rs. {inspection.mrp}" if inspection.mrp else "N/A",
            "Country of Origin:",
            inspection.country_of_origin or "N/A",
        ],

        [
            "Manufacturer:",
            inspection.manufacturer_name or "N/A",
            "Customer Helpline:",
            inspection.consumer_care_phone or inspection.consumer_care_email or "N/A",
        ],
    ]

    t_meta = Table(
        meta_data,
        colWidths=[
            105,
            165,
            105,
            165,
        ],
    )

    t_meta.setStyle(
        TableStyle(
            [
                (
                    "BACKGROUND",
                    (0, 0),
                    (-1, -1),
                    colors.HexColor("#f8fafc"),
                ),

                (
                    "GRID",
                    (0, 0),
                    (-1, -1),
                    0.5,
                    colors.HexColor("#cbd5e1"),
                ),

                (
                    "FONTNAME",
                    (0, 0),
                    (-1, -1),
                    "Helvetica-Bold",
                ),

                (
                    "FONTSIZE",
                    (0, 0),
                    (-1, -1),
                    9,
                ),

                (
                    "TEXTCOLOR",
                    (0, 0),
                    (-1, -1),
                    colors.HexColor("#334155"),
                ),

                (
                    "PADDING",
                    (0, 0),
                    (-1, -1),
                    6,
                ),
            ]
        )
    )

    story.append(t_meta)

    story.append(
        Spacer(1, 15)
    )

    # DECLARATIONS

    story.append(
        Paragraph(
            "<b>Extracted Package Declarations</b>",
            styles["Heading2"],
        )
    )

    story.append(
        Spacer(1, 6)
    )

    image_angle_map = {}
    if images:
        image_angle_map = {
            getattr(img, "id", None): (getattr(img, "angle", None) or "UNKNOWN").upper()
            for img in images
            if getattr(img, "id", None)
        }

    decl_data = [
        [
            "Field Name",
            "Extracted Value",
            "Confidence",
            "Panel",
            "Method",
        ]
    ]

    for d in declarations:
        field_name = getattr(d, "field_name", None) or (d.get("field_name") if isinstance(d, dict) else "")
        if field_name.lower() == "legibility":
            continue
        value = getattr(d, "value", None) or (d.get("value") if isinstance(d, dict) else "")
        ext_conf = getattr(d, "extraction_confidence", None)
        item_conf = getattr(d, "confidence", None)

        if isinstance(d, dict):
            confidence = d.get("confidence") or d.get("extraction_confidence") or 0
            method = d.get("extraction_method", "REGEX")
            source_img_id = d.get("source_image_id")
            angle = d.get("angle")
        else:
            confidence = ext_conf or item_conf or 0
            method = getattr(d, "extraction_method", "REGEX")
            source_img_id = getattr(d, "source_image_id", None)
            angle = getattr(d, "angle", None)

        if not angle and source_img_id in image_angle_map:
            angle = image_angle_map[source_img_id]
        if not angle:
            angle = "FRONT" if field_name.lower() in ("product_name", "brand") else "BACK"

        conf_str = f"{int(confidence * 100)}%" if confidence > 0 else "—"

        decl_data.append(
            [
                field_name.replace("_", " ").title(),
                str(value or "N/A"),
                conf_str,
                str(angle).upper(),
                str(method).upper(),
            ]
        )

    if len(decl_data) > 1:

        t_decl = Table(
            decl_data,
            colWidths=[
                125,
                205,
                70,
                70,
                70,
            ],
        )

        t_decl.setStyle(
            TableStyle(
                [
                    (
                        "BACKGROUND",
                        (0, 0),
                        (-1, 0),
                        colors.HexColor("#0f172a"),
                    ),

                    (
                        "TEXTCOLOR",
                        (0, 0),
                        (-1, 0),
                        colors.white,
                    ),

                    (
                        "GRID",
                        (0, 0),
                        (-1, -1),
                        0.5,
                        colors.HexColor("#e2e8f0"),
                    ),

                    (
                        "FONTNAME",
                        (0, 0),
                        (-1, 0),
                        "Helvetica-Bold",
                    ),

                    (
                        "FONTSIZE",
                        (0, 0),
                        (-1, -1),
                        8.5,
                    ),

                    (
                        "PADDING",
                        (0, 0),
                        (-1, -1),
                        5,
                    ),
                ]
            )
        )

        story.append(t_decl)

    story.append(
        Spacer(1, 15)
    )

    # COMPLIANCE FINDINGS

    story.append(
        Paragraph(
            "<b>Legal Metrology Compliance Findings</b>",
            styles["Heading2"],
        )
    )

    story.append(
        Spacer(1, 6)
    )

    find_data = [
        [
            "Rule Clause",
            "Statutory Requirement",
            "Result",
            "Observations / Findings",
        ]
    ]

    for f in findings:
        clause_val = getattr(f, "clause", None) or getattr(f, "rule_number", None) or getattr(f, "rule_id", "Rule")
        clause_str = str(clause_val)
        if not clause_str.startswith("Rule") and not clause_str.startswith("PC-"):
            clause_str = f"Rule {clause_str}"

        requirement = (
            f.requirement[:50] + "..."
            if f.requirement
            and len(f.requirement) > 50
            else (f.requirement or "")
        )

        reason = (
            f.reason[:60] + "..."
            if f.reason
            and len(f.reason) > 60
            else (f.reason or "")
        )

        find_data.append(
            [
                clause_str,
                requirement,
                f.result,
                reason,
            ]
        )

    if len(find_data) > 1:

        t_find = Table(
            find_data,
            colWidths=[
                80,
                180,
                70,
                200,
            ],
        )

        t_find.setStyle(
            TableStyle(
                [
                    (
                        "BACKGROUND",
                        (0, 0),
                        (-1, 0),
                        colors.HexColor("#1e3a8a"),
                    ),

                    (
                        "TEXTCOLOR",
                        (0, 0),
                        (-1, 0),
                        colors.white,
                    ),

                    (
                        "GRID",
                        (0, 0),
                        (-1, -1),
                        0.5,
                        colors.HexColor("#e2e8f0"),
                    ),

                    (
                        "FONTNAME",
                        (0, 0),
                        (-1, 0),
                        "Helvetica-Bold",
                    ),

                    (
                        "FONTSIZE",
                        (0, 0),
                        (-1, -1),
                        8,
                    ),

                    (
                        "PADDING",
                        (0, 0),
                        (-1, -1),
                        5,
                    ),
                ]
            )
        )

        story.append(t_find)

    # Images section
    if images and HAS_REPORTLAB:
        story.append(Spacer(1, 15))
        story.append(
            Paragraph(
                "<b>Supporting Photographic Evidence</b>",
                styles["Heading2"],
            )
        )
        story.append(Spacer(1, 8))

        evidence_rows = []
        current_row = []
        for img in images:
            img_bytes = _fetch_image_bytes(img)
            cell_items = []
            if img_bytes:
                try:
                    rl_img = RLImage(BytesIO(img_bytes), width=180, height=135)
                    cell_items.append(rl_img)
                    cell_items.append(Spacer(1, 4))
                except Exception:
                    cell_items.append(Paragraph("(Preview unavailable)", styles["Normal"]))
            else:
                cell_items.append(Paragraph("(Image not available)", styles["Normal"]))

            angle_lbl = getattr(img, "angle", "N/A") or "N/A"
            cell_items.append(
                Paragraph(f"<b>Angle:</b> {angle_lbl}", styles["Normal"])
            )
            sha = getattr(img, "sha256", None)
            if sha:
                cell_items.append(
                    Paragraph(f"<b>SHA-256:</b> {sha[:16]}...", styles["Normal"])
                )

            current_row.append(cell_items)
            if len(current_row) == 2:
                evidence_rows.append(current_row)
                current_row = []

        if current_row:
            current_row.append([])
            evidence_rows.append(current_row)

        if evidence_rows:
            t_evidence = Table(evidence_rows, colWidths=[260, 260])
            t_evidence.setStyle(
                TableStyle([
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("PADDING", (0, 0), (-1, -1), 6),
                ])
            )
            story.append(t_evidence)

    # BUILD PDF

    doc.build(story)

    return buffer.getvalue()

# APPLY INSPECTOR DECISION

def apply_inspector_decision(
    db: Session,
    inspection_id: int,
    decision: str,
    remarks: Optional[str] = None,
) -> Inspection:
    inspection = (
        db.query(Inspection)
        .filter(Inspection.id == inspection_id)
        .first()
    )
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if inspection.status == "FINALIZED":
        raise HTTPException(status_code=400, detail="Cannot alter decision of a finalized inspection.")

    norm_decision = decision.strip().upper()
    if norm_decision in ("COMPLIANT", "PASS"):
        norm_decision = "PASS"
    elif norm_decision in ("NON-COMPLIANT", "NON_COMPLIANT", "FAIL"):
        norm_decision = "FAIL"
    else:
        norm_decision = "REVIEW"

    inspection.compliance_result = norm_decision

    findings = (
        db.query(ComplianceFinding)
        .filter(ComplianceFinding.inspection_id == inspection_id)
        .all()
    )
    if norm_decision == "PASS":
        for f in findings:
            if f.result == "REVIEW":
                f.result = "PASS"
                f.reason = f"Verified and cleared by Legal Metrology Officer{': ' + remarks if remarks else ''}"
                if not f.evidence:
                    f.evidence = "Physical package verified by officer"

    db.commit()
    db.refresh(inspection)
    return inspection


# FINALIZE INSPECTION + CREATE REPORT

def finalize_inspection_and_create_report(
    db: Session,
    inspection_id: int,
    decision: Optional[str] = None,
    remarks: Optional[str] = None,
) -> Tuple[Inspection, InspectionReport]:

    # Fetch inspection

    inspection = (
        db.query(Inspection)
        .filter(
            Inspection.id == inspection_id
        )
        .first()
    )

    if not inspection:

        raise HTTPException(
            status_code=404,
            detail="Inspection not found",
        )

    # Fetch related data

    declarations = (
        db.query(InspectionDeclaration)
        .filter(
            InspectionDeclaration.inspection_id
            == inspection_id
        )
        .all()
    )

    findings = (
        db.query(ComplianceFinding)
        .filter(
            ComplianceFinding.inspection_id
            == inspection_id
        )
        .all()
    )

    # Apply inspector decision override if provided
    if decision and str(decision).strip():
        norm_decision = str(decision).strip().upper()
        if norm_decision in ("COMPLIANT", "PASS"):
            norm_decision = "PASS"
        elif norm_decision in ("NON-COMPLIANT", "NON_COMPLIANT", "FAIL"):
            norm_decision = "FAIL"
        else:
            norm_decision = "REVIEW"

        inspection.compliance_result = norm_decision

        if norm_decision == "PASS":
            for f in findings:
                if f.result == "REVIEW":
                    f.result = "PASS"
                    f.reason = f"Verified and cleared by Legal Metrology Officer{': ' + remarks if remarks else ''}"
                    if not f.evidence:
                        f.evidence = "Physical package verified by officer"

    images = (
        db.query(InspectionImage)
        .filter(
            InspectionImage.inspection_id
            == inspection_id,
            InspectionImage.is_active.is_(True),
        )
        .all()
    )

    # CALCULATE CANONICAL SHA-256

    canonical_hash = (
        calculate_canonical_inspection_hash(
            inspection,
            declarations,
            findings,
            images,
        )
    )

    inspection.canonical_hash = canonical_hash

    inspection.status = "FINALIZED"

    inspection.finalized_at = datetime.utcnow()

    # GENERATE PDF

    pdf_bytes = generate_pdf_report_bytes(
        inspection,
        declarations,
        findings,
        images,
    )

    # CALCULATE PDF SHA-256

    pdf_sha256 = hashlib.sha256(
        pdf_bytes
    ).hexdigest()

    # SAVE PDF TO DISK

    # report_service.py is located at:
    #
    # backend/app/services/report_service.py
    #
    # parents[0] -> services
    # parents[1] -> app
    # parents[2] -> backend

    backend_dir = (
        Path(__file__)
        .resolve()
        .parents[2]
    )

    reports_dir = (
        backend_dir / "reports"
    )

    # Create reports directory if it doesn't exist
    reports_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    report_filename = (
        f"inspection_{inspection_id}.pdf"
    )

    report_path = (
        reports_dir / report_filename
    )

    # Write actual PDF bytes to disk
    report_path.write_bytes(
        pdf_bytes
    )

    # CREATE REPORT DATABASE RECORD

    report = InspectionReport(
        inspection_id=inspection_id,
        version=1,
        report_status="FINALIZED",
        pdf_url=f"/reports/{report_filename}",
        sha256=pdf_sha256,
        finalized_at=datetime.utcnow(),
    )

    db.add(report)

    db.commit()

    db.refresh(inspection)

    db.refresh(report)

    # RETURN

    return inspection, report

# JSON export
def generate_json_report(
    inspection: Inspection,
    declarations: list,
    findings: list,
    images: Optional[list] = None,
) -> dict:
    return {
        "inspection_id": inspection.id,
        "inspector_id": inspection.inspector_id,
        "status": inspection.status,
        "compliance_result": inspection.compliance_result,
        "canonical_hash": inspection.canonical_hash,
        "created_at": format_utc_iso(inspection.created_at),
        "finalized_at": format_utc_iso(inspection.finalized_at),
        "product": {
            "name": inspection.product_name,
            "brand": inspection.brand,
            "mrp": inspection.mrp,
            "net_quantity": inspection.net_quantity,
            "country_of_origin": inspection.country_of_origin,
        },
        "declarations": [
            {
                "field_name": d.field_name,
                "value": d.value,
                "confidence": d.extraction_confidence or d.confidence,
                "extraction_method": d.extraction_method,
                "evidence_text": d.evidence_text,
            }
            for d in declarations
            if getattr(d, "field_name", "").lower() != "legibility"
        ],
        "findings": [
            {
                "rule_id": f.rule_id,
                "rule_number": f.rule_number,
                "clause": f.clause,
                "requirement": f.requirement,
                "result": f.result,
                "reason": f.reason,
            }
            for f in findings
        ],
        "images": [
            {
                "id": img.id,
                "angle": img.angle,
                "capture_source": img.capture_source,
                "image_url": img.image_url,
                "sha256": img.sha256,
            }
            for img in (images or [])
        ],
    }

# CSV export
def generate_csv_report(
    inspection: Inspection,
    declarations: list,
    findings: list,
) -> str:
    output = StringIO()
    writer = csv.writer(output)

    writer.writerow(["PARAKH LEGAL METROLOGY INSPECTION REPORT"])
    writer.writerow(["Inspection ID", inspection.id])
    writer.writerow(["Status", inspection.status])
    writer.writerow(["Compliance Result", inspection.compliance_result])
    writer.writerow(["Canonical Hash", inspection.canonical_hash or "N/A"])
    writer.writerow(["Created At", inspection.created_at.isoformat() if inspection.created_at else "N/A"])
    writer.writerow([])

    writer.writerow(["PRODUCT DETAILS"])
    writer.writerow(["Product Name", inspection.product_name or "N/A"])
    writer.writerow(["Brand", inspection.brand or "N/A"])
    writer.writerow(["MRP", inspection.mrp or "N/A"])
    writer.writerow(["Net Quantity", inspection.net_quantity or "N/A"])
    writer.writerow(["Country of Origin", inspection.country_of_origin or "N/A"])
    writer.writerow([])

    writer.writerow(["DECLARATIONS"])
    writer.writerow(["Field Name", "Value", "Confidence", "Method"])
    for d in declarations:
        if getattr(d, "field_name", "").lower() == "legibility":
            continue
        conf = f"{int((d.extraction_confidence or d.confidence or 0) * 100)}%"
        writer.writerow([d.field_name, d.value or "N/A", conf, d.extraction_method or "N/A"])
    writer.writerow([])

    writer.writerow(["COMPLIANCE FINDINGS"])
    writer.writerow(["Rule Clause", "Requirement", "Result", "Reason"])
    for f in findings:
        clause_val = getattr(f, "clause", None) or getattr(f, "rule_number", None) or getattr(f, "rule_id", "Rule")
        writer.writerow([clause_val, f.requirement or "", f.result, f.reason or ""])

    return output.getvalue()