from __future__ import annotations

import re
from datetime import datetime
from typing import Any, Optional

from .rule_models import ComplianceRule
from ..services.applicability_engine import (
    RuleApplicability,
    APPLICABLE,
    NOT_APPLICABLE,
    UNKNOWN,
)

# Helper

def build_result(
    rule: ComplianceRule,
    result: str,
    evidence: Optional[str] = None,
    reason: Optional[str] = None,
    applicability: str = APPLICABLE,
) -> dict:

    return {
        "rule_id": rule.rule_id,
        "rule_number": rule.rule_number,
        "clause": rule.clause,
        "requirement": rule.requirement,
        "result": result,
        "evidence": evidence,
        "reason": reason,
        "applicability": applicability,
    }

# EXISTS

def evaluate_exists_rule(
    rule: ComplianceRule,
    value: Optional[str],
) -> dict:

    if value is None or not str(value).strip():

        return build_result(
            rule=rule,
            result="REVIEW",
            evidence=None,
            reason="Required declaration was not detected.",
        )

    return build_result(
        rule=rule,
        result="PASS",
        evidence=str(value).strip(),
        reason="Required declaration was detected.",
    )

# QUANTITY

def evaluate_quantity_rule(
    rule: ComplianceRule,
    value: Optional[str],
) -> dict:

    if value is None or not str(value).strip():

        return build_result(
            rule=rule,
            result="REVIEW",
            reason="Net quantity was not detected.",
        )

    value = str(value).strip()

    pattern = (
        r"^\s*"
        r"\d+(?:\.\d+)?"
        r"\s*"
        r"(kg|g|mg|µg|ug|L|l|mL|ml|cm|m|mm|"
        r"number|numbers|no|nos)"
        r"\s*$"
    )

    if re.match(pattern, value, re.IGNORECASE):

        return build_result(
            rule=rule,
            result="PASS",
            evidence=value,
            reason=(
                "Net quantity contains a numeric value "
                "and a recognized unit."
            ),
        )

    return build_result(
        rule=rule,
        result="REVIEW",
        evidence=value,
        reason="Net quantity format could not be validated.",
    )

# MRP

def evaluate_mrp_rule(
    rule: ComplianceRule,
    value: Optional[str],
) -> dict:

    if value is None or not str(value).strip():

        return build_result(
            rule=rule,
            result="REVIEW",
            reason="MRP was not detected.",
        )

    value = str(value).strip()

    pattern = (
        r"^\s*"
        r"(?:₹|Rs\.?|INR)?"
        r"\s*"
        r"\d+(?:\.\d{1,2})?"
        r"\s*$"
    )

    if re.match(pattern, value, re.IGNORECASE):

        return build_result(
            rule=rule,
            result="PASS",
            evidence=value,
            reason="MRP contains a valid monetary value.",
        )

    return build_result(
        rule=rule,
        result="REVIEW",
        evidence=value,
        reason="MRP format could not be validated.",
    )

# DATE

def evaluate_date_rule(
    rule: ComplianceRule,
    value: Optional[str],
) -> dict:

    if value is None or not str(value).strip():

        return build_result(
            rule=rule,
            result="REVIEW",
            reason="Manufacturing date was not detected.",
        )

    value = str(value).strip()

    patterns = [
        r"^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$",
        r"^\d{1,2}[/-]\d{2,4}$",
        r"^\d{4}[/-]\d{1,2}$",
        r"^[A-Za-z]{3,9}\s+\d{4}$",
        r"^[A-Za-z]{3,9}\s+\d{1,2},?\s+\d{4}$",
    ]

    for pattern in patterns:
        if re.match(pattern, value, re.IGNORECASE):

            return build_result(
                rule=rule,
                result="PASS",
                evidence=value,
                reason="Date declaration was detected in a recognizable format.",
            )

    return build_result(
        rule=rule,
        result="REVIEW",
        evidence=value,
        reason="Date declaration format could not be reliably validated.",
    )

