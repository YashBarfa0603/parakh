from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Float, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class InspectionOCRItem(Base):
    __tablename__ = "inspection_ocr_items"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    ocr_result_id: Mapped[int] = mapped_column(
        ForeignKey("inspection_ocr_results.id"),
        nullable=False,
        index=True
    )

    text: Mapped[str] = mapped_column(
        String(1000),
        nullable=False
    )

    confidence: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True
    )

    bbox_x: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True
    )

    bbox_y: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True
    )

    bbox_width: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True
    )

    bbox_height: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    ocr_result = relationship(
        "InspectionOCRResult",
        back_populates="items"
    )