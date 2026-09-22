from __future__ import annotations

from typing import Optional


class ComplianceRule:
    def __init__(
        self,
        rule_id: str,
        rule_number: str,
        clause: Optional[str],
        requirement: str,
        field_name: str,
        validation_type: str,
        applicability: str = "GENERAL",
        evidence_type: str = "OCR",
        description: Optional[str] = None,
        source_version: Optional[str] = None,
        source: Optional[str] = None,
        severity: str = "REVIEW"
    ):
        self.rule_id = rule_id
        self.rule_number = rule_number
        self.clause = clause
        self.requirement = requirement
        self.field_name = field_name
        self.validation_type = validation_type
        self.applicability = applicability
        self.evidence_type = evidence_type
        self.description = description
        self.source_version = source_version
        self.source = source
        self.severity = severity