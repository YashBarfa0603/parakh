from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Float, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class InspectionDeclaration(Base):
    __tablename__ = "inspection_declarations"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)

    inspection_id: Mapped[int] = mapped_column(
        ForeignKey("inspections.id"),
        nullable=False,
        index=True
    )

    field_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    value: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True
    )

    # Raw value as detected by OCR before any normalization
    raw_value: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True
    )

    # Which image this declaration was extracted from
    source_image_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("inspection_images.id"),
        nullable=True,
        index=True
    )

    # Which specific OCR item produced this extraction
    source_ocr_item_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("inspection_ocr_items.id"),
        nullable=True
    )

    # Legacy: OCR result ID (kept for backward compatibility)
    source_ocr_result_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("inspection_ocr_results.id"),
        nullable=True
    )

    # The raw OCR text that produced this extraction
    evidence_text: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True
    )

    # Extraction-level confidence (separate from OCR confidence)
    extraction_confidence: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True
    )

    # OCR-level confidence for the source item
    confidence: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True
    )

    # Bounding box of the source OCR item / region
    bbox_x: Mapped[Optional[int]] = mapped_column(nullable=True)
    bbox_y: Mapped[Optional[int]] = mapped_column(nullable=True)
    bbox_width: Mapped[Optional[int]] = mapped_column(nullable=True)
    bbox_height: Mapped[Optional[int]] = mapped_column(nullable=True)

    # REGEX / CONTEXTUAL / SPATIAL / HEURISTIC
    extraction_method: Mapped[str] = mapped_column(
        String(30),
        nullable=False
    )

    # EXTRACTED / LOW_CONFIDENCE / PENDING
    status: Mapped[str] = mapped_column(
        String(30),
        default="PENDING",
        nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    # Relationship with Inspection
    inspection = relationship(
        "Inspection",
        back_populates="declarations"
    )