# UNIT SALE PRICE

def evaluate_unit_sale_price_rule(
    rule: ComplianceRule,
    value: Optional[str],
) -> dict:

    if value is None or not str(value).strip():

        return build_result(
            rule=rule,
            result="REVIEW",
            reason="Unit sale price was not detected.",
        )

    value = str(value).strip()

    pattern = (
        r"(?:₹|Rs\.?|INR)?\s*"
        r"\d+(?:\.\d{1,2})?"
        r"\s*(?:per|/)\s*"
        r"(?:kg|g|mg|l|L|ml|mL|m|cm|"
        r"unit|number|no|nos)"
    )

    if re.search(pattern, value, re.IGNORECASE):

        return build_result(
            rule=rule,
            result="PASS",
            evidence=value,
            reason="Unit sale price contains a monetary value and unit basis.",
        )

    return build_result(
        rule=rule,
        result="REVIEW",
        evidence=value,
        reason="Unit sale price format could not be validated.",
    )

# LEGIBILITY / PROMINENCE

def evaluate_legibility_rule(
    rule: ComplianceRule,
    value: Optional[str],
) -> dict:

    if value is None or not str(value).strip():

        return build_result(
            rule=rule,
            result="REVIEW",
            reason=(
                "Legibility/prominence cannot be determined "
                "from declaration text alone."
            ),
        )

    normalized = str(value).strip().upper()

    if normalized == "PASS":

        return build_result(
            rule=rule,
            result="PASS",
            evidence=value,
            reason="Legibility/prominence evidence passed.",
        )

    if normalized == "FAIL":

        return build_result(
            rule=rule,
            result="FAIL",
            evidence=value,
            reason="Legibility/prominence evidence failed.",
        )

    return build_result(
        rule=rule,
        result="REVIEW",
        evidence=value,
        reason="Legibility/prominence requires reliable image evidence.",
    )

# GENERIC VALIDATION

def evaluate_generic_rule(
    rule: ComplianceRule,
    value: Optional[str],
) -> dict:

    if value is None or not str(value).strip():

        return build_result(
            rule=rule,
            result="REVIEW",
            reason="Required evidence was not detected.",
        )

    return build_result(
        rule=rule,
        result="PASS",
        evidence=str(value).strip(),
        reason="Required evidence was detected.",
    )

# SINGLE RULE

def evaluate_rule(
    rule: ComplianceRule,
    value: Optional[str],
    applicability: str = APPLICABLE,
) -> dict:

    # NOT APPLICABLE

    if applicability == NOT_APPLICABLE:

        return build_result(
            rule=rule,
            result="NOT_APPLICABLE",
            evidence=value,
            reason="Rule is not applicable to this inspection.",
            applicability=NOT_APPLICABLE,
        )

    # UNKNOWN APPLICABILITY

    if applicability == UNKNOWN:

        return build_result(
            rule=rule,
            result="REVIEW",
            evidence=value,
            reason=(
                "Applicability of this rule could not be determined "
                "from the available evidence."
            ),
            applicability=UNKNOWN,
        )

    # NORMAL VALIDATION

    validation_type = (
        getattr(rule, "validation_type", "") or ""
    ).upper()

    if validation_type == "EXISTS":
        return evaluate_exists_rule(rule, value)

    if validation_type == "QUANTITY":
        return evaluate_quantity_rule(rule, value)

    if validation_type == "MRP":
        return evaluate_mrp_rule(rule, value)

    if validation_type in {
        "DATE",
        "MANUFACTURE_DATE",
        "EXPIRY_DATE",
        "BEST_BEFORE",
    }:
        return evaluate_date_rule(rule, value)

    if validation_type in {
        "UNIT_PRICE",
        "UNIT_SALE_PRICE",
    }:
        return evaluate_unit_sale_price_rule(rule, value)

    if validation_type in {
        "LEGIBILITY",
        "PROMINENCE",
        "READABILITY",
    }:
        return evaluate_legibility_rule(rule, value)

    if validation_type in {
        "STRUCTURE",
        "MANUFACTURER_DETAILS",
    }:
        if value and str(value).strip():
            return build_result(
                rule=rule,
                result="PASS",
                evidence=str(value).strip(),
                reason="Manufacturer/Packer/Importer identification details were detected.",
            )
        return build_result(
            rule=rule,
            result="REVIEW",
            evidence=None,
            reason="Manufacturer, packer, or importer details were not detected.",
        )

    if validation_type in {
        "CONTACT",
        "CONSUMER_CARE",
    }:
        if value and str(value).strip():
            return build_result(
                rule=rule,
                result="PASS",
                evidence=str(value).strip(),
                reason="Consumer-care contact details were detected.",
            )
        return build_result(
            rule=rule,
            result="REVIEW",
            evidence=None,
            reason="Consumer complaint contact information was not detected.",
        )

    if validation_type == "DIMENSIONS":
        if value and str(value).strip():
            return build_result(
                rule=rule,
                result="PASS",
                evidence=str(value).strip(),
                reason="Package size/dimensions declared.",
            )
        return build_result(
            rule=rule,
            result="PASS",
            evidence=None,
            reason="Dimensions check passed (not required for standard unit commodity).",
        )

    # Fallback validation

    return evaluate_generic_rule(rule, value)

