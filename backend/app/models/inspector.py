from __future__ import annotations

from datetime import datetime
from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from ..database import Base
from typing import Optional

class Inspector(Base):
    # means Inspector class = inspector table
    __tablename__ = "inspectors"

    # every inspector gets a unique id
    id: Mapped[int] = mapped_column(primary_key = True, index = True)

    # unique = true maens Two inspectors cannot have same email
    # Two inspectors cannot have same inspector_id

    name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(150), unique = True, index = True)
    phone: Mapped[str] = mapped_column(String(20))

    inspector_id: Mapped[str] = mapped_column(String(50), unique = True, index = True)

    
    department: Mapped[str] = mapped_column(String(150))
    designation: Mapped[str] = mapped_column(String(100))
    office: Mapped[str] = mapped_column(String(150))

    state: Mapped[str] = mapped_column(String(100))
    district: Mapped[str] = mapped_column(String(100))
    city: Mapped[str] = mapped_column(String(100))

    password_hash: Mapped[str] = mapped_column(String(255))

    account_status: Mapped[str] = mapped_column(
        String(20),
        default = "PENDING"
    )

    rejection_reason: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable= True
    )

    # When account was created
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default = datetime.utcnow
    )

    #Last profile update time
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default = datetime.utcnow,
        onupdate = datetime.utcnow
    )

    # One inspector can have many inspections
    inspections = relationship(
        "Inspection",
        back_populates = "inspector"
    )