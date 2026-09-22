#Audit Logging Service for PARAKH.

#Provides centralized function to record system and inspector audit actions.

from __future__ import annotations

from typing import Optional
from sqlalchemy.orm import Session
from ..models import AuditLog

def log_action(
    db: Session,
    action: str,
    inspection_id: Optional[int] = None,
    inspector_id: Optional[int] = None,
    details: Optional[str] = None,
    ip_address: Optional[str] = None
) -> AuditLog:
    entry = AuditLog(
        action=action,
        inspection_id=inspection_id,
        inspector_id=inspector_id,
        details=details,
        ip_address=ip_address
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry
