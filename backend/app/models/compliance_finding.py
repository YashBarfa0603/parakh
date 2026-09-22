from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class ComplianceFinding(Base):
    __tablename__ = "compliance_findings"

    # Unique finding ID
    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    # Which inspection produced this finding
    inspection_id: Mapped[int] = mapped_column(
        ForeignKey("inspections.id"),
        nullable=False,
        index=True
    )

    # Rule identification
    rule_id: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )

    rule_number: Mapped[str] = mapped_column(
        String(30),
        nullable=False
    )

    clause: Mapped[Optional[str]] = mapped_column(
        String(50),
        nullable=True
    )

    # What the rule requires
    requirement: Mapped[str] = mapped_column(
        String(500),
        nullable=False
    )

    # PASS / FAIL / REVIEW
    result: Mapped[str] = mapped_column(
        String(20),
        nullable=False
    )

    # Evidence detected from OCR / image
    evidence: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True
    )

    # Explanation for the result
    reason: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True
    )

    # Timestamp
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    # Relationship with Inspection
    inspection = relationship(
        "Inspection",
        back_populates="findings"
    )