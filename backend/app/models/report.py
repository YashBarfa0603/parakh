from __future__ import annotations

from datetime import datetime
from typing import Optional
from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from ..database import Base

class InspectionReport(Base):
    __tablename__ = "inspection_reports"

    # Unique ID for every report
    id: Mapped[int] = mapped_column(
        primary_key = True,
        index = True
    )

    # Inspection this report belongs to
    inspection_id: Mapped[int] = mapped_column(
        ForeignKey("inspections.id"),
        nullable = False,
        index = True
    )

    # Report version: 1, 2, 3...
    version: Mapped[int] = mapped_column(
        default = 1
    )

    # DRAFT, FINALIZED
    report_status: Mapped[str] = mapped_column(
        String(20),
        default = "DRAFT"
    )

    # Location of generated PDF in object storage
    pdf_url: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable = True
    )

    # SHA-256 hash of finalized PDF
    sha256: Mapped[Optional[str]] = mapped_column(
        String(64),
        nullable = True
    )

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default = datetime.utcnow
    )

    finalized_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime,
        nullable = True
    )

    # Relationship with Inspection
    inspection = relationship(
        "Inspection",
        back_populates = "reports"
    )