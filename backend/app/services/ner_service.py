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

# Marketing and promotional claims that should NEVER be a brand or product name
_MARKETING_SIGNALS = re.compile(
    r"\b("
    r"no\s+artificial|artificial\s+(?:colours?|flav[a-z]*|preservatives?)|"
    r"(?:colours?|flav[a-z]*)\s*&\s*(?:colours?|flav[a-z]*)|"
    r"no\s+(?:added\s+)?(?:preservatives?|msg|sugar|trans\s+fat)|"
    r"100%\s*(?:veg|vegetarian|natural|pure|organic|real|authentic)|"
    r"same\s+great\s+taste|new\s+look|new\s+pack|"
    r"made\s+with\s+(?:the\s+)?(?:finest|real|fresh|pure)|"
    r"cooked\s*&\s*seasoned|seasoned\s+to\s+perfection|perfection|"
    r"deliciously\s+crunchy|crispy\s*&\s*crunchy|extra\s+crunchy|"
    r"rich\s+in\s+protein|source\s+of\s+fibre|zero\s+(?:cholesterol|trans\s+fat)|"
    r"serving\s+suggestion|image\s+for\s+illustration|creative\s+visualization|"
    r"guaranteed\s+fresh|quality\s+seal|pure\s+joy|taste\s+the\s+best|"
    r"premium\s+quality|finest\s+potatoes|unmistakable\s+flavour|"
    r"per\s+serve|energy|kcal|adult\'?s\s+rda"
    r")\b",
    re.IGNORECASE,
)

_KNOWN_BRANDS = {
    "lay's", "lays", "pepsico", "kurkure", "doritos", "cheetos", "pringles",
    "haldiram's", "haldiram", "balaji", "bikaji", "bingo", "crax",
    "britannia", "parle", "amul", "itc", "cadbury", "sunfeast", "oreo",
    "nestle", "maggi", "knorr", "dabur", "patanjali", "kellogg's", "kellogg",
    "saffola", "fortune", "aashirvaad", "mother dairy", "real", "tropicana",
    "coca-cola", "thums up", "sprite", "fanta", "limca", "pepsi", "mirinda",
    "7up", "mountain dew", "red bull", "sting", "frooti", "appy", "paper boat",
    "bournvita", "horlicks", "complan", "boost", "milo", "nescafe", "bru",
    "tata", "taj mahal", "red label", "lipton", "wagh bakri",
    "everest", "mdh", "catch", "badshah", "suhana", "ramdev",
}

def _is_marketing_claim(text: str) -> bool:
    return bool(_MARKETING_SIGNALS.search(text))

def _clean_brand_or_product_text(text: str) -> str:
    # Strip trademark symbols: TM, (TM), ®, (R), ©, (C)
    text = re.sub(r"\b(TM|MR|SM)\b", "", text, flags=re.IGNORECASE)
    text = re.sub(r"[®©™]+", "", text)
    # Strip non-alphanumeric noise at boundaries
    text = re.sub(r"^[^\w]+|[^\w]+$", "", text)
    return re.sub(r"\s+", " ", text).strip()

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

    # Build spatially-ordered lines using robust bounding-box overlap grouping
    from .declaration_extraction_service import group_ocr_items_into_lines
    grouped_rows = group_ocr_items_into_lines(ocr_items)

    class _Line:
        def __init__(self, items):
            self.items = items
            texts = [i.text for i in items if i.text]
            self.text = " ".join(texts)
            heights = [i.bbox_height for i in items if i.bbox_height is not None]
            self.bbox_height = max(heights) if heights else None
            ys = [i.bbox_y for i in items if i.bbox_y is not None]
            self.bbox_y = min(ys) if ys else None
            widths = [i.bbox_width for i in items if i.bbox_width is not None]
            self.bbox_width = sum(widths) if widths else 50

    lines = [_Line(row) for row in grouped_rows if any(i.text for i in row)]

    # 1. Identify Brand
    # First priority: check for known brands in front panel lines
    detected_brand = None
    brand_line = None
    for l in lines:
        cleaned = _clean_brand_or_product_text(l.text)
        for word in cleaned.split():
            clean_word = re.sub(r"[^\w']+", "", word).lower()
            if clean_word in _KNOWN_BRANDS:
                detected_brand = word
                brand_line = l
                break
        if detected_brand:
            break

    if not detected_brand:
        # Fallback: largest prominent non-marketing, non-nutrition line in upper half
        valid_brand_lines = [
            l for l in lines
            if not _is_marketing_claim(l.text)
            and not _is_nutrition_facts_line(l.text)
            and not _is_certification_line(l.text)
            and not _is_all_numbers_or_symbols(l.text)
            and len(_clean_brand_or_product_text(l.text)) >= 2
            and len(_clean_brand_or_product_text(l.text).split()) <= 4
        ]
        if valid_brand_lines:
            valid_brand_lines.sort(
                key=lambda x: ((x.bbox_height or 0) * (x.bbox_width or 1)),
                reverse=True
            )
            brand_line = valid_brand_lines[0]
            detected_brand = _clean_brand_or_product_text(brand_line.text)

    if detected_brand:
        result["brand"] = detected_brand
        logger.info("NER brand: %r", detected_brand)

    # 2. Identify Product Name / Flavor description
    flavor_words = []
    if brand_line:
        bl_text = _clean_brand_or_product_text(brand_line.text)
        bl_words = [
            w for w in bl_text.split()
            if w.lower() not in _KNOWN_BRANDS and w.lower() not in {"brand:", "brand", "tm", "r", "c"}
        ]
        flavor_words.extend(bl_words)

    for l in lines:
        if l == brand_line:
            continue
        # Skip lines physically above the brand logo (promotional claims above logo)
        if brand_line and l.bbox_y is not None and brand_line.bbox_y is not None and l.bbox_y < brand_line.bbox_y:
            continue
        txt = _clean_brand_or_product_text(l.text)
        if not txt or len(txt) < 2:
            continue
        if _is_marketing_claim(txt):
            continue
        if _is_nutrition_facts_line(txt) or re.search(r"\b(serve|energy|kcal|rda|adult)\b", txt, re.IGNORECASE):
            continue
        if re.search(r"\b(net\s*(?:wt|weight|qty|quantity)?|mrp|rs\.?|inr|pkd|mfd|mfg|exp|use\s*by|batch|lot|country|care)\b", txt, re.IGNORECASE):
            continue
        for w in txt.split():
            clean_w = re.sub(r"^[^\w]+|[^\w]+$", "", w)
            if clean_w and clean_w.upper() not in {"TM", "R", "C", "MADE", "WITH"}:
                flavor_words.append(clean_w)

    flavor_text = " ".join(flavor_words[:6]).strip()
    if detected_brand and detected_brand.lower() not in flavor_text.lower():
        product_name = f"{detected_brand} {flavor_text}".strip() if flavor_text else detected_brand
    else:
        product_name = flavor_text or detected_brand

    if product_name:
        result["product_name"] = product_name
        logger.info("NER product_name: %r", product_name)

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
