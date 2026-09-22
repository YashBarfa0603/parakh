from __future__ import annotations

import os
import sys
from sqlalchemy import text

backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app.database import engine, Base

def migrate_database():
    # Ensure base tables exist
    Base.metadata.create_all(bind=engine)

    queries = [
        "ALTER TABLE inspections ALTER COLUMN brand TYPE VARCHAR(1000);",
        "ALTER TABLE inspections ALTER COLUMN country_of_origin TYPE VARCHAR(1000);",
        "ALTER TABLE inspections ALTER COLUMN product_name TYPE VARCHAR(1000);",
        "ALTER TABLE inspections ALTER COLUMN manufacturer_name TYPE VARCHAR(1000);",
        "ALTER TABLE inspections ALTER COLUMN importer_name TYPE VARCHAR(1000);",
        "ALTER TABLE inspections ALTER COLUMN net_quantity TYPE VARCHAR(500);",
        "ALTER TABLE inspections ALTER COLUMN mrp TYPE VARCHAR(500);",
        "ALTER TABLE inspections ALTER COLUMN consumer_care_phone TYPE VARCHAR(500);",
        "ALTER TABLE inspections ALTER COLUMN consumer_care_email TYPE VARCHAR(500);",
        "ALTER TABLE inspections ALTER COLUMN category TYPE VARCHAR(500);",
        "ALTER TABLE inspections ALTER COLUMN commodity_type TYPE VARCHAR(500);",

        "ALTER TABLE batches ALTER COLUMN batch_number TYPE VARCHAR(250);",
        "ALTER TABLE batches ALTER COLUMN best_before TYPE VARCHAR(500);",
        "ALTER TABLE batches ALTER COLUMN raw_manufacturing_date TYPE VARCHAR(500);",
        "ALTER TABLE batches ALTER COLUMN raw_expiry_date TYPE VARCHAR(500);",

        "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS category VARCHAR(100);",
        "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS commodity_type VARCHAR(100);",
        "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS importer_name VARCHAR(200);",
        "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS importer_address VARCHAR(500);",
        "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS processing_error TEXT;",
        "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS canonical_hash VARCHAR(64);",
        "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS finalized_at TIMESTAMP WITHOUT TIME ZONE;",
        
        "ALTER TABLE batches ADD COLUMN IF NOT EXISTS raw_manufacturing_date VARCHAR(100);",
        "ALTER TABLE batches ADD COLUMN IF NOT EXISTS raw_expiry_date VARCHAR(100);",
        
        "ALTER TABLE inspection_declarations ADD COLUMN IF NOT EXISTS raw_value TEXT;",
        "ALTER TABLE inspection_declarations ADD COLUMN IF NOT EXISTS source_image_id INTEGER REFERENCES inspection_images(id);",
        "ALTER TABLE inspection_declarations ADD COLUMN IF NOT EXISTS source_ocr_item_id INTEGER REFERENCES inspection_ocr_items(id);",
        "ALTER TABLE inspection_declarations ADD COLUMN IF NOT EXISTS evidence_text TEXT;",
        "ALTER TABLE inspection_declarations ADD COLUMN IF NOT EXISTS extraction_confidence DOUBLE PRECISION;",
        
        "CREATE TABLE IF NOT EXISTS audit_logs ("
        "  id SERIAL PRIMARY KEY, "
        "  inspection_id INTEGER REFERENCES inspections(id), "
        "  inspector_id INTEGER REFERENCES inspectors(id), "
        "  action VARCHAR(100) NOT NULL, "
        "  details TEXT, "
        "  ip_address VARCHAR(50), "
        "  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP"
        ");"
    ]

    with engine.begin() as conn:
        for q in queries:
            try:
                conn.execute(text(q))
                print(f"SUCCESS: {q}")
            except Exception as e:
                print(f"SKIPPED/INFO: {q} -> {e}")

    print("Migration finished successfully.")

if __name__ == "__main__":
    migrate_database()
