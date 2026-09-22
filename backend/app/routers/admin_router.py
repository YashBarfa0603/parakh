# Router = API
# APIRouter lets us keep Admin endpoints separate from main.py

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Admin, Inspector

from ..schemas.admin_schema import (
    AdminLoginRequest,
    AdminResponse,
    AdminAuthResponse
)

from ..schemas.auth_schema import InspectorResponse

from ..services.admin_auth_service import (
    verify_admin_password,
    create_admin_access_token
)

from ..dependencies.admin_dependency import (
    get_current_admin,
)

router = APIRouter(
    prefix = "/api/admin",
    tags = ["Admin"]
)
@router.post(
    "/login",
    response_model=AdminAuthResponse
)
def login(
    data: AdminLoginRequest,
    db: Session = Depends(get_db)
):
    # Find admin by email
    admin = db.query(Admin).filter(
        Admin.email == data.email
    ).first()

    # Admin not found
    if not admin:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    # Check whether admin account is active
    if not admin.is_active:
        raise HTTPException(
            status_code=403,
            detail="Admin account is inactive"
        )

    # Verify password
    password_valid = verify_admin_password(
        data.password,
        admin.password_hash
    )

    if not password_valid:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    # Create Admin JWT
    access_token = create_admin_access_token(
        admin.id,
        admin.role
    )

    # Return authentication response
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "admin": admin
    }

#get current admin
@router.get(
    "/me",
    response_model= AdminResponse
)
def get_me(
    current_admin: Admin = Depends(get_current_admin)
):
    return current_admin

#get all inspector 
@router.get(
    "/inspector",
    response_model = list[InspectorResponse]
)
def get_inspectors(
    current_admin: Admin = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    #get all insp from db 
    inspector = db.query(Inspector).all()

    return inspector

#approved inspector 
@router.patch(
    "/inspectors/{inspector_id}/approve",
    response_model = InspectorResponse
)
def approve_inspector(
    inspector_id: int,
    current_admin: Admin = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    # Find inspector
    inspector = db.query(Inspector).filter(
        Inspector.id == inspector_id
    ).first()

    # Inspector not found
    if not inspector:
        raise HTTPException(
            status_code = 404,
            detail = "Inspector not found"
        )

    # Check current status
    if inspector.account_status == "APPROVED":
        raise HTTPException(
            status_code = 400,
            detail = "Inspector is already approved"
        )

    # Approve inspector
    inspector.account_status = "APPROVED"

    db.commit()
    db.refresh(inspector)

    return inspector

#reject inspector
@router.patch(
    "/inspectors/{inspector_id}/reject",
    response_model = InspectorResponse
)
def reject_inspector(
    inspector_id: int,
    rejection_reason: str,
    current_admin: Admin = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    #find inspector
    inspector = db.query(Inspector).filter(
        Inspector.id == inspector_id
    ).first()

    #find inspector 
    inspector = db.query(Inspector).filter(
        Inspector.id == inspector_id
    ).first()

    #inspector not found 
    if not inspector:
        raise HTTPException(
            status_code=404,
            detail="Inspector not found"
        )

    # Check current status
    if inspector.account_status == "REJECTED":
        raise HTTPException(
            status_code=400,
            detail="Inspector is already rejected"
        )

    # Reject inspector
    inspector.account_status = "REJECTED"
    inspector.rejection_reason = rejection_reason

    db.commit()
    db.refresh(inspector)

    return inspector