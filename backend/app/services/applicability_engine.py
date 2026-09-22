#Applicability Engine for PARAKH.

#Determines whether a Legal Metrology rule is:
#    APPLICABLE
#    NOT_APPLICABLE
#    UNKNOWN

#UNKNOWN is intentionally preserved because the absence of OCR evidence
#must not be treated as proof that a condition does not exist.

from __future__ import annotations

from typing import Any, Dict, List

APPLICABLE = "APPLICABLE"
NOT_APPLICABLE = "NOT_APPLICABLE"
UNKNOWN = "UNKNOWN"

class RuleApplicability:

    @staticmethod
    def _get_rule_id(rule: Any) -> str:
        if isinstance(rule, dict):
            return rule.get("rule_id", "")
        return getattr(rule, "rule_id", "")

    @staticmethod
    def _get_rule_field(rule: Any) -> str:
        if isinstance(rule, dict):
            return rule.get("field_name", "")
        return getattr(rule, "field_name", "")

    @staticmethod
    def _normalise_bool(value: Any) -> bool | None:

        if isinstance(value, bool):
            return value

        if value is None:
            return None

        if isinstance(value, str):
            value = value.strip().upper()

            if value in {"TRUE", "YES", "Y", "1"}:
                return True

            if value in {"FALSE", "NO", "N", "0"}:
                return False

        return None

    @staticmethod
    def determine_facts(
        declarations: Dict[str, Any]
    ) -> Dict[str, Any]:

        coo = str(declarations.get("COUNTRY_OF_ORIGIN") or declarations.get("country_of_origin") or "").strip().upper()
        importer = str(declarations.get("IMPORTER_NAME") or declarations.get("importer_name") or "").strip()

        is_imported = RuleApplicability._normalise_bool(
            declarations.get("IS_IMPORTED")
        )
        if is_imported is None:
            if coo:
                is_imported = not ("INDIA" in coo or "IND" in coo)
            elif importer:
                is_imported = True

        is_prepackaged = RuleApplicability._normalise_bool(
            declarations.get("IS_PREPACKAGED")
        )
        if is_prepackaged is None:
            is_prepackaged = True

        is_retail = RuleApplicability._normalise_bool(
            declarations.get("IS_RETAIL")
        )
        if is_retail is None:
            is_retail = True

        is_medical_device = RuleApplicability._normalise_bool(
            declarations.get("IS_MEDICAL_DEVICE")
        )
        if is_medical_device is None:
            is_medical_device = False

        category = declarations.get("CATEGORY")

        if isinstance(category, str):
            category = category.strip().upper()

        return {
            "is_imported": is_imported,
            "is_prepackaged": is_prepackaged,
            "is_retail": is_retail,
            "is_medical_device": is_medical_device,
            "category": category,
        }

    @staticmethod
    def determine_rule_applicability(
        rule: Any,
        declarations: Dict[str, Any],
        facts: Dict[str, Any] | None = None,
    ) -> str:

        if facts is None:
            facts = RuleApplicability.determine_facts(declarations)

        rule_id = RuleApplicability._get_rule_id(rule)

        is_imported = facts.get("is_imported")
        is_prepackaged = facts.get("is_prepackaged")
        is_retail = facts.get("is_retail")
        is_medical_device = facts.get("is_medical_device")

        # General pre-packaged commodity rules

        packaged_rules = {
            "PC-R6-1A",
            "PC-R6-1B",
            "PC-R6-1C",
            "PC-R6-1D",
            "PC-R6-1E",
            "PC-R6-1F",
            "PC-R6-2",
            "PC-R6-11",
            "PC-R9-1A",
        }

        if rule_id in packaged_rules:

            if is_prepackaged is False:
                return NOT_APPLICABLE

            return APPLICABLE

        # Country of origin - Rule 6(1)(aa)

        if rule_id == "PC-R6-AA":

            if is_imported is True:
                return APPLICABLE

            if is_imported is False:
                return NOT_APPLICABLE

            return UNKNOWN

        # Unit sale price - Rule 6(11)

        if rule_id == "PC-R6-11":

            if is_retail is False:
                return NOT_APPLICABLE

            if is_retail is None:
                return UNKNOWN

            return APPLICABLE

        # Medical-device exception
        #
        # Rule 7 measurement requirements have special treatment
        # for applicable medical devices.

        if rule_id == "PC-R6-1F":

            if is_medical_device is True:
                return NOT_APPLICABLE

            if is_medical_device is None:
                return UNKNOWN

            return APPLICABLE

        # Default

        return APPLICABLE

    @staticmethod
    def evaluate_rules(
        rules: List[Any],
        declarations: Dict[str, Any],
    ) -> List[Dict[str, Any]]:

        facts = RuleApplicability.determine_facts(declarations)

        results = []

        for rule in rules:
            applicability = RuleApplicability.determine_rule_applicability(
                rule=rule,
                declarations=declarations,
                facts=facts,
            )

            results.append(
                {
                    "rule": rule,
                    "rule_id": RuleApplicability._get_rule_id(rule),
                    "field_name": RuleApplicability._get_rule_field(rule),
                    "applicability": applicability,
                }
            )

        return results

    @staticmethod
    def filter_applicable_rules(
        rules: List[Any],
        declarations: Dict[str, Any],
    ) -> List[Any]:

        evaluated = RuleApplicability.evaluate_rules(
            rules,
            declarations,
        )

        return [
            item["rule"]
            for item in evaluated
            if item["applicability"] in {
                APPLICABLE,
                UNKNOWN,
            }
        ]