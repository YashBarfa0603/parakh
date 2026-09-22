from __future__ import annotations

from .rule_models import ComplianceRule


RULE_SET_VERSION = "PC_RULES_2026_BASELINE"


PACKAGED_COMMODITY_RULES = [

    ComplianceRule(
        rule_id="PC-R6-1A",
        rule_number="6",
        clause="6(1)(a)",
        requirement="Manufacturer, packer or importer name and address",
        field_name="manufacturer_details",
        validation_type="STRUCTURE",
        applicability="GENERAL",
        evidence_type="OCR",
        description=(
            "The package must carry the applicable manufacturer, "
            "packer and importer identification details."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R6-AA",
        rule_number="6",
        clause="6(1)(aa)",
        requirement="Country of origin for imported packages",
        field_name="country_of_origin",
        validation_type="EXISTS",
        applicability="IMPORTED",
        evidence_type="OCR",
        description=(
            "Country of origin declaration for an imported package."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R6-1B",
        rule_number="6",
        clause="6(1)(b)",
        requirement="Common or generic name of the commodity",
        field_name="product_name",
        validation_type="EXISTS",
        applicability="GENERAL",
        evidence_type="OCR",
        description=(
            "The common or generic name of the commodity "
            "must be declared."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R6-1C",
        rule_number="6",
        clause="6(1)(c)",
        requirement="Net quantity",
        field_name="net_quantity",
        validation_type="QUANTITY",
        applicability="GENERAL",
        evidence_type="OCR",
        description=(
            "Net quantity must be declared in the prescribed "
            "standard unit or number."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R6-1D",
        rule_number="6",
        clause="6(1)(d)",
        requirement="Month and year of manufacture, pre-packing or import",
        field_name="manufacturing_date",
        validation_type="DATE",
        applicability="GENERAL",
        evidence_type="OCR",
        description=(
            "The applicable month and year declaration "
            "must be present."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R6-1E",
        rule_number="6",
        clause="6(1)(e)",
        requirement="Maximum Retail Price",
        field_name="mrp",
        validation_type="MRP",
        applicability="GENERAL",
        evidence_type="OCR",
        description=(
            "Retail sale price must be declared as the "
            "Maximum Retail Price in the prescribed manner."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R6-1F",
        rule_number="6",
        clause="6(1)(f)",
        requirement="Dimensions where relevant",
        field_name="dimensions",
        validation_type="DIMENSIONS",
        applicability="WHERE_RELEVANT",
        evidence_type="OCR_IMAGE",
        description=(
            "Where the size/dimensions of the commodity are relevant, "
            "the prescribed dimensions must be declared."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R6-2",
        rule_number="6",
        clause="6(2)",
        requirement="Consumer complaint contact details",
        field_name="consumer_care",
        validation_type="CONTACT",
        applicability="GENERAL",
        evidence_type="OCR",
        description=(
            "Consumer-care contact information must be declared."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R6-11",
        rule_number="6",
        clause="6(11)",
        requirement="Unit Sale Price",
        field_name="unit_sale_price",
        validation_type="UNIT_SALE_PRICE",
        applicability="APPLICABLE",
        evidence_type="OCR",
        description=(
            "Unit sale price must be declared in the prescribed "
            "manner where applicable."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011 as amended",
        severity="REVIEW"
    ),

    ComplianceRule(
        rule_id="PC-R9-1A",
        rule_number="9",
        clause="9(1)(a)",
        requirement="Declarations must be legible and prominent",
        field_name="declarations",
        validation_type="READABILITY",
        applicability="GENERAL",
        evidence_type="OCR_IMAGE",
        description=(
            "Every required declaration must be legible and prominent."
        ),
        source_version=RULE_SET_VERSION,
        source="Legal Metrology (Packaged Commodities) Rules, 2011",
        severity="REVIEW"
    ),
]


def get_all_rules() -> list[ComplianceRule]:
    return PACKAGED_COMMODITY_RULES