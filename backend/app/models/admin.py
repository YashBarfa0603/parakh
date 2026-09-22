from __future__ import annotations

from datetime import datetime

from sqlalchemy import String, Boolean, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from ..database import Base

#admin model
class Admin(Base):
    __tablename__ = "admins"

    id: Mapped[int] = mapped_column(
        primary_key = True,
        index = True
    )

    name: Mapped[str] = mapped_column(
        String(100),
        nullable = False
    )

    email: Mapped[str] = mapped_column(
        String(150),
        unique = True,
        index = True,
        nullable = False
    )

    password_hash: Mapped[str] = mapped_column(
        String(255),
        nullable = False
    )

    role: Mapped[str] = mapped_column(
        String(20),
        default = "ADMIN",
        nullable = False
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default = True,
        nullable = False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default = datetime.utcnow
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default = datetime.utcnow,
        onupdate = datetime.utcnow
    )