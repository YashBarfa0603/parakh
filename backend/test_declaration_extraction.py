from __future__ import annotations

from app.services.declaration_extraction_service import (
    extract_mrp,
    extract_net_quantity
)


test_lines = [
    "MRP ₹120.00",
    "MRP Rs. 120",
    "Maximum Retail Price INR 150",
    "NET QTY: 500 g",
    "Net Weight 1 kg",
    "Net Wt. 250ml"
]


for line in test_lines:

    print(f"\nTEXT: {line}")

    mrp = extract_mrp(line)

    if mrp:
        print("MRP:", mrp)

    quantity = extract_net_quantity(line)

    if quantity:
        print("QUANTITY:", quantity)