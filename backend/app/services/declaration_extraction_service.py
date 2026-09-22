from __future__ import annotations

import re
from typing import Optional

from sqlalchemy.orm import Session

from ..models import (
    Inspection,
    InspectionImage,
    InspectionOCRItem,
    InspectionOCRResult,
    InspectionDeclaration,
)

from .extraction_patterns import (
    LABEL_ALIASES,
    STANDALONE_PRICE,
    QUANTITY_WITH_UNIT,
    normalize_unit,
    parse_date_string,
    PHONE_PATTERN,
    EMAIL_PATTERN,
    ADDRESS_INDICATORS,
    BATCH_LOT_PATTERN,
    DIMENSION_PATTERN,
)

# TEXT NORMALIZATION

def normalize_ocr_text(text: str) -> str:
    text = text.strip()
    text = re.sub(r"\s+", " ", text)
    return text

# OCR LINE GROUPING (preserved from original, with enhancements)

def group_ocr_items_into_lines(ocr_items: list) -> list[list]:
    items = [
        item for item in ocr_items
        if (
            item.text
            and item.bbox_y is not None
            and item.bbox_height is not None
        )
    ]

    items.sort(key=lambda item: item.bbox_y)

    lines = []

    for item in items:
        item_top = item.bbox_y
        item_bottom = item.bbox_y + item.bbox_height

        best_line = None
        best_overlap = 0.0

        for line in lines:
            line_top = min(x.bbox_y for x in line)
            line_bottom = max(x.bbox_y + x.bbox_height for x in line)

            overlap_top = max(item_top, line_top)
            overlap_bottom = min(item_bottom, line_bottom)
            overlap = max(0, overlap_bottom - overlap_top)

            item_height = item.bbox_height
            line_height = line_bottom - line_top

            denominator = min(item_height, line_height)
            if denominator <= 0:
                continue

            overlap_ratio = overlap / denominator

            if overlap_ratio > best_overlap:
                best_overlap = overlap_ratio
                best_line = line

        if best_line is not None and best_overlap >= 0.5:
            best_line.append(item)
        else:
            lines.append([item])

    # Sort words left → right within each line
    for line in lines:
        line.sort(
            key=lambda item: item.bbox_x if item.bbox_x is not None else 0
        )

    # Sort lines top → bottom
    lines.sort(key=lambda line: min(item.bbox_y for item in line))

    return lines

def build_ocr_text(ocr_items: list) -> str:
    sorted_items = sorted(
        ocr_items,
        key=lambda item: (
            item.bbox_y if item.bbox_y is not None else 0,
            item.bbox_x if item.bbox_x is not None else 0,
        ),
    )
    text = " ".join(item.text for item in sorted_items if item.text)
    return normalize_ocr_text(text)

def build_ocr_lines(ocr_items: list) -> list[str]:
    lines = group_ocr_items_into_lines(ocr_items)
    return [
        " ".join(item.text for item in line)
        for line in lines
    ]

# ENRICHED LINE STRUCTURE

class OCRLine:

    def __init__(self, items: list):
        self.items = items
        self.text = " ".join(item.text for item in items if item.text)
        self.normalized = normalize_ocr_text(self.text)

        # Bounding box for the whole line
        if items:
            self.bbox_x = min(
                i.bbox_x for i in items if i.bbox_x is not None
            ) if any(i.bbox_x is not None for i in items) else None
            self.bbox_y = min(
                i.bbox_y for i in items if i.bbox_y is not None
            ) if any(i.bbox_y is not None for i in items) else None

            xs = [i.bbox_x + i.bbox_width for i in items
                  if i.bbox_x is not None and i.bbox_width is not None]
            ys = [i.bbox_y + i.bbox_height for i in items
                  if i.bbox_y is not None and i.bbox_height is not None]

            if xs and self.bbox_x is not None:
                self.bbox_width = max(xs) - self.bbox_x
            else:
                self.bbox_width = None

            if ys and self.bbox_y is not None:
                self.bbox_height = max(ys) - self.bbox_y
            else:
                self.bbox_height = None
        else:
            self.bbox_x = self.bbox_y = self.bbox_width = self.bbox_height = None

        # Average confidence across items
        confidences = [i.confidence for i in items if i.confidence is not None]
        self.avg_confidence = (
            sum(confidences) / len(confidences) if confidences else None
        )

        # Source OCR item IDs
        self.ocr_item_ids = [i.id for i in items]

    @property
    def upper(self) -> str:
        return self.normalized.upper()

def build_enriched_lines(ocr_items: list, source_image_id: int) -> list[OCRLine]:
    grouped = group_ocr_items_into_lines(ocr_items)
    lines = []
    for group in grouped:
        line = OCRLine(group)
        line.source_image_id = source_image_id
        lines.append(line)
    return lines

# EXTRACTION RESULT

