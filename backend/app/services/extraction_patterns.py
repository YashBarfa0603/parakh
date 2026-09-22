
#Extraction Patterns for PARAKH Declaration Extraction.

#All regex patterns, label aliases, date formats, quantity patterns,
#price patterns, contact patterns, and country patterns are centralized here.

#Patterns are separated from extraction logic so they can be
#updated independently without changing extraction service code.

from __future__ import annotations

import re
from typing import Optional

# LABEL ALIASES
# Each key maps to a list of known textual labels/aliases that may appear
# on packaging. Used for label-based (explicit) extraction.

LABEL_ALIASES = {
    "mrp": [
        r"M\.?\s*R\.?\s*P\.?",
        r"MAXIMUM\s+RETAIL\s+PRICE",
        r"RETAIL\s+SALE\s+PRICE",
        r"RSP",
    ],
    "net_quantity": [
        r"NET\s*(?:QTY|QUANTITY|WT\.?|WEIGHT|CONTENT|CONTENTS)",
        r"NET\s+WEIGHT",
        r"CONTENTS?\s*:",
    ],
    "product_name": [
        r"PRODUCT\s+NAME",
        r"NAME\s+OF\s+(?:THE\s+)?(?:COMMODITY|PRODUCT|FOOD)",
        r"COMMON\s+NAME",
        r"GENERIC\s+NAME",
    ],
    "common_generic_name": [
        r"COMMON\s+(?:OR\s+)?GENERIC\s+NAME",
        r"GENERIC\s+NAME",
        r"COMMON\s+NAME",
    ],
    "brand": [
        r"BRAND\s*(?:NAME)?",
    ],
    "manufacturer_name": [
        r"MANUFACTURED\s+BY",
        r"MFG\.?\s+BY",
        r"MFGD\.?\s+BY",
        r"MFD\.?\s+BY",
        r"MANUFACTURER",
    ],
    "packer_name": [
        r"PACKED\s+BY",
        r"PKGD\.?\s+BY",
        r"PACKAGED\s+BY",
        r"PACKER",
        r"REPACKED\s+BY",
    ],
    "importer_name": [
        r"IMPORTED\s+BY",
        r"IMPORTER",
        r"IMP\.?\s+BY",
    ],
    "manufacturer_address": [
        r"REGD\.?\s+OFFICE",
        r"REGISTERED\s+OFFICE",
        r"FACTORY\s+(?:ADDRESS|AT)",
        r"UNIT\s+(?:ADDRESS|AT)",
        r"WORKS?\s+(?:ADDRESS|AT)",
    ],
    "country_of_origin": [
        r"COUNTRY\s+OF\s+ORIGIN",
        r"MADE\s+IN",
        r"PRODUCT\s+OF",
        r"ORIGIN\s*:",
        r"ASSEMBLED\s+IN",
        r"MANUFACTURED\s+IN",
    ],
    "manufacturing_date": [
        r"MFD\.?",
        r"MFG\.?\s*(?:DATE|DT\.?)?",
        r"MANUFACTURED?\s*(?:ON|DATE)?",
        r"MANUFACTURING\s+DATE",
        r"DATE\s+OF\s+MANUFACTURE",
        r"DATE\s+OF\s+MFG\.?",
        r"DOM",
        r"PKD\.?\s*(?:ON|DATE|DT\.?)?",
        r"PACKED?\s*(?:ON|DATE)?",
        r"PACKING\s+DATE",
    ],
    "expiry_date": [
        r"EXP\.?\s*(?:DATE|DT\.?)?",
        r"EXPIRY\s*(?:DATE)?",
        r"EXPIRES?\s*(?:ON|BY)?",
        r"USE\s+BY",
        r"USE\s+BEFORE",
        r"VALID\s+(?:TILL|UNTIL|UPTO|UP\s+TO)",
    ],
    "best_before": [
        r"BEST\s+BEFORE",
        r"BB",
        r"BEST\s+BY",
        r"BEST\s+IF\s+USED\s+BY",
    ],
    "batch_number": [
        r"BATCH\s*(?:NO\.?|NUMBER|#)?",
        r"LOT\s*(?:NO\.?|NUMBER|#)?",
        r"B\.?\s*NO\.?",
        r"L\.?\s*NO\.?",
        r"BATCH\s*/?LOT",
    ],
    "consumer_care_phone": [
        r"CUSTOMER\s+CARE",
        r"CONSUMER\s+CARE",
        r"CUSTOMER\s+SERVICE",
        r"CONSUMER\s+HELPLINE",
        r"TOLL\s+FREE",
        r"HELPLINE",
        r"CALL\s+US",
        r"CONTACT\s+US",
        r"FOR\s+(?:QUERIES|COMPLAINTS|FEEDBACK|SUGGESTIONS)",
    ],
    "consumer_care_email": [
        r"EMAIL\s*:",
        r"E-?MAIL\s*:",
        r"WRITE\s+TO\s+US",
    ],
    "consumer_care_address": [
        r"CONSUMER\s+(?:CARE\s+)?ADDRESS",
        r"CORRESPONDENCE\s+ADDRESS",
        r"COMPLAINTS?\s+(?:TO|ADDRESS)",
    ],
    "unit_sale_price": [
        r"UNIT\s+SALE\s+PRICE",
        r"PRICE\s+PER\s+(?:UNIT|KG|G|L|ML|M|CM)",
    ],
    "dimensions": [
        r"DIMENSIONS?\s*:",
        r"SIZE\s*:",
        r"LENGTH\s*[×xX]\s*WIDTH",
        r"L\s*[×xX]\s*W\s*[×xX]\s*H",
    ],
    "mrp_inclusive_of_taxes": [
        r"INCLUSIVE\s+OF\s+(?:ALL\s+)?TAXES",
        r"INCL\.?\s+(?:OF\s+)?(?:ALL\s+)?TAXES",
        r"\(\s*INCLUSIVE\s+OF\s+(?:ALL\s+)?TAXES\s*\)",
        r"INCLUDING\s+(?:ALL\s+)?TAXES",
    ],
}

