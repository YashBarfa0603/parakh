from __future__ import annotations

from datetime import datetime
from typing import Optional
from sqlalchemy import String, DateTime, ForeignKey, Float, Integer,Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from ..database import Base

class InspectionImage(Base):

    __tablename__ = "inspection_images"

    #unique id for every image 
    id: Mapped[int] = mapped_column(
        primary_key = True,
        index = True
    )
    # which inspection this image belongs to
    inspection_id: Mapped[int] = mapped_column(
        ForeignKey("inspections.id"),
        nullable = False,
        index = True
    )

    # FRONT, BACK, TOP, BOTTOM, LEFT, RIGHT
    angle: Mapped[str] = mapped_column(
        String(20),
        nullable = False
    )

    #camera / gallery
    capture_source: Mapped[str] = mapped_column(
        String(20),
        nullable = False
    )

    # location of image in object storage
    image_url: Mapped[str] = mapped_column(
        String(500),
        nullable = False
    )

    #cloudinay public id of stored image
    cloudinary_public_id: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable = True
    )

    # SHA-256 hash of the image
    sha256: Mapped[Optional[str]] = mapped_column(
        String(64),
        nullable = True
    )

    # when image was captured
    captured_at: Mapped[datetime] = mapped_column(
        DateTime,
        default = datetime.utcnow
    )

    # result of image quality check
    image_quality: Mapped[Optional[str]] = mapped_column(
        String(30),
        nullable = True
    )

    # result of image authenticity check
    authenticity_status: Mapped[Optional[str]] = mapped_column(
        String(30),
        nullable = True
    )

    # relationship with inspection
    inspection = relationship(
        "Inspection",
        back_populates = "images"
    )
    # ocr result
    ocr_results = relationship(
    "InspectionOCRResult",
    back_populates="image",
    cascade="all, delete-orphan"
)

    # blur detection score
    blur_score: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True
    )

    # glare detection score
    glare_score: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True
    )

    # perspective / panel alignment score
    perspective_score: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True
    )

    # whether package is correctly aligned inside guided frame
    frame_alignment_status: Mapped[Optional[str]] = mapped_column(
        String(30),
        nullable=True
    )

    # original captured image dimensions
    capture_width: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True
    )

    capture_height: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True
    )

    # whether image is suitable for physical-size measurement
    calibration_status: Mapped[Optional[str]] = mapped_column(
        String(30),
        nullable=True
    )

    # whether this image is currently used for the inspection
    is_active: Mapped[bool] = mapped_column(
    Boolean,
    default=True,
    nullable=False
    )

