from __future__ import annotations

from typing import Dict, Any
import re

# Standard units recognized by Legal Metrology (Packaged Commodities) Rules, 2011
MASS_UNITS = {"g": 1.0, "kg": 1000.0, "mg": 0.001}
VOLUME_UNITS = {"ml": 1.0, "l": 1000.0, "cl": 10.0}
LENGTH_UNITS = {"mm": 0.001, "cm": 0.01, "m": 1.0}

def parse_and_normalize_quantity(quantity_str: str) -> Dict[str, Any]:
    if not quantity_str:
        return {"value": None, "unit": None, "base_value": None, "base_unit": None, "is_valid": False}

    pattern = r"^\s*(\d+(?:\.\d+)?)\s*([a-zA-Z]+)\s*$"
    match = re.match(pattern, quantity_str.strip())
    if not match:
        return {"value": None, "unit": None, "base_value": None, "base_unit": None, "is_valid": False}

    num_val = float(match.group(1))
    unit = match.group(2).lower()

    if unit in MASS_UNITS:
        base_val = num_val * MASS_UNITS[unit]
        base_unit = "g"
    elif unit in VOLUME_UNITS:
        base_val = num_val * VOLUME_UNITS[unit]
        base_unit = "ml"
    elif unit in LENGTH_UNITS:
        base_val = num_val * LENGTH_UNITS[unit]
        base_unit = "m"
    else:
        base_val = num_val
        base_unit = unit

    return {
        "value": num_val,
        "unit": unit,
        "base_value": base_val,
        "base_unit": base_unit,
        "is_valid": True
    }

# Heuristic package heights (mm)
DEFAULT_PACKAGE_HEIGHT_MM = 200.0
SMALL_PACKAGE_HEIGHT_MM = 100.0

# Legal Metrology minimums (mm)
MIN_FONT_HEIGHT_STANDARD = 2.0
MIN_FONT_HEIGHT_SMALL = 1.0

# Key fields for readability
READABILITY_FIELDS = {
    "mrp", "net_quantity", "product_name", "manufacturer_name",
    "expiry_date", "manufacturing_date", "country_of_origin",
    "consumer_care_phone", "batch_number",
}

def estimate_font_height_mm(
    bbox_height: int,
    image_height: int,
    package_height_mm: float = DEFAULT_PACKAGE_HEIGHT_MM,
) -> float:
    if not image_height or not bbox_height:
        return 0.0
    mm_per_pixel = package_height_mm / image_height
    return bbox_height * mm_per_pixel

def analyze_readability(
    declarations: list,
    image_heights: Dict[int, int],
) -> Dict[str, Any]:
    results = []
    all_pass = True
    any_fail = False

    for decl in declarations:
        field = getattr(decl, "field_name", "") or ""
        if field.lower() not in READABILITY_FIELDS:
            continue

        bbox_h = getattr(decl, "bbox_height", None)
        img_id = getattr(decl, "source_image_id", None)
        img_h = image_heights.get(img_id, 0) if img_id else 0

        if not bbox_h or not img_h:
            results.append({
                "field": field,
                "estimated_mm": None,
                "min_required_mm": MIN_FONT_HEIGHT_STANDARD,
                "verdict": "REVIEW",
                "reason": "No bbox data",
            })
            all_pass = False
            continue

        est_mm = estimate_font_height_mm(bbox_h, img_h)
        min_req = MIN_FONT_HEIGHT_STANDARD

        if est_mm >= min_req:
            verdict = "PASS"
        elif est_mm >= MIN_FONT_HEIGHT_SMALL:
            verdict = "REVIEW"
            all_pass = False
        else:
            verdict = "FAIL"
            all_pass = False
            any_fail = True

        results.append({
            "field": field,
            "estimated_mm": round(est_mm, 2),
            "min_required_mm": min_req,
            "verdict": verdict,
            "reason": f"{round(est_mm, 2)}mm vs {min_req}mm min",
        })

    if any_fail:
        overall = "FAIL"
    elif all_pass and results:
        overall = "PASS"
    else:
        overall = "REVIEW"

    return {
        "overall": overall,
        "field_results": results,
        "fields_analyzed": len(results),
    }
