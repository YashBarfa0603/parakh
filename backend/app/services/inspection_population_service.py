
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

    # Update Inspection fields
    if "PRODUCT_NAME" in decl_map:
        inspection.product_name = decl_map["PRODUCT_NAME"]
    elif "COMMON_GENERIC_NAME" in decl_map:
        inspection.product_name = decl_map["COMMON_GENERIC_NAME"]
    elif "GENERIC_NAME" in decl_map:
        inspection.product_name = decl_map["GENERIC_NAME"]
    if "PRODUCT_CODE" in decl_map:
        inspection.product_code = decl_map["PRODUCT_CODE"]
    if "BRAND" in decl_map:
        inspection.brand = decl_map["BRAND"]
    if "MANUFACTURER_NAME" in decl_map:
        inspection.manufacturer_name = decl_map["MANUFACTURER_NAME"]
    if "MANUFACTURER_ADDRESS" in decl_map:
        inspection.manufacturer_address = decl_map["MANUFACTURER_ADDRESS"]
    if "NET_QUANTITY" in decl_map:
        inspection.net_quantity = decl_map["NET_QUANTITY"]
    if "QUANTITY_UNIT" in decl_map:
        inspection.quantity_unit = decl_map["QUANTITY_UNIT"]
    if "MRP" in decl_map:
        inspection.mrp = decl_map["MRP"]
    if "CONSUMER_CARE_PHONE" in decl_map:
        inspection.consumer_care_phone = decl_map["CONSUMER_CARE_PHONE"]
    if "CONSUMER_CARE_EMAIL" in decl_map:
        inspection.consumer_care_email = decl_map["CONSUMER_CARE_EMAIL"]
    if "CONSUMER_CARE_ADDRESS" in decl_map:
        inspection.consumer_care_address = decl_map["CONSUMER_CARE_ADDRESS"]
    if "COUNTRY_OF_ORIGIN" in decl_map:
        inspection.country_of_origin = decl_map["COUNTRY_OF_ORIGIN"]
    if "CATEGORY" in decl_map:
        inspection.category = decl_map["CATEGORY"]
    if "COMMODITY_TYPE" in decl_map:
        inspection.commodity_type = decl_map["COMMODITY_TYPE"]
    if "IMPORTER_NAME" in decl_map:
        inspection.importer_name = decl_map["IMPORTER_NAME"]
    if "IMPORTER_ADDRESS" in decl_map:
        inspection.importer_address = decl_map["IMPORTER_ADDRESS"]

    # Tax inclusive flag check
    if "MRP" in decl_map:
        raw_mrp = raw_map.get("MRP", "").lower()
        if "incl" in raw_mrp or "inclusive" in raw_mrp:
            inspection.mrp_inclusive_of_taxes = True

    # Handle Batch object
    batch = db.query(Batch).filter(Batch.inspection_id == inspection.id).first()
    if not batch:
        batch = Batch(inspection_id=inspection.id)
        db.add(batch)

    if "BATCH_NUMBER" in decl_map:
        batch.batch_number = decl_map["BATCH_NUMBER"]

    if "MANUFACTURING_DATE" in decl_map:
        raw_mfg = raw_map.get("MANUFACTURING_DATE", decl_map["MANUFACTURING_DATE"])
        batch.raw_manufacturing_date = raw_mfg
        parsed_mfg = parse_date_string(raw_mfg)
        if isinstance(parsed_mfg, dict) and parsed_mfg.get("date"):
            batch.manufacturing_date = parsed_mfg["date"]
        elif isinstance(parsed_mfg, datetime):
            batch.manufacturing_date = parsed_mfg

    if "EXPIRY_DATE" in decl_map:
        raw_exp = raw_map.get("EXPIRY_DATE", decl_map["EXPIRY_DATE"])
        batch.raw_expiry_date = raw_exp
        parsed_exp = parse_date_string(raw_exp)
        if isinstance(parsed_exp, dict) and parsed_exp.get("date"):
            batch.expiry_date = parsed_exp["date"]
        elif isinstance(parsed_exp, datetime):
            batch.expiry_date = parsed_exp

    if "BEST_BEFORE" in decl_map:
        batch.best_before = decl_map["BEST_BEFORE"]

    db.flush()
    return inspection