# PRICE / CURRENCY PATTERNS

CURRENCY_SYMBOL = r"(?:₹|Rs\.?|INR|MRP)"

# Matches prices like ₹120, Rs. 120.00, INR 99, 120/-
PRICE_PATTERN = re.compile(
    r"(?:"
    + CURRENCY_SYMBOL
    + r")\s*(\d+(?:[.,]\d{1,2})?)"
    r"|(\d+(?:[.,]\d{1,2})?)\s*/\-",
    re.IGNORECASE,
)

# Standalone price — used for contextual extraction when no label
STANDALONE_PRICE = re.compile(
    r"(?:^|\s)"
    r"(?:" + CURRENCY_SYMBOL + r")\s*"
    r"(\d+(?:\.\d{1,2})?)"
    r"(?:\s|$)",
    re.IGNORECASE,
)

# QUANTITY PATTERNS

QUANTITY_UNITS = (
    r"(?:kg|kgs|g|gm|gms|grams?|mg|"
    r"l|lt|ltr|ltrs|litres?|liters?|ml|mL|"
    r"cm|mm|m|"
    r"pieces?|pcs?|nos?|numbers?|units?|"
    r"pairs?|sets?|sheets?|tablets?|capsules?|sachets?)"
)

# Matches "500 g", "1.5 kg", "200 ml" etc.
QUANTITY_WITH_UNIT = re.compile(
    r"(\d+(?:[.,]\d+)?)\s*" + QUANTITY_UNITS,
    re.IGNORECASE,
)

# Unit normalization mapping
UNIT_NORMALIZATION = {
    "gm": "g",
    "gms": "g",
    "gram": "g",
    "grams": "g",
    "g": "g",
    "kg": "kg",
    "kgs": "kg",
    "mg": "mg",
    "l": "L",
    "lt": "L",
    "ltr": "L",
    "ltrs": "L",
    "litre": "L",
    "litres": "L",
    "liter": "L",
    "liters": "L",
    "ml": "mL",
    "cm": "cm",
    "mm": "mm",
    "m": "m",
    "piece": "pcs",
    "pieces": "pcs",
    "pcs": "pcs",
    "pc": "pcs",
    "no": "nos",
    "nos": "nos",
    "number": "nos",
    "numbers": "nos",
    "unit": "units",
    "units": "units",
    "pair": "pairs",
    "pairs": "pairs",
    "set": "sets",
    "sets": "sets",
    "sheet": "sheets",
    "sheets": "sheets",
    "tablet": "tablets",
    "tablets": "tablets",
    "capsule": "capsules",
    "capsules": "capsules",
    "sachet": "sachets",
    "sachets": "sachets",
}

def normalize_unit(unit: str) -> str:
    return UNIT_NORMALIZATION.get(unit.lower(), unit.lower())

# DATE PATTERNS

