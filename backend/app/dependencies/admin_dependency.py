from __future__ import annotations

from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Admin
from ..services.admin_auth_service import decode_admin_access_token

#http bearer security 
security = HTTPBearer()

#get current admin
def get_current_admin(
        credentials: HTTPAuthorizationCredentials = Depends(security),
        db: Session = Depends(get_db)
):
    #extract jwt token from auth header
    token = credentials.credentials

    #deocde and verify admin jwt
    try:
        payload = decode_admin_access_token(token)

    except ValueError:
        raise HTTPException(
            status_code = 401,
            detail = "Invalid or Expired Admin token"
        )
    #get admin id from jwt payload
    raw_sub = payload.get("sub")
    if raw_sub is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid Admin token"
        )

    try:
        admin_id = int(raw_sub)
    except (TypeError, ValueError):
        raise HTTPException(
            status_code=401,
            detail="Invalid Admin token"
        )

    #find admin in db
    admin = db.query(Admin).filter(
        Admin.id == admin_id
    ).first()

    #check if exists 
    if not admin:
        raise HTTPException(
            status_code = 401,
            detail = "Admin Not Found"
        )
    # if admin account is active 
    if not admin.is_active:
        raise HTTPException(
            status_code = 403,
            detail = "Admin Account is Inactive"
        )
    return admin

#get admin
def get_admin(
        current_admin: Admin = Depends(get_current_admin)
):
    return current_admin

#fianl RBAC layer
#get super admin

def get_super_admin(
        current_admin: Admin = Depends(get_admin)
):
    #checks admin role
    if current_admin.role != "SUPER_ADMIN":
        raise HTTPException(
            status_code = 403,
            detail = "Super Admin accesss required"
        )
    #return authenticated SA
    return current_admin