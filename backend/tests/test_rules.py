from __future__ import annotations

from app.rules.packaged_commodity_rules import get_all_rules


rules = get_all_rules()

print(f"Total rules: {len(rules)}")

for rule in rules:
    print(
        f"{rule.rule_id} | "
        f"Rule {rule.rule_number} | "
        f"{rule.clause} | "
        f"{rule.requirement} | "
        f"{rule.validation_type}"
    )