
from __future__ import annotations
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from ..models import InspectionImage


def evaluate_image_authenticity(
    db: Session,
    inspection_id: int,
    image_sha256: str,
    quality_result: Dict[str, Any],
    current_angle: Optional[str] = None
) -> Dict[str, Any]:
    

    # 1. Check duplicate image

    duplicate = (
        db.query(InspectionImage)
        .filter(
            InspectionImage.inspection_id == inspection_id,
            InspectionImage.sha256 == image_sha256,
            InspectionImage.is_active.is_(True)
        )
        .first()
    )

    if duplicate:
        # If it is the same angle, it's a replacement/retry which is allowed.
        # Only reject if the same image is reused across different angles.
        if current_angle and duplicate.angle.upper() != current_angle.upper():
            return {
                "authenticity_status": "REJECTED_DUPLICATE",
                "reason": (
                    "Duplicate image detected: the same image cannot be used for different angles."
                )
            }

    # 2. Read quality decision

    image_quality = quality_result.get(
        "image_quality",
        "REVIEW"
    )

    # 3. Quality failed

    if image_quality == "RETAKE":
        return {
            "authenticity_status": "RETAKE_REQUIRED",
            "reason": (
                "Image quality is insufficient. "
                "Please capture the package image again."
            )
        }

    # 4. Quality needs review

    if image_quality == "REVIEW":
        return {
            "authenticity_status": "WARN",
            "reason": (
                "Image quality requires inspector review "
                "before relying on the extracted evidence."
            )
        }


    # 5. Quality passed
    return {
        "authenticity_status": "VERIFIED",
        "reason": (
            "Image passed the duplicate/integrity check "
            "and image-quality gate."
        )
    }