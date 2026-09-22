from __future__ import annotations

from app.rules.packaged_commodity_rules import get_all_rules
from app.rules.rule_evaluator import (
    build_declaration_map,
    evaluate_rules,
    calculate_overall_result
)


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


rules = get_all_rules()

declaration_map = build_declaration_map(declarations)

results = evaluate_rules(
    rules=rules,
    declarations=declaration_map
)

print("\nCOMPLIANCE RESULTS")
print("------------------")

for result in results:
    print(
        f"{result['rule_id']} | "
        f"{result['result']} | "
        f"{result['evidence']}"
    )


overall_result = calculate_overall_result(results)

print(f"\nOVERALL RESULT: {overall_result}")