class ExtractionResult:

    def __init__(
        self,
        field_name: str,
        value: str,
        raw_value: str = "",
        confidence: float = 0.5,
        source_image_id: Optional[int] = None,
        source_ocr_item_ids: Optional[list[int]] = None,
        evidence_text: str = "",
        bbox: Optional[dict] = None,
        extraction_method: str = "REGEX",
    ):
        self.field_name = field_name
        self.value = value
        self.raw_value = raw_value or value
        self.confidence = confidence
        self.source_image_id = source_image_id
        self.source_ocr_item_ids = source_ocr_item_ids or []
        self.evidence_text = evidence_text or value
        self.bbox = bbox
        self.extraction_method = extraction_method

    def to_dict(self) -> dict:
        return {
            "field_name": self.field_name,
            "value": self.value,
            "raw_value": self.raw_value,
            "confidence": self.confidence,
            "source_image_id": self.source_image_id,
            "source_ocr_item_ids": self.source_ocr_item_ids,
            "evidence_text": self.evidence_text,
            "bbox": self.bbox,
            "extraction_method": self.extraction_method,
        }

# INDIVIDUAL FIELD EXTRACTORS

def _line_bbox(line: OCRLine) -> Optional[dict]:
    if line.bbox_x is not None:
        return {
            "x": line.bbox_x,
            "y": line.bbox_y,
            "width": line.bbox_width,
            "height": line.bbox_height,
        }
    return None

def _label_match(text: str, field_name: str) -> Optional[re.Match]:
    aliases = LABEL_ALIASES.get(field_name, [])
    for alias in aliases:
        pattern = re.compile(
            rf"(?:{alias})\s*[:\-]?\s*(.+?)$",
            re.IGNORECASE,
        )
        match = pattern.search(text)
        if match:
            return match
    return None

def _label_present(text: str, field_name: str) -> bool:
    aliases = LABEL_ALIASES.get(field_name, [])
    for alias in aliases:
        if re.search(alias, text, re.IGNORECASE):
            return True
    return False

def extract_mrp(line: OCRLine | str) -> Optional[ExtractionResult]:

    if isinstance(line, str):
        text = normalize_ocr_text(line)
        ocr_item_ids = []
        source_image_id = None
        bbox = None
    else:
        text = line.normalized
        ocr_item_ids = line.ocr_item_ids
        source_image_id = getattr(line, "source_image_id", None)
        bbox = _line_bbox(line)

    # Label-based:
    # "MRP ₹120"
    # "MRP Rs. 150"
    # "Maximum Retail Price INR 150"
    for alias in LABEL_ALIASES["mrp"]:

        pattern = re.compile(
            rf"(?:{alias})"
            r"\s*[:\-]?\s*"
            r"(?:₹|Rs\.?|INR)?\s*"
            r"(\d+(?:[.,]\d{1,2})?)",
            re.IGNORECASE,
        )

        match = pattern.search(text)

        if match:
            return ExtractionResult(
                field_name="mrp",
                value=match.group(1).replace(",", "."),
                raw_value=match.group(0),
                confidence=0.95,
                source_image_id=source_image_id,
                source_ocr_item_ids=ocr_item_ids,
                evidence_text=text,
                bbox=bbox,
                extraction_method="REGEX",
            )

    return None

