from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)

    inspection_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("inspections.id"),
        nullable=True,
        index=True
    )

    inspector_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("inspectors.id"),
        nullable=True,
        index=True
    )

    action: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True
    )

    details: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True
    )

    ip_address: Mapped[Optional[str]] = mapped_column(
        String(50),
        nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )
