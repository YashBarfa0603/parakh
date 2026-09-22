from __future__ import annotations

from app.services.declaration_extraction_service import (
    extract_declarations
)


demo_lines = [
    "Product Name: Potato Chips",
    "Net Wt. 500 g",
    "MRP ₹120.00",
    "Mfd: 08/2026",
    "Customer Care: 1800-123-4567",
    "Made in India"
]


declarations = extract_declarations(demo_lines)


print("DEMO DECLARATIONS")
print("-----------------")

for declaration in declarations:
    print(declaration)