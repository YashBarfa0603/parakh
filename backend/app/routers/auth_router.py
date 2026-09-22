#Router = API
#APIRouter lets us keep authentication endpoints separate from main.py

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Inspector
from ..schemas.auth_schema import (SignupRequest,LoginRequest, AuthResponse,InspectorResponse )
from ..services.auth_service import (hash_password,verify_password, create_access_token)
from ..dependencies.auth_dependency import (get_current_inspector, get_approved_inspector)

router = APIRouter(
    prefix = "/api/auth",
    tags = ["Authentication"]
)

@router.post(
    "/signup",
    response_model=AuthResponse
)
def signup(
    data: SignupRequest,
    db: Session = Depends(get_db)
):
    #check duplicated email

    existing_emails = db.query(Inspector).filter(
        Inspector.email == data.email
    ).first()

    if existing_emails:
        raise HTTPException(
            status_code = 400,
            detail = "Email already registered"
        )

    #check duplicated inspector id

    existing_inspector = db.query(Inspector).filter(
        Inspector.inspector_id == data.inspector_id
    ).first()

    if existing_inspector:
        raise HTTPException(
            status_code = 400,
            detail = "Inspector ID already registered"
        )

    #create inspector
    inspector = Inspector(
        name = data.name,
        email = data.email,
        phone = data.phone,
        inspector_id = data.inspector_id,
        department = data.department,
        designation = data.designation,
        office = data.office,
        state = data.state,
        district = data.district,
        city = data.city,
        password_hash = hash_password(data.password),
        account_status = "APPROVED"
    )

    db.add(inspector)
    db.commit()
    db.refresh(inspector)

    #create jwt token

    access_token = create_access_token(inspector.id)

    #return auth response
    return{
        "access_token": access_token,
        "token_type":"bearer",
        "inspector":inspector    

    }

@router.post(
    "/login",
    response_model = AuthResponse
)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db)
):
    #find inspector by email
    inspector = db.query(Inspector).filter(
        Inspector.email == data.email
    ).first()

    if not inspector:
        raise HTTPException(
            status_code= 401,
            detail= "Invalid email or password"
        )

    #verify passwordd
    password_valid = verify_password(
        data.password,
        inspector.password_hash
    )
    if not password_valid:
        raise HTTPException(
            status_code= 401,
            detail = "Invalid email or password"
        )

    #create jwt token
    access_token = create_access_token(
        inspector.id
    )

    #return auth response
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "inspector": inspector
    }

#get current insp
@router.get(
    "/me",
    response_model = InspectorResponse
)
def get_me(
    current_inspector: Inspector = Depends(get_current_inspector)
):
    return current_inspector

#approved insp test endpoint
@router.get("/approved-tes")
def approved_tes(
    current_inspector: Inspector = Depends(get_approved_inspector)
):
    return{
        "message": "Inspector is Approved",
        "inspector_id": current_inspector.inspector_id
    }

#inspector access test
@router.get("/inspector-access-test")
def inspection_access_test(
    current_inspector: Inspector = Depends(get_approved_inspector)
):
    return{
        "message": "Inspector is allowed to perform inspection",
        "inspector_id": current_inspector.inspector_id,
        "account_status": current_inspector.account_status
    }
