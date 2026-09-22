from __future__ import annotations

import re
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# NUTRITION FACTS DETECTION

# Patterns that indicate a line is from the Nutrition Facts panel — NOT a
# product identity field.
_NUTRITION_FACTS_SIGNALS = re.compile(
    r"""
    \b(
        nutrition\s+facts?        |
        serving\s+size            |
        servings?\s+per           |
        calories                  |
        total\s+fat               |
        sat(?:urated)?\s+fat      |
        trans\s+fat               |
        cholesterol               |
        sodium                    |
        total\s+carb              |
        dietary\s+fiber           |
        total\s+sugars?           |
        added\s+sugars?           |
        protein                   |
        vitamin\s+[a-z]           |
        daily\s+value             |
        %\s*dv                    |
        % daily                   |
        amount\s+per\s+serving    |
        kcal
    )\b
    """,
    re.IGNORECASE | re.VERBOSE,
)

# Patterns that indicate a line is a certifications / badges, not a product name
_CERTIFICATION_SIGNALS = re.compile(
    r"""
    \b(
        usda\s+organic             |
        certified\s+organic        |
        non.?gmo                   |
        gluten.?free               |
        kosher                     |
        halal                      |
        vegan                      |
        good\s+housekeeping        |
        twice\s+as\s+nice          |
        plastic\s+tray             |
        keep\s+refrigerated        |
        perishable                 |
        best\s+by                  |
        sell\s+by
    )\b
    """,
    re.IGNORECASE | re.VERBOSE,
)

# Common noise words that should NOT be a product name alone
_NOISE_TOKENS = {
    "usda", "organic", "vegan", "calories", "nutrition", "facts",
    "serving", "size", "gluten", "free", "kosher", "halal",
    "perishable", "refrigerated", "tray", "plastic", "aldi", "twice",
    "nice", "guarantee", "housekeeping", "good",
}

def _is_nutrition_facts_line(text: str) -> bool:
    return bool(_NUTRITION_FACTS_SIGNALS.search(text))

def _is_certification_line(text: str) -> bool:
    return bool(_CERTIFICATION_SIGNALS.search(text))

def _is_noisy(text: str) -> bool:
    tokens = re.findall(r"[a-zA-Z]+", text.lower())
    if not tokens:
        return True
    noise_count = sum(1 for t in tokens if t in _NOISE_TOKENS)
    return noise_count / len(tokens) >= 0.6  # >60% noise tokens → skip

def _is_all_numbers_or_symbols(text: str) -> bool:
    clean = re.sub(r"[\d\s%./,()\-₹$+]", "", text)
    # If less than 30% of chars are real letters, it's numeric garbage
    letters = re.findall(r"[a-zA-Z]", text)
    return len(letters) < max(3, len(text) * 0.3)

def _score_product_name_candidate(text: str, bbox_height: Optional[float]) -> float:
    score = 0.0

    # Size bonus — larger text is more likely to be the product name
    if bbox_height:
        score += min(bbox_height / 20.0, 5.0)

    # Length sweet spot: product names are 2–6 words
    words = text.split()
    word_count = len(words)
    if 1 <= word_count <= 6:
        score += 3.0
    elif word_count <= 10:
        score += 1.0
    else:
        score -= 5.0  # Too long → probably not a product name

    # Upper-case bonus (product names often in caps on packaging)
    if text.isupper():
        score += 1.5

    # Title-case bonus
    if text.istitle():
        score += 1.0

    # Heavy penalty for nutrition facts
    if _is_nutrition_facts_line(text):
        score -= 20.0

    # Penalty for certification / badge text
    if _is_certification_line(text):
        score -= 10.0

    # Penalty for noisy tokens
    if _is_noisy(text):
        score -= 8.0

    # Penalty for mostly numbers
    if _is_all_numbers_or_symbols(text):
        score -= 15.0

    # Penalty for text with lots of % signs (Nutrition Facts)
    if text.count("%") >= 2:
        score -= 10.0

    # Bonus for known product-type keywords
    product_keywords = re.compile(
        r"\b(tofu|rice|atta|flour|oil|milk|tea|coffee|sugar|salt|biscuit|"
        r"cookie|chip|juice|water|sauce|paste|masala|spice|dal|lentil|"
        r"soap|shampoo|detergent|cream|lotion|bread|noodle|pasta|cereal|"
        r"chocolate|candy|snack|mix|blend|powder|grain|seed|nut|berry|"
        r"organic|extra\s+firm|firm|soft|light|whole|full|fat|skim)\b",
        re.IGNORECASE,
    )
    if product_keywords.search(text):
        score += 4.0

    return score

# MAIN NER FUNCTION