def extract_mrp_contextual(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized
    match = STANDALONE_PRICE.search(text)
    if match:
        price_val = match.group(1)
        if price_val:
            return ExtractionResult(
                field_name="mrp",
                value=price_val,
                raw_value=match.group(0).strip(),
                confidence=0.5,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="CONTEXTUAL",
            )
    return None

def extract_mrp_inclusive_of_taxes(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized
    for alias in LABEL_ALIASES["mrp_inclusive_of_taxes"]:
        if re.search(alias, text, re.IGNORECASE):
            return ExtractionResult(
                field_name="mrp_inclusive_of_taxes",
                value="true",
                raw_value=text,
                confidence=0.90,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="REGEX",
            )
    return None

def extract_net_quantity(
    line: OCRLine | str
) -> Optional[ExtractionResult]:

    if isinstance(line, str):
        text = normalize_ocr_text(line)
        ocr_item_ids = []
        source_image_id = None
        bbox = None
    else:
        text = line.normalized
        ocr_item_ids = line.ocr_item_ids
        source_image_id = getattr(line, "source_image_id", None)
        bbox = _line_bbox(line)

    # Label-based quantity extraction.
    for alias in LABEL_ALIASES["net_quantity"]:

        pattern = re.compile(
            rf"(?:{alias})"
            r"\s*[:\-]?\s*"
            r"(\d+(?:[.,]\d+)?)\s*"
            r"(kg|kgs|g|gm|gms|grams?|mg|l|lt|ltr|ltrs|"
            r"litres?|liters?|ml|mL|cm|mm|m|pieces?|"
            r"pcs?|nos?|numbers?|units?)",
            re.IGNORECASE,
        )

        match = pattern.search(text)

        if match:

            qty = match.group(1).replace(",", ".")
            unit = normalize_unit(match.group(2))

            return ExtractionResult(
                field_name="net_quantity",
                value=f"{qty} {unit}",
                raw_value=match.group(0),
                confidence=0.95,
                source_image_id=source_image_id,
                source_ocr_item_ids=ocr_item_ids,
                evidence_text=text,
                bbox=bbox,
                extraction_method="REGEX",
            )

    return None

def extract_net_quantity_contextual(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized
    match = QUANTITY_WITH_UNIT.search(text)
    if match:
        full_match = match.group(0)
        qty = match.group(1).replace(",", ".")
        # Find the unit part after the number
        unit_match = re.search(
            r"(\d+(?:[.,]\d+)?)\s*"
            r"(kg|kgs|g|gm|gms|grams?|mg|l|lt|ltr|ltrs|litres?|liters?|ml|mL|"
            r"cm|mm|m|pieces?|pcs?|nos?|numbers?|units?)",
            text,
            re.IGNORECASE,
        )
        if unit_match:
            unit = normalize_unit(unit_match.group(2))
            return ExtractionResult(
                field_name="net_quantity",
                value=f"{qty} {unit}",
                raw_value=full_match,
                confidence=0.4,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="CONTEXTUAL",
            )
    return None

def extract_product_name(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized
    match = _label_match(text, "product_name")
    if match:
        value = normalize_ocr_text(match.group(1))
        if value and len(value) >= 2:
            return ExtractionResult(
                field_name="product_name",
                value=value,
                raw_value=match.group(0),
                confidence=0.90,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="REGEX",
            )
    return None

def extract_common_generic_name(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized
    match = _label_match(text, "common_generic_name")
    if match:
        value = normalize_ocr_text(match.group(1))
        if value and len(value) >= 2:
            return ExtractionResult(
                field_name="common_generic_name",
                value=value,
                raw_value=match.group(0),
                confidence=0.90,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="REGEX",
            )
    return None

def extract_brand(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized
    match = _label_match(text, "brand")
    if match:
        value = normalize_ocr_text(match.group(1))
        if value and len(value) >= 1:
            return ExtractionResult(
                field_name="brand",
                value=value,
                raw_value=match.group(0),
                confidence=0.85,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="REGEX",
            )
    return None

def extract_manufacturer(
    line: OCRLine, following_lines: list[OCRLine]
) -> list[ExtractionResult]:
    results = []
    text = line.normalized

    match = _label_match(text, "manufacturer_name")
    if not match:
        return results

    value = normalize_ocr_text(match.group(1))
    if not value or len(value) < 2:
        return results

    # Manufacturer name
    results.append(ExtractionResult(
        field_name="manufacturer_name",
        value=value,
        raw_value=match.group(0),
        confidence=0.90,
        source_image_id=getattr(line, "source_image_id", None),
        source_ocr_item_ids=line.ocr_item_ids,
        evidence_text=text,
        bbox=_line_bbox(line),
        extraction_method="REGEX",
    ))

    # Try to collect address from following lines
    address_parts = []
    address_ocr_ids = []
    address_evidence = []

    # Check if the same line contains address info after the name
    if ADDRESS_INDICATORS.search(value):
        address_parts.append(value)
        address_ocr_ids.extend(line.ocr_item_ids)
        address_evidence.append(text)

    for next_line in following_lines:
        next_text = next_line.normalized
        # Stop if we hit another label
        if _is_new_label(next_text):
            break
        # Check for address indicators or continuation
        if ADDRESS_INDICATORS.search(next_text) or _looks_like_address_continuation(next_text):
            address_parts.append(next_text)
            address_ocr_ids.extend(next_line.ocr_item_ids)
            address_evidence.append(next_text)
        else:
            # One more line as possible continuation
            if address_parts:
                break
            address_parts.append(next_text)
            address_ocr_ids.extend(next_line.ocr_item_ids)
            address_evidence.append(next_text)

    if address_parts:
        full_address = ", ".join(address_parts)
        results.append(ExtractionResult(
            field_name="manufacturer_address",
            value=full_address,
            raw_value=full_address,
            confidence=0.80,
            source_image_id=getattr(line, "source_image_id", None),
            source_ocr_item_ids=address_ocr_ids,
            evidence_text=" | ".join(address_evidence),
            bbox=_line_bbox(line),
            extraction_method="CONTEXTUAL",
        ))

    return results

def extract_packer(
    line: OCRLine, following_lines: list[OCRLine]
) -> list[ExtractionResult]:
    results = []
    text = line.normalized

    match = _label_match(text, "packer_name")
    if not match:
        return results

    value = normalize_ocr_text(match.group(1))
    if not value or len(value) < 2:
        return results

    results.append(ExtractionResult(
        field_name="packer_name",
        value=value,
        raw_value=match.group(0),
        confidence=0.90,
        source_image_id=getattr(line, "source_image_id", None),
        source_ocr_item_ids=line.ocr_item_ids,
        evidence_text=text,
        bbox=_line_bbox(line),
        extraction_method="REGEX",
    ))

    # Collect address
    address_parts = _collect_address_lines(value, line, following_lines)
    if address_parts:
        full_address = ", ".join(p[0] for p in address_parts)
        all_ids = []
        for p in address_parts:
            all_ids.extend(p[1])
        results.append(ExtractionResult(
            field_name="packer_address",
            value=full_address,
            raw_value=full_address,
            confidence=0.80,
            source_image_id=getattr(line, "source_image_id", None),
            source_ocr_item_ids=all_ids,
            evidence_text=full_address,
            bbox=_line_bbox(line),
            extraction_method="CONTEXTUAL",
        ))

    return results

def extract_importer(
    line: OCRLine, following_lines: list[OCRLine]
) -> list[ExtractionResult]:
    results = []
    text = line.normalized

    match = _label_match(text, "importer_name")
    if not match:
        return results

    value = normalize_ocr_text(match.group(1))
    if not value or len(value) < 2:
        return results

    results.append(ExtractionResult(
        field_name="importer_name",
        value=value,
        raw_value=match.group(0),
        confidence=0.90,
        source_image_id=getattr(line, "source_image_id", None),
        source_ocr_item_ids=line.ocr_item_ids,
        evidence_text=text,
        bbox=_line_bbox(line),
        extraction_method="REGEX",
    ))

    address_parts = _collect_address_lines(value, line, following_lines)
    if address_parts:
        full_address = ", ".join(p[0] for p in address_parts)
        all_ids = []
        for p in address_parts:
            all_ids.extend(p[1])
        results.append(ExtractionResult(
            field_name="importer_address",
            value=full_address,
            raw_value=full_address,
            confidence=0.80,
            source_image_id=getattr(line, "source_image_id", None),
            source_ocr_item_ids=all_ids,
            evidence_text=full_address,
            bbox=_line_bbox(line),
            extraction_method="CONTEXTUAL",
        ))

    return results

def extract_country_of_origin(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    match = _label_match(text, "country_of_origin")
    if match:
        value = normalize_ocr_text(match.group(1))
        # Remove trailing punctuation
        value = re.sub(r"[.,;:]+$", "", value).strip()
        if value and len(value) >= 2:
            return ExtractionResult(
                field_name="country_of_origin",
                value=value,
                raw_value=match.group(0),
                confidence=0.92,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="REGEX",
            )
    return None

def extract_manufacturing_date(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    for alias in LABEL_ALIASES["manufacturing_date"]:
        pattern = re.compile(
            rf"(?:{alias})\s*[:\-]?\s*(.+?)(?:\s+(?:EXP|BEST|USE|BB)|$)",
            re.IGNORECASE,
        )
        match = pattern.search(text)
        if match:
            date_str = normalize_ocr_text(match.group(1))
            # Remove trailing labels
            date_str = re.sub(
                r"\s*(EXP|BEST|USE|BB|MFG|MFD|BATCH|LOT).*$",
                "", date_str, flags=re.IGNORECASE
            ).strip()
            if date_str and len(date_str) >= 4:
                parsed = parse_date_string(date_str)
                if parsed:
                    return ExtractionResult(
                        field_name="manufacturing_date",
                        value=date_str,
                        raw_value=match.group(0),
                        confidence=0.88,
                        source_image_id=getattr(line, "source_image_id", None),
                        source_ocr_item_ids=line.ocr_item_ids,
                        evidence_text=text,
                        bbox=_line_bbox(line),
                        extraction_method="REGEX",
                    )
    return None

def extract_expiry_date(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    for alias in LABEL_ALIASES["expiry_date"]:
        pattern = re.compile(
            rf"(?:{alias})\s*[:\-]?\s*(.+?)$",
            re.IGNORECASE,
        )
        match = pattern.search(text)
        if match:
            date_str = normalize_ocr_text(match.group(1))
            date_str = re.sub(
                r"\s*(MFG|MFD|BATCH|LOT|BEST).*$",
                "", date_str, flags=re.IGNORECASE
            ).strip()
            if date_str and len(date_str) >= 4:
                parsed = parse_date_string(date_str)
                if parsed:
                    return ExtractionResult(
                        field_name="expiry_date",
                        value=date_str,
                        raw_value=match.group(0),
                        confidence=0.88,
                        source_image_id=getattr(line, "source_image_id", None),
                        source_ocr_item_ids=line.ocr_item_ids,
                        evidence_text=text,
                        bbox=_line_bbox(line),
                        extraction_method="REGEX",
                    )
    return None

def extract_best_before(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    for alias in LABEL_ALIASES["best_before"]:
        pattern = re.compile(
            rf"(?:{alias})\s*[:\-]?\s*(.+?)$",
            re.IGNORECASE,
        )
        match = pattern.search(text)
        if match:
            value = normalize_ocr_text(match.group(1))
            value = re.sub(
                r"\s*(MFG|MFD|BATCH|LOT|EXP).*$",
                "", value, flags=re.IGNORECASE
            ).strip()
            if value and len(value) >= 2:
                return ExtractionResult(
                    field_name="best_before",
                    value=value,
                    raw_value=match.group(0),
                    confidence=0.85,
                    source_image_id=getattr(line, "source_image_id", None),
                    source_ocr_item_ids=line.ocr_item_ids,
                    evidence_text=text,
                    bbox=_line_bbox(line),
                    extraction_method="REGEX",
                )
    return None

def extract_batch_number(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    match = BATCH_LOT_PATTERN.search(text)
    if match:
        value = match.group(1).strip()
        if value and len(value) >= 1:
            return ExtractionResult(
                field_name="batch_number",
                value=value,
                raw_value=match.group(0),
                confidence=0.88,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="REGEX",
            )
    return None

def extract_consumer_care_phone(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    # Check if this line has consumer care label context
    has_label = _label_present(text, "consumer_care_phone")

    phone_match = PHONE_PATTERN.search(text)
    if phone_match:
        phone = phone_match.group(0).strip()
        confidence = 0.90 if has_label else 0.50
        return ExtractionResult(
            field_name="consumer_care_phone",
            value=phone,
            raw_value=phone_match.group(0),
            confidence=confidence,
            source_image_id=getattr(line, "source_image_id", None),
            source_ocr_item_ids=line.ocr_item_ids,
            evidence_text=text,
            bbox=_line_bbox(line),
            extraction_method="REGEX" if has_label else "CONTEXTUAL",
        )
    return None

def extract_consumer_care_email(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    email_match = EMAIL_PATTERN.search(text)
    if email_match:
        email = email_match.group(0).strip()
        has_label = _label_present(text, "consumer_care_email") or _label_present(
            text, "consumer_care_phone"
        )
        confidence = 0.90 if has_label else 0.60
        return ExtractionResult(
            field_name="consumer_care_email",
            value=email,
            raw_value=email_match.group(0),
            confidence=confidence,
            source_image_id=getattr(line, "source_image_id", None),
            source_ocr_item_ids=line.ocr_item_ids,
            evidence_text=text,
            bbox=_line_bbox(line),
            extraction_method="REGEX" if has_label else "CONTEXTUAL",
        )
    return None

def extract_consumer_care_address(
    line: OCRLine, following_lines: list[OCRLine]
) -> Optional[ExtractionResult]:
    text = line.normalized

    # Only if we see a consumer care label on this or preceding context
    if not _label_present(text, "consumer_care_address") and \
       not _label_present(text, "consumer_care_phone"):
        return None

    address_parts = _collect_address_lines("", line, following_lines)
    if address_parts:
        full_address = ", ".join(p[0] for p in address_parts)
        all_ids = []
        for p in address_parts:
            all_ids.extend(p[1])
        return ExtractionResult(
            field_name="consumer_care_address",
            value=full_address,
            raw_value=full_address,
            confidence=0.75,
            source_image_id=getattr(line, "source_image_id", None),
            source_ocr_item_ids=all_ids,
            evidence_text=full_address,
            bbox=_line_bbox(line),
            extraction_method="CONTEXTUAL",
        )
    return None

def extract_consumer_care_name(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    # Look for "Customer Care: <Name>" or "Consumer Care: <Name>"
    for alias in LABEL_ALIASES["consumer_care_phone"]:
        pattern = re.compile(
            rf"(?:{alias})\s*[:\-]?\s*([A-Za-z][A-Za-z\s]+?)(?:\s*[,\-]|\s+\d|$)",
            re.IGNORECASE,
        )
        match = pattern.search(text)
        if match:
            value = normalize_ocr_text(match.group(1))
            # Only if it looks like a name (not a phone number)
            if value and len(value) >= 3 and not re.match(r"^\d", value):
                return ExtractionResult(
                    field_name="consumer_care_name",
                    value=value,
                    raw_value=match.group(0),
                    confidence=0.70,
                    source_image_id=getattr(line, "source_image_id", None),
                    source_ocr_item_ids=line.ocr_item_ids,
                    evidence_text=text,
                    bbox=_line_bbox(line),
                    extraction_method="CONTEXTUAL",
                )
    return None

def extract_unit_sale_price(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    match = _label_match(text, "unit_sale_price")
    if match:
        value = normalize_ocr_text(match.group(1))
        if value:
            return ExtractionResult(
                field_name="unit_sale_price",
                value=value,
                raw_value=match.group(0),
                confidence=0.85,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="REGEX",
            )
    return None

def extract_dimensions(line: OCRLine) -> Optional[ExtractionResult]:
    text = line.normalized

    # Label-based
    match = _label_match(text, "dimensions")
    if match:
        value = normalize_ocr_text(match.group(1))
        if value:
            return ExtractionResult(
                field_name="dimensions",
                value=value,
                raw_value=match.group(0),
                confidence=0.85,
                source_image_id=getattr(line, "source_image_id", None),
                source_ocr_item_ids=line.ocr_item_ids,
                evidence_text=text,
                bbox=_line_bbox(line),
                extraction_method="REGEX",
            )

    # Pattern-based: "20 cm × 15 cm"
    dim_match = DIMENSION_PATTERN.search(text)
    if dim_match:
        return ExtractionResult(
            field_name="dimensions",
            value=dim_match.group(0),
            raw_value=dim_match.group(0),
            confidence=0.75,
            source_image_id=getattr(line, "source_image_id", None),
            source_ocr_item_ids=line.ocr_item_ids,
            evidence_text=text,
            bbox=_line_bbox(line),
            extraction_method="CONTEXTUAL",
        )
    return None

# HELPER FUNCTIONS

# Fields whose labels we recognize
_ALL_LABEL_FIELDS = list(LABEL_ALIASES.keys())

def _is_new_label(text: str) -> bool:
    for field in _ALL_LABEL_FIELDS:
        if _label_present(text, field):
            return True
    return False

def _looks_like_address_continuation(text: str) -> bool:
    if ADDRESS_INDICATORS.search(text):
        return True
    # Lines with commas and mixed alphanumeric often are addresses
    if "," in text and len(text) > 5:
        return True
    return False

def _collect_address_lines(
    initial_text: str,
    current_line: OCRLine,
    following_lines: list[OCRLine],
    max_lines: int = 5,
) -> list[tuple[str, list[int]]]:
    parts = []

    if initial_text and ADDRESS_INDICATORS.search(initial_text):
        parts.append((initial_text, current_line.ocr_item_ids))

    for i, next_line in enumerate(following_lines):
        if i >= max_lines:
            break
        next_text = next_line.normalized
        if _is_new_label(next_text):
            break
        if ADDRESS_INDICATORS.search(next_text) or _looks_like_address_continuation(next_text):
            parts.append((next_text, next_line.ocr_item_ids))
        elif parts:
            # If we already have address parts and this line doesn't look like
            # an address, stop collecting
            break
        else:
            # First line after label might be part of the address
            parts.append((next_text, next_line.ocr_item_ids))

    return parts

# PRODUCT NAME HEURISTIC (when no explicit label)

def extract_product_name_heuristic(
    lines: list[OCRLine],
) -> Optional[ExtractionResult]:
    if not lines:
        return None

    # Find lines with bboxes
    candidates = [
        line for line in lines
        if line.bbox_height is not None
        and line.bbox_height > 0
        and len(line.normalized) >= 2
        # Exclude lines that are clearly labels/declarations
        and not _is_new_label(line.normalized)
        # Exclude lines that are just numbers or very short
        and not re.match(r"^[\d\s.,/\-₹]+$", line.normalized)
    ]

    if not candidates:
        return None

    # Sort by bbox_height descending (largest text first)
    candidates.sort(key=lambda l: l.bbox_height, reverse=True)

    # Take the largest text as candidate product name
    candidate = candidates[0]
    value = candidate.normalized.strip()

    # Additional filtering
    if len(value) < 2 or len(value) > 200:
        return None

    return ExtractionResult(
        field_name="product_name",
        value=value,
        raw_value=value,
        confidence=0.35,
        source_image_id=getattr(candidate, "source_image_id", None),
        source_ocr_item_ids=candidate.ocr_item_ids,
        evidence_text=value,
        bbox=_line_bbox(candidate),
        extraction_method="HEURISTIC",
    )

# BRAND HEURISTIC

def extract_brand_heuristic(
    lines: list[OCRLine],
) -> Optional[ExtractionResult]:
    if not lines:
        return None

    candidates = [
        line for line in lines
        if line.bbox_height is not None
        and line.bbox_height > 0
        and line.bbox_y is not None
        and len(line.normalized) >= 2
        and not _is_new_label(line.normalized)
        and not re.match(r"^[\d\s.,/\-₹]+$", line.normalized)
    ]

    if not candidates:
        return None

    # Sort by position (top of image) then by size
    candidates.sort(key=lambda l: (l.bbox_y, -l.bbox_height))

    if candidates:
        candidate = candidates[0]
        value = candidate.normalized.strip()
        if len(value) >= 2 and len(value) <= 100:
            return ExtractionResult(
                field_name="brand",
                value=value,
                raw_value=value,
                confidence=0.30,
                source_image_id=getattr(candidate, "source_image_id", None),
                source_ocr_item_ids=candidate.ocr_item_ids,
                evidence_text=value,
                bbox=_line_bbox(candidate),
                extraction_method="HEURISTIC",
            )
    return None

# MAIN EXTRACTION PIPELINE

def extract_all_from_lines(
    lines: list[OCRLine],
) -> list[ExtractionResult]:
    results = []

    for i, line in enumerate(lines):
        following = lines[i + 1:]

        # MRP
        r = extract_mrp(line)
        if r:
            results.append(r)

        # MRP inclusive of taxes
        r = extract_mrp_inclusive_of_taxes(line)
        if r:
            results.append(r)

        # Net quantity
        r = extract_net_quantity(line)
        if r:
            results.append(r)

        # Product name (label-based)
        r = extract_product_name(line)
        if r:
            results.append(r)

        # Common/generic name
        r = extract_common_generic_name(line)
        if r:
            results.append(r)

        # Brand (label-based)
        r = extract_brand(line)
        if r:
            results.append(r)

        # Manufacturer
        mfr_results = extract_manufacturer(line, following)
        results.extend(mfr_results)

        # Packer
        pkr_results = extract_packer(line, following)
        results.extend(pkr_results)

        # Importer
        imp_results = extract_importer(line, following)
        results.extend(imp_results)

        # Country of origin
        r = extract_country_of_origin(line)
        if r:
            results.append(r)

        # Manufacturing date
        r = extract_manufacturing_date(line)
        if r:
            results.append(r)

        # Expiry date
        r = extract_expiry_date(line)
        if r:
            results.append(r)

        # Best before
        r = extract_best_before(line)
        if r:
            results.append(r)

        # Batch number
        r = extract_batch_number(line)
        if r:
            results.append(r)

        # Consumer care phone
        r = extract_consumer_care_phone(line)
        if r:
            results.append(r)

        # Consumer care email
        r = extract_consumer_care_email(line)
        if r:
            results.append(r)

        # Consumer care name
        r = extract_consumer_care_name(line)
        if r:
            results.append(r)

        # Consumer care address
        r = extract_consumer_care_address(line, following)
        if r:
            results.append(r)

        # Unit sale price
        r = extract_unit_sale_price(line)
        if r:
            results.append(r)

        # Dimensions
        r = extract_dimensions(line)
        if r:
            results.append(r)

    found_fields = {r.field_name for r in results}

    # Contextual MRP (if no label-based MRP found)
    if "mrp" not in found_fields:
        for line in lines:
            r = extract_mrp_contextual(line)
            if r:
                results.append(r)
                break

    # Contextual net quantity
    if "net_quantity" not in found_fields:
        for line in lines:
            r = extract_net_quantity_contextual(line)
            if r:
                results.append(r)
                break

    # Heuristic product name
    if "product_name" not in found_fields:
        r = extract_product_name_heuristic(lines)
        if r:
            results.append(r)

    # Heuristic brand
    if "brand" not in found_fields:
        r = extract_brand_heuristic(lines)
        if r:
            results.append(r)

    return results

# MULTI-IMAGE COMBINED EXTRACTION

def extract_declarations_from_all_images(
    ocr_items_by_image: dict[int, list],
) -> list[ExtractionResult]:
    all_results = []

    for image_id, ocr_items in ocr_items_by_image.items():
        lines = build_enriched_lines(ocr_items, image_id)
        image_results = extract_all_from_lines(lines)
        all_results.extend(image_results)

    # Deduplicate: keep highest-confidence result per field
    return deduplicate_extractions(all_results)

def deduplicate_extractions(
    results: list[ExtractionResult],
) -> list[ExtractionResult]:
    best_by_field: dict[str, ExtractionResult] = {}

    for result in results:
        field = result.field_name
        if field not in best_by_field:
            best_by_field[field] = result
        else:
            existing = best_by_field[field]
            if result.confidence > existing.confidence:
                best_by_field[field] = result

    return list(best_by_field.values())

# LEGACY COMPATIBILITY
# These functions maintain backward compatibility with existing code
# that calls the old extraction interface.

def extract_declarations_from_ocr_items(
    ocr_items: list,
) -> list[dict]:
    lines = build_enriched_lines(ocr_items, source_image_id=0)
    results = extract_all_from_lines(lines)
    deduped = deduplicate_extractions(results)
    return [r.to_dict() for r in deduped]

def extract_declarations_from_multi_image_ocr(ocr_items: list) -> list[dict]:
    ocr_items_by_image: dict[int, list] = {}
    for item in ocr_items:
        img_id = getattr(item, "source_image_id", None)
        if not img_id and hasattr(item, "ocr_result") and item.ocr_result:
            img_id = getattr(item.ocr_result, "inspection_image_id", 0)
        if not img_id:
            img_id = 0
        if img_id not in ocr_items_by_image:
            ocr_items_by_image[img_id] = []
        ocr_items_by_image[img_id].append(item)

    extracted_results = extract_declarations_from_all_images(ocr_items_by_image)
    return [r.to_dict() for r in extracted_results]

def extract_declarations(lines_text: list[str]) -> list[dict]:
    # Create minimal OCR-like objects for compatibility
    class _FakeItem:
        def __init__(self, text, idx):
            self.id = idx
            self.text = text
            self.confidence = None
            self.bbox_x = None
            self.bbox_y = idx * 30
            self.bbox_width = None
            self.bbox_height = 25

    fake_items = [_FakeItem(line, i) for i, line in enumerate(lines_text)]
    return extract_declarations_from_ocr_items(fake_items)

# SAVE DECLARATIONS TO DB

def save_extracted_declarations(
    db: Session,
    inspection_id: int,
    results: list[ExtractionResult] | None = None,
    declarations: list[dict] | None = None,
    ocr_result_id: int | None = None,
) -> list[InspectionDeclaration]:

    if results is None:
        results = []

        for declaration in declarations or []:
            results.append(
                ExtractionResult(
                    field_name=declaration.get("field_name"),
                    value=declaration.get("value"),
                    raw_value=declaration.get(
                        "raw_value",
                        declaration.get("value", ""),
                    ),
                    confidence=declaration.get(
                        "confidence",
                        0.5,
                    ),
                    source_image_id=declaration.get(
                        "source_image_id"
                    ),
                    source_ocr_item_ids=declaration.get(
                        "source_ocr_item_ids",
                        [],
                    ),
                    evidence_text=declaration.get(
                        "evidence_text",
                        declaration.get("value", ""),
                    ),
                    bbox=declaration.get("bbox"),
                    extraction_method=declaration.get(
                        "extraction_method",
                        "HEURISTIC",
                    ),
                )
            )

    saved = []

    # Validate OCR result

    valid_ocr_result_id = None

    if ocr_result_id is not None:
        ocr_result = (
            db.query(InspectionOCRResult)
            .filter(
                InspectionOCRResult.id == ocr_result_id
            )
            .first()
        )

        if ocr_result:
            valid_ocr_result_id = ocr_result.id

    # Validate inspection

    inspection = (
        db.query(Inspection)
        .filter(Inspection.id == inspection_id)
        .first()
    )

    if not inspection:
        raise ValueError(
            f"Inspection {inspection_id} does not exist"
        )

    # Save declarations

    for result in results:

        if not result.field_name:
            continue

        if result.value is None:
            continue

        # Validate source image

        valid_source_image_id = None

        if result.source_image_id is not None:

            source_image = (
                db.query(InspectionImage)
                .filter(
                    InspectionImage.id
                    == result.source_image_id,
                    InspectionImage.inspection_id
                    == inspection_id,
                )
                .first()
            )

            if source_image:
                valid_source_image_id = source_image.id

        # Validate source OCR item

        valid_source_ocr_item_id = None

        if result.source_ocr_item_ids:

            candidate_id = result.source_ocr_item_ids[0]

            if valid_ocr_result_id is not None:

                ocr_item = (
                    db.query(InspectionOCRItem)
                    .filter(
                        InspectionOCRItem.id == candidate_id,
                        InspectionOCRItem.ocr_result_id
                        == valid_ocr_result_id,
                    )
                    .first()
                )

                if ocr_item:
                    valid_source_ocr_item_id = ocr_item.id

        # Bounding box

        bbox = result.bbox or {}

        declaration = InspectionDeclaration(
            inspection_id=inspection_id,

            field_name=result.field_name,

            value=result.value,

            raw_value=result.raw_value,

            source_image_id=valid_source_image_id,

            source_ocr_item_id=valid_source_ocr_item_id,

            source_ocr_result_id=valid_ocr_result_id,

            evidence_text=result.evidence_text,

            extraction_confidence=result.confidence,

            confidence=result.confidence,

            bbox_x=bbox.get("x"),

            bbox_y=bbox.get("y"),

            bbox_width=bbox.get("width"),

            bbox_height=bbox.get("height"),

            extraction_method=result.extraction_method,

            status="EXTRACTED",
        )

        db.add(declaration)

        saved.append(declaration)

    db.flush()

    return saved

def clear_declarations_for_inspection(
    db: Session,
    inspection_id: int,
) -> int:
    count = (
        db.query(InspectionDeclaration)
        .filter(InspectionDeclaration.inspection_id == inspection_id)
        .delete()
    )
    db.flush()
    return count