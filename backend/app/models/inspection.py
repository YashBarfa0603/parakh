from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Inspection(Base):
    __tablename__ = "inspections"

    # Unique database ID for every inspection
    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    # Which inspector performed this inspection
    inspector_id: Mapped[int] = mapped_column(
        ForeignKey("inspectors.id"),
        nullable=False,
        index=True
    )

    # Inspector-scoped sequential number (e.g. 1, 2, 3...)
    inspector_seq: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True
    )

    # Formatted inspector-scoped inspection ID (e.g. INSP-DL01-0001)
    inspection_number: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True,
        index=True
    )

    # Product Information

    product_name: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True
    )

    product_code: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True
    )

    brand: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True
    )

    # Manufacturer Information
  
    manufacturer_name: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True
    )

    manufacturer_address: Mapped[Optional[str]] = mapped_column(
        String(1000),
        nullable=True
    )

    # Quantity Information

    net_quantity: Mapped[Optional[str]] = mapped_column(
        String(200),
        nullable=True
    )

    quantity_unit: Mapped[Optional[str]] = mapped_column(
        String(50),
        nullable=True
    )

    # Pricing Information

    mrp: Mapped[Optional[str]] = mapped_column(
        String(200),
        nullable=True
    )

    mrp_inclusive_of_taxes: Mapped[Optional[bool]] = mapped_column(
        nullable=True
    )

    # Consumer Care Information

    consumer_care_phone: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True
    )

    consumer_care_email: Mapped[Optional[str]] = mapped_column(
        String(250),
        nullable=True
    )

    consumer_care_address: Mapped[Optional[str]] = mapped_column(
        String(1000),
        nullable=True
    )

    # Country of Origin

    country_of_origin: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True
    )

    # Classification / Category
    category: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True
    )

    commodity_type: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True
    )

    # Importer Information (for imported products)
    importer_name: Mapped[Optional[str]] = mapped_column(
        String(200),
        nullable=True
    )

    importer_address: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True
    )

    # Processing details
    processing_error: Mapped[Optional[str]] = mapped_column(
        String(1000),
        nullable=True
    )

    canonical_hash: Mapped[Optional[str]] = mapped_column(
        String(64),
        nullable=True
    )

    finalized_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime,
        nullable=True
    )

    # Inspection Processing
    
    status: Mapped[str] = mapped_column(
        String(30),
        default="PENDING"
    )

    # Final compliance result
    compliance_result: Mapped[Optional[str]] = mapped_column(
        String(30),
        nullable=True
    )

    # Timestamps

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )

    # Relationship with Inspector
    inspector = relationship(
        "Inspector",
        back_populates="inspections"
    )

    # One inspection can have multiple images
    images = relationship(
        "InspectionImage",
        back_populates="inspection",
        cascade="all, delete-orphan"
    )

    # One inspection can have multiple report versions
    reports = relationship(
        "InspectionReport",
        back_populates="inspection",
        cascade="all, delete-orphan"
    )

    # One inspection has one batch
    batch = relationship(
        "Batch",
        back_populates="inspection",
        uselist=False,
        cascade="all, delete-orphan"
    )

    # One inspection can have multiple extracted declarations
    declarations = relationship(
        "InspectionDeclaration",
        back_populates="inspection",
        cascade="all, delete-orphan"
    )

    # One inspection can have multiple compliance findings
    findings = relationship(
        "ComplianceFinding",
        back_populates="inspection",
        cascade="all, delete-orphan"
    )