def run_ner(ocr_items: list) -> dict[str, str | None]:
    if not ocr_items:
        return {}

    result: dict[str, str | None] = {}

    # Build spatially-ordered lines
    # Group items into text lines using y-position proximity
    sorted_items = sorted(
        ocr_items,
        key=lambda i: (
            i.bbox_y if i.bbox_y is not None else 0,
            i.bbox_x if i.bbox_x is not None else 0,
        ),
    )

    # Group into rows
    rows: list[list] = []
    for item in sorted_items:
        if not item.text or not item.text.strip():
            continue
        y = item.bbox_y if item.bbox_y is not None else 0
        h = item.bbox_height if item.bbox_height is not None else 20
        placed = False
        for row in rows:
            row_y = row[0].bbox_y if row[0].bbox_y is not None else 0
            row_h = row[0].bbox_height if row[0].bbox_height is not None else 20
            if abs(y - row_y) <= max(h, row_h) * 0.55:
                row.append(item)
                placed = True
                break
        if not placed:
            rows.append([item])

    # Sort rows top to bottom
    rows.sort(key=lambda r: (r[0].bbox_y if r[0].bbox_y is not None else 0))

    # Build line dicts with aggregated bbox height
    class _Line:
        def __init__(self, items):
            self.items = items
            texts = [i.text for i in items if i.text]
            self.text = " ".join(texts)
            heights = [i.bbox_height for i in items if i.bbox_height is not None]
            self.bbox_height = max(heights) if heights else None
            ys = [i.bbox_y for i in items if i.bbox_y is not None]
            self.bbox_y = min(ys) if ys else None

    lines = [_Line(row) for row in rows if any(i.text for i in row)]

    # Find product name
    # Strategy:
    # 1. Find the single word/token with the largest bbox_height (the hero text)
    # 2. Expand to include immediately adjacent lines of similarly large text
    # 3. Filter out Nutrition Facts, certifications, and noise

    # Filter candidates — exclude Nutrition Facts and noise
    valid_lines = [
        line for line in lines
        if line.text.strip()
        and len(line.text.strip()) >= 2
        and not _is_nutrition_facts_line(line.text)
        and not _is_all_numbers_or_symbols(line.text)
        and line.bbox_height is not None
        and line.bbox_height > 0
    ]

    if valid_lines:
        # Find the line with the maximum bbox_height (hero/largest text)
        hero_line = max(valid_lines, key=lambda l: l.bbox_height or 0)
        hero_h = hero_line.bbox_height or 20
        hero_y = hero_line.bbox_y or 0

        # Collect "large text" lines — at least 40% as tall as the hero,
        # and within 3x hero_height vertically of the hero
        large_threshold = hero_h * 0.4
        vertical_window = hero_h * 3

        product_parts = []
        for line in valid_lines:
            lh = line.bbox_height or 0
            ly = line.bbox_y or 0
            if lh >= large_threshold and abs(ly - hero_y) <= vertical_window:
                raw_text = line.text.strip()
                if _is_certification_line(raw_text) or _is_noisy(raw_text):
                    continue
                # Skip lines that are quantity, price, or date declarations
                if re.search(r"\b(net\s*(?:wt|weight|qty|quantity)?|mrp|rs\.?|inr|pkd|mfd|exp)\b", raw_text, re.IGNORECASE):
                    continue
                # Filter individual tokens within the line
                clean_tokens = []
                for token in raw_text.split():
                    # Skip date-like tokens (e.g. "2023AUGOR", "20AUG06")
                    if re.match(r"^\d{2,4}[A-Z]{2,}\d*$", token, re.IGNORECASE):
                        continue
                    # Skip expiry junk tokens
                    if re.match(r"^[A-Z0-9]{1,3}[Ee8Bb]$", token) and len(token) <= 4:
                        continue
                    # Skip standalone 1-2 char stop words or quantity units
                    if token.upper() in {"BY", "OF", "AT", "AS", "IN", "ON", "TO", "BE", "NET", "WT", "WT.", "WEIGHT", "QTY", "QUANTITY", "G", "GM", "GMS", "KG", "ML", "LTR"}:
                        continue
                    # Skip pure number tokens
                    if re.match(r"^\d+[\d:./]*$", token):
                        continue
                    clean_tokens.append(token)
                if clean_tokens:
                    product_parts.append((ly, " ".join(clean_tokens)))

        if product_parts:
            # Sort by vertical position and join
            product_parts.sort(key=lambda p: p[0])
            combined = " ".join(p[1] for p in product_parts)
            # Truncate to reasonable length (max 6 words)
            words = combined.split()
            if len(words) > 6:
                words = words[:6]
            clean = " ".join(words)
            clean = re.sub(r"\s+", " ", clean).strip()
            clean = re.sub(r"^[^\w]+|[^\w]+$", "", clean)
            if clean and len(clean) >= 2:
                result["product_name"] = clean
                logger.info("NER product_name: %r (hero_h=%.0f)", clean, hero_h)

    # Find brand
    # Brand is usually the topmost text that is:
    # - NOT Nutrition Facts
    # - NOT pure numbers/symbols
    # - NOT the same as product_name
    # - Has reasonable height (at least 15px to filter out tiny text)
    # - Is short (≤4 words)
    for line in lines:  # lines is already sorted top-to-bottom
        text = line.text.strip()
        if not text or len(text) < 2:
            continue
        lh = line.bbox_height or 0
        if lh < 14:  # skip tiny text (fine print)
            continue
        if _is_nutrition_facts_line(text):
            continue
        if _is_all_numbers_or_symbols(text):
            continue
        if len(text.split()) > 4:
            continue
        # Skip pure certification-only words
        cert_only = re.compile(
            r"^(usda|organic|vegan|gluten.?free|kosher|halal|certified|"
            r"good|source|of|protein)\s*$",
            re.IGNORECASE,
        )
        if cert_only.match(text.strip()):
            continue
        if _is_noisy(text):
            continue
        clean = re.sub(r"\s+", " ", text).strip()
        if clean and len(clean) >= 2 and clean != result.get("product_name"):
            result["brand"] = clean
            logger.info("NER brand: %r", clean)
            break

    # Net quantity (unit-level fallback)
    # Only fill if not found by regex pipeline — look for "NET WT X oz/g/kg/ml"
    net_qty_pattern = re.compile(
        r"NET\s+(?:WT|WEIGHT|QTY|QUANTITY|CONTENT)?\.?\s*"
        r"(\d+(?:[.,]\d+)?)\s*"
        r"(oz|fl\.?\s*oz|lb|g|gm|gms|kg|ml|mL|l|L|ltr|litres?)\b"
        r"(?:\s*[(/]\s*(\d+(?:[.,]\d+)?)\s*(g|gm|gms|kg|ml|mL|oz|lb)\s*[)/])?",
        re.IGNORECASE,
    )
    for line in lines:
        m = net_qty_pattern.search(line.text)
        if m:
            # Prefer metric quantity if parenthetical is available
            if m.group(3) and m.group(4):
                val = f"{m.group(3)} {m.group(4)}"
            else:
                val = f"{m.group(1)} {m.group(2)}"
            result["net_quantity"] = val.strip()
            logger.info("NER net_quantity: %r", val)
            break

    return result