# Month names and abbreviations
MONTH_NAMES = {
    "jan": "01", "january": "01",
    "feb": "02", "february": "02",
    "mar": "03", "march": "03",
    "apr": "04", "april": "04",
    "may": "05",
    "jun": "06", "june": "06",
    "jul": "07", "july": "07",
    "aug": "08", "august": "08",
    "sep": "09", "sept": "09", "september": "09",
    "oct": "10", "october": "10",
    "nov": "11", "november": "11",
    "dec": "12", "december": "12",
}

# Various date formats found on Indian packaging
DATE_PATTERNS = [
    # DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    re.compile(
        r"(\d{1,2})\s*[/\-\.]\s*(\d{1,2})\s*[/\-\.]\s*(\d{4})",
    ),
    # MM/YYYY or MM-YYYY or MM.YYYY
    re.compile(
        r"(\d{1,2})\s*[/\-\.]\s*(\d{4})",
    ),
    # YYYY/MM or YYYY-MM
    re.compile(
        r"(\d{4})\s*[/\-\.]\s*(\d{1,2})",
    ),
    # MMM YYYY or MMM-YYYY (e.g., "Mar 2026", "JAN-2025")
    re.compile(
        r"([A-Za-z]{3,9})\s*[/\-\.]?\s*(\d{4})",
    ),
    # DD MMM YYYY (e.g., "15 Mar 2026")
    re.compile(
        r"(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})",
    ),
    # DD/MM/YY or DD-MM-YY
    re.compile(
        r"(\d{1,2})\s*[/\-\.]\s*(\d{1,2})\s*[/\-\.]\s*(\d{2})\b",
    ),
    # MM/YY
    re.compile(
        r"(\d{1,2})\s*[/\-\.]\s*(\d{2})\b",
    ),
]

def parse_date_string(text: str) -> Optional[dict]:
    text = text.strip()

    # DD/MM/YYYY
    match = re.match(r"^(\d{1,2})\s*[/\-\.]\s*(\d{1,2})\s*[/\-\.]\s*(\d{4})$", text)
    if match:
        return {
            "raw": text,
            "day": match.group(1),
            "month": match.group(2),
            "year": match.group(3),
        }

    # MM/YYYY
    match = re.match(r"^(\d{1,2})\s*[/\-\.]\s*(\d{4})$", text)
    if match:
        return {
            "raw": text,
            "month": match.group(1),
            "year": match.group(2),
        }

    # YYYY/MM
    match = re.match(r"^(\d{4})\s*[/\-\.]\s*(\d{1,2})$", text)
    if match:
        return {
            "raw": text,
            "month": match.group(2),
            "year": match.group(1),
        }

    # MMM YYYY
    match = re.match(r"^([A-Za-z]{3,9})\s*[/\-\.]?\s*(\d{4})$", text)
    if match:
        month_str = match.group(1).lower()
        month_num = MONTH_NAMES.get(month_str)
        if month_num:
            return {
                "raw": text,
                "month": month_num,
                "year": match.group(2),
            }

    # DD MMM YYYY
    match = re.match(r"^(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})$", text)
    if match:
        month_str = match.group(2).lower()
        month_num = MONTH_NAMES.get(month_str)
        if month_num:
            return {
                "raw": text,
                "day": match.group(1),
                "month": month_num,
                "year": match.group(3),
            }

    # DD/MM/YY
    match = re.match(r"^(\d{1,2})\s*[/\-\.]\s*(\d{1,2})\s*[/\-\.]\s*(\d{2})$", text)
    if match:
        year_2 = int(match.group(3))
        year_4 = str(2000 + year_2) if year_2 < 80 else str(1900 + year_2)
        return {
            "raw": text,
            "day": match.group(1),
            "month": match.group(2),
            "year": year_4,
        }

    # MM/YY
    match = re.match(r"^(\d{1,2})\s*[/\-\.]\s*(\d{2})$", text)
    if match:
        year_2 = int(match.group(2))
        year_4 = str(2000 + year_2) if year_2 < 80 else str(1900 + year_2)
        return {
            "raw": text,
            "month": match.group(1),
            "year": year_4,
        }

    return None

# PHONE / EMAIL / CONTACT PATTERNS

# Indian phone numbers: 10 digits, optional +91 / 0 prefix
PHONE_PATTERN = re.compile(
    r"(?:\+91[\s\-]?|0)?"
    r"[6-9]\d{4}[\s\-]?\d{5}"
    r"|1800[\s\-]?\d{3}[\s\-]?\d{3,4}"  # toll-free
    r"|1860[\s\-]?\d{3}[\s\-]?\d{4}",   # paid helpline
    re.IGNORECASE,
)

