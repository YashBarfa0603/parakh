from __future__ import annotations

from app.database import SessionLocal
from app.rules.packaged_commodity_rules import get_all_rules
from app.rules.rule_evaluator import (
    build_declaration_map,
    evaluate_rules,
    calculate_overall_result
)
from app.services.compliance_finding_service import (
    save_compliance_findings
)


INSPECTION_ID = 6


declarations = [
    {
        "field_name": "product_name",
        "value": "Potato Chips"
    },
    {
        "field_name": "net_quantity",
        "value": "500 g"
    },
    {
        "field_name": "mrp",
        "value": "120.00"
    },
    {
        "field_name": "manufacturing_date",
        "value": "08/2026"
    },
    {
        "field_name": "consumer_care",
        "value": "1800-123-4567"
    },
    {
        "field_name": "country_of_origin",
        "value": "India"
    }
]


db = SessionLocal()

try:
    rules = get_all_rules()

    declaration_map = build_declaration_map(
        declarations
    )

    results = evaluate_rules(
        rules=rules,
        declarations=declaration_map
    )

    overall_result = calculate_overall_result(results)

    findings = save_compliance_findings(
        db=db,
        inspection_id=INSPECTION_ID,
        results=results
    )

    print("\nFINDINGS SAVED")
    print("--------------")

    for finding in findings:
        print(
            f"{finding.rule_id} | "
            f"{finding.result} | "
            f"{finding.evidence}"
        )

    print(f"\nOVERALL RESULT: {overall_result}")

finally:
    db.close()