def merge_ner_with_regex(
    regex_results: list[dict],
    ner_result: dict[str, str | None],
) -> list[dict]:
    if not ner_result:
        return regex_results

    # Build a map: field_name -> best regex result
    regex_map: dict[str, dict] = {}
    for r in regex_results:
        field = r.get("field_name")
        if not field:
            continue
        if field not in regex_map:
            regex_map[field] = r
        elif r.get("confidence", 0) > regex_map[field].get("confidence", 0):
            regex_map[field] = r

    merged: list[dict] = []
    ner_fields_handled = set()

    # Fields where NER should override heuristic unless regex confidence is high
    ner_override_fields = {"product_name", "brand"}

    for field, ner_value in ner_result.items():
        ner_fields_handled.add(field)

        if not ner_value or not str(ner_value).strip():
            # NER found nothing — keep regex result if any
            if field in regex_map:
                merged.append(regex_map[field])
            continue

        clean_ner_value = str(ner_value).strip()
        regex_hit = regex_map.get(field)

        if regex_hit:
            regex_conf = regex_hit.get("confidence") or 0

            # Never allow NER to override valid regex net_quantity
            if field == "net_quantity" and regex_conf >= 0.50:
                merged.append(regex_hit)
                continue

            if field in ner_override_fields and regex_conf < 0.85:
                # Override heuristic with NER
                merged.append({
                    "field_name": field,
                    "value": clean_ner_value,
                    "raw_value": clean_ner_value,
                    "confidence": 0.78,
                    "source_image_id": regex_hit.get("source_image_id"),
                    "source_ocr_item_ids": regex_hit.get("source_ocr_item_ids", []),
                    "evidence_text": clean_ner_value,
                    "bbox": regex_hit.get("bbox"),
                    "extraction_method": "NER",
                    "angle": regex_hit.get("angle", "FRONT"),
                })
            else:
                # Keep the good regex result
                merged.append(regex_hit)
        else:
            # NER found something regex missed
            merged.append({
                "field_name": field,
                "value": clean_ner_value,
                "raw_value": clean_ner_value,
                "confidence": 0.78,
                "source_image_id": None,
                "source_ocr_item_ids": [],
                "evidence_text": clean_ner_value,
                "bbox": None,
                "extraction_method": "NER",
                "angle": "FRONT",
            })

    # Add any regex fields that NER didn't touch
    for field, r in regex_map.items():
        if field not in ner_fields_handled:
            merged.append(r)

    return merged