EMAIL_PATTERN = re.compile(
    r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}",
)

# Website / URL
WEBSITE_PATTERN = re.compile(
    r"(?:https?://)?(?:www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}(?:/[^\s]*)?",
    re.IGNORECASE,
)

# COUNTRY PATTERNS

KNOWN_COUNTRIES = [
    "india", "china", "usa", "united states", "japan",
    "south korea", "korea", "germany", "france", "italy",
    "spain", "uk", "united kingdom", "australia",
    "thailand", "vietnam", "indonesia", "malaysia",
    "taiwan", "bangladesh", "sri lanka", "nepal",
    "pakistan", "singapore", "brazil", "mexico",
    "turkey", "switzerland", "sweden", "netherlands",
    "belgium", "poland", "russia", "canada",
    "new zealand", "philippines", "cambodia",
]

# ADDRESS INDICATORS
# Words/patterns that suggest a line is part of an address.

ADDRESS_INDICATORS = re.compile(
    r"(?:"
    r"road|rd\.?|street|st\.?|"
    r"lane|nagar|colony|"
    r"sector|block|phase|plot|"
    r"industrial\s+(?:area|estate)|"
    r"dist\.?|district|"
    r"pin\s*(?:code)?[\s:\-]*\d{6}|"
    r"\d{6}|"  # 6-digit PIN code
    r"state|taluk|tehsil|"
    r"near|opp\.?|behind|"
    r"floor|building|bldg|"
    r"tower|complex|center|centre|"
    r"village|vill\.?|"
    r"po[\s:\-]|p\.?o\.?[\s:\-]|"
    r"gp[\s:\-]|"
    r"tal[\s:\-]|"
    r"(?:uttar|madhya)\s+pradesh|"
    r"maharashtra|karnataka|tamil\s+nadu|"
    r"kerala|gujarat|rajasthan|"
    r"punjab|haryana|andhra|telangana|"
    r"west\s+bengal|bihar|odisha|"
    r"assam|jharkhand|chhattisgarh|"
    r"uttarakhand|goa|himachal|"
    r"delhi|mumbai|bangalore|bengaluru|"
    r"chennai|hyderabad|kolkata|pune|"
    r"ahmedabad|jaipur|lucknow|kanpur|"
    r"nagpur|indore|bhopal|surat"
    r")",
    re.IGNORECASE,
)

# BATCH / LOT PATTERNS
BATCH_LOT_PATTERN = re.compile(
    r"(?:BATCH(?:\s*(?:NO|NUMBER))?|LOT(?:\s*(?:NO|NUMBER))?|B\.?\s*NO|L\.?\s*NO)"
    r"\s*[:\-]?\s*"
    r"([A-Za-z0-9./-]+)",
    re.IGNORECASE,
)

# DIMENSION PATTERNS

DIMENSION_PATTERN = re.compile(
    r"(\d+(?:\.\d+)?)\s*"
    r"(?:cm|mm|m|inch|in|ft|feet)\s*"
    r"[×xX]\s*"
    r"(\d+(?:\.\d+)?)\s*"
    r"(?:cm|mm|m|inch|in|ft|feet)"
    r"(?:\s*[×xX]\s*(\d+(?:\.\d+)?)\s*(?:cm|mm|m|inch|in|ft|feet))?",
    re.IGNORECASE,
)

# FSSAI / REGULATORY PATTERNS

FSSAI_PATTERN = re.compile(
    r"FSSAI\s*(?:LIC\.?\s*(?:NO\.?)?|LICENSE\s*(?:NO\.?)?)?\s*[:\-]?\s*"
    r"(\d{14})",
    re.IGNORECASE,
)

# HELPER: Build combined label regex for a field

def build_label_regex(field_name: str) -> Optional[re.Pattern]:
    aliases = LABEL_ALIASES.get(field_name)
    if not aliases:
        return None

    combined = "|".join(aliases)
    return re.compile(
        rf"(?:{combined})",
        re.IGNORECASE | re.VERBOSE,
    )

def build_label_value_regex(field_name: str, value_pattern: str = r"(.+?)") -> Optional[re.Pattern]:
    aliases = LABEL_ALIASES.get(field_name)
    if not aliases:
        return None

    combined = "|".join(aliases)
    return re.compile(
        rf"(?:{combined})"
        rf"\s*[:\-]?\s*"
        rf"{value_pattern}",
        re.IGNORECASE,
    )
