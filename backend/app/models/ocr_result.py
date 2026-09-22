from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class InspectionOCRResult(Base):
    __tablename__ = "inspection_ocr_results"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    inspection_image_id: Mapped[int] = mapped_column(
        ForeignKey("inspection_images.id"),
        nullable=False,
        index=True
    )

    model_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    model_version: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True
    )

    full_text: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True
    )

    status: Mapped[str] = mapped_column(
        String(30),
        default="PENDING",
        nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    image = relationship(
        "InspectionImage",
        back_populates="ocr_results"
    )

    items = relationship(
        "InspectionOCRItem",
        back_populates="ocr_result",
        cascade="all, delete-orphan"
    )