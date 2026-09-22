from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Batch(Base):
    __tablename__ = "batches"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    inspection_id: Mapped[int] = mapped_column(
        ForeignKey("inspections.id"),
        nullable=False,
        unique=True,
        index=True
    )

    batch_number: Mapped[Optional[str]] = mapped_column(
        String(250),
        nullable=True
    )

    manufacturing_date: Mapped[Optional[datetime]] = mapped_column(
        DateTime,
        nullable=True
    )

    expiry_date: Mapped[Optional[datetime]] = mapped_column(
        DateTime,
        nullable=True
    )

    best_before: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True
    )

    raw_manufacturing_date: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True
    )

    raw_expiry_date: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    inspection = relationship(
        "Inspection",
        back_populates="batch"
    )