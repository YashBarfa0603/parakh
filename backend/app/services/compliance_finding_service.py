from __future__ import annotations

from sqlalchemy.orm import Session

from ..models import ComplianceFinding


def save_compliance_findings(
    db: Session,
    inspection_id: int,
    results: list[dict]
) -> list[ComplianceFinding]:

    # Clear existing findings for this inspection to prevent duplicates on re-analysis
    db.query(ComplianceFinding).filter(
        ComplianceFinding.inspection_id == inspection_id
    ).delete(synchronize_session=False)

    findings = []

    for result in results:

        finding = ComplianceFinding(
            inspection_id=inspection_id,
            rule_id=result["rule_id"],
            rule_number=result["rule_number"],
            clause=result["clause"],
            requirement=result["requirement"],
            result=result["result"],
            evidence=result.get("evidence"),
            reason=result.get("reason")
        )

        db.add(finding)
        findings.append(finding)

    db.commit()

    for finding in findings:
        db.refresh(finding)

    return findings
