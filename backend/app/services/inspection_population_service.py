
from __future__ import annotations

from typing import List, Dict
from datetime import datetime
from sqlalchemy.orm import Session

from ..models import Inspection, Batch, InspectionDeclaration
from .extraction_patterns import parse_date_string

def populate_inspection_and_batch_from_declarations(
    db: Session,
    inspection: Inspection,
    declarations: List[InspectionDeclaration]
) -> Inspection:
    decl_map: Dict[str, str] = {}
    raw_map: Dict[str, str] = {}
    for d in declarations:
        if d.field_name and d.value:
            key = d.field_name.upper()
            decl_map[key] = d.value
            raw_map[key] = d.raw_value or d.value

    # Update Inspection fields cleanly
    inspection.product_name = (
        decl_map.get("PRODUCT_NAME")
        or decl_map.get("COMMON_GENERIC_NAME")
        or decl_map.get("GENERIC_NAME")
    )
    inspection.product_code = decl_map.get("PRODUCT_CODE")
    inspection.brand = decl_map.get("BRAND")
    inspection.manufacturer_name = decl_map.get("MANUFACTURER_NAME")
    inspection.manufacturer_address = decl_map.get("MANUFACTURER_ADDRESS")
    inspection.net_quantity = decl_map.get("NET_QUANTITY")
    inspection.quantity_unit = decl_map.get("QUANTITY_UNIT")
    inspection.mrp = decl_map.get("MRP")
    inspection.consumer_care_phone = decl_map.get("CONSUMER_CARE_PHONE")
    inspection.consumer_care_email = decl_map.get("CONSUMER_CARE_EMAIL")
    inspection.consumer_care_address = decl_map.get("CONSUMER_CARE_ADDRESS")
    inspection.country_of_origin = decl_map.get("COUNTRY_OF_ORIGIN")
    inspection.category = decl_map.get("CATEGORY")
    inspection.commodity_type = decl_map.get("COMMODITY_TYPE")
    inspection.importer_name = decl_map.get("IMPORTER_NAME")
    inspection.importer_address = decl_map.get("IMPORTER_ADDRESS")

    # Tax inclusive flag check
    if "MRP" in decl_map:
        raw_mrp = raw_map.get("MRP", "").lower()
        inspection.mrp_inclusive_of_taxes = bool("incl" in raw_mrp or "inclusive" in raw_mrp)
    else:
        inspection.mrp_inclusive_of_taxes = None

    # Handle Batch object
    batch = db.query(Batch).filter(Batch.inspection_id == inspection.id).first()
    if not batch:
        batch = Batch(inspection_id=inspection.id)
        db.add(batch)

    batch.batch_number = decl_map.get("BATCH_NUMBER")

    if "MANUFACTURING_DATE" in decl_map:
        raw_mfg = raw_map.get("MANUFACTURING_DATE", decl_map["MANUFACTURING_DATE"])
        batch.raw_manufacturing_date = raw_mfg
        parsed_mfg = parse_date_string(raw_mfg)
        if isinstance(parsed_mfg, dict):
            try:
                y = int(parsed_mfg.get("year", 0))
                m = int(parsed_mfg.get("month", 1))
                d = int(parsed_mfg.get("day", 1))
                if y > 1900 and 1 <= m <= 12 and 1 <= d <= 31:
                    batch.manufacturing_date = datetime(y, m, d)
            except Exception:
                pass
        elif isinstance(parsed_mfg, datetime):
            batch.manufacturing_date = parsed_mfg
    else:
        batch.manufacturing_date = None
        batch.raw_manufacturing_date = None

    if "EXPIRY_DATE" in decl_map:
        raw_exp = raw_map.get("EXPIRY_DATE", decl_map["EXPIRY_DATE"])
        batch.raw_expiry_date = raw_exp
        parsed_exp = parse_date_string(raw_exp)
        if isinstance(parsed_exp, dict):
            try:
                y = int(parsed_exp.get("year", 0))
                m = int(parsed_exp.get("month", 1))
                d = int(parsed_exp.get("day", 1))
                if y > 1900 and 1 <= m <= 12 and 1 <= d <= 31:
                    batch.expiry_date = datetime(y, m, d)
            except Exception:
                pass
        elif isinstance(parsed_exp, datetime):
            batch.expiry_date = parsed_exp
    else:
        batch.expiry_date = None
        batch.raw_expiry_date = None

    batch.best_before = decl_map.get("BEST_BEFORE")

    db.flush()
    return inspection