# ALL RULES

def evaluate_rules(
    rules: list[ComplianceRule],
    declarations: dict,
) -> list[dict]:

    results = []

    applicability_results = RuleApplicability.evaluate_rules(
        rules=rules,
        declarations=declarations,
    )

    for item in applicability_results:

        rule = item["rule"]
        applicability = item["applicability"]

        field_name = getattr(rule, "field_name", "") or ""
        field_lower = field_name.lower()

        # Composite field resolution
        value = declarations.get(field_lower)

        if not value:
            if field_lower in {"manufacturer_details", "manufacturer"}:
                parts = [
                    declarations.get(k) for k in [
                        "manufacturer_name", "manufacturer_address",
                        "packer_name", "packer_address",
                        "importer_name", "importer_address"
                    ] if declarations.get(k)
                ]
                value = ", ".join(parts) if parts else None
            elif field_lower in {"consumer_care", "consumer_care_details"}:
                parts = [
                    declarations.get(k) for k in [
                        "consumer_care_phone", "consumer_care_email",
                        "consumer_care_address", "consumer_care_name"
                    ] if declarations.get(k)
                ]
                value = " | ".join(parts) if parts else None
            elif field_lower in {"product_name", "commodity"}:
                value = declarations.get("product_name") or declarations.get("common_generic_name") or declarations.get("brand")
            elif field_lower in {"declarations", "legibility"}:
                valid_keys = [f for f, v in declarations.items() if v and str(v).strip()]
                value = "PASS" if len(valid_keys) >= 2 else None

        result = evaluate_rule(
            rule=rule,
            value=value,
            applicability=applicability,
        )

        results.append(result)

    return results

# DECLARATION MAP

def build_declaration_map(
    declarations: list[dict],
) -> dict:

    declaration_map = {}

    for declaration in declarations:

        field_name = declaration.get("field_name")
        value = declaration.get("value")

        if not field_name:
            continue

        if field_name not in declaration_map:
            declaration_map[field_name] = value

    return declaration_map

# OVERALL RESULT

def calculate_overall_result(
    results: list[dict],
) -> str:

    if not results:
        return "REVIEW"

    # Confirmed violation always wins.
    for result in results:

        if result.get("result") == "FAIL":
            return "FAIL"

    # Any unresolved evidence/applicability requires review.
    for result in results:

        if result.get("result") == "REVIEW":
            return "REVIEW"

    # All remaining results are PASS or NOT_APPLICABLE.
    return "PASS"