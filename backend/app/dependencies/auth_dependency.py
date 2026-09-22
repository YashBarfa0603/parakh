from __future__ import annotations

from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Inspector
from ..services.auth_service import decode_access_token

# http bearer security 
security = HTTPBearer()

#get curent inspector
def get_current_inspector(
        credentials: HTTPAuthorizationCredentials = Depends(security),
        db: Session = Depends(get_db)
):
    token = credentials.credentials

    #decode and verify JWT token
    try:
        payload = decode_access_token(token)
    except ValueError:
        raise HTTPException(
            status_code = 401,
            detail = "Invalid or expired token"
        )

    #get inspector id from jwt
    raw_sub = payload.get("sub")
    if raw_sub is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid Token"
        )

    try:
        inspector_id = int(raw_sub)
    except (TypeError, ValueError):
        raise HTTPException(
            status_code=401,
            detail="Invalid Token"
        )

    #find insp in db
    inspector = db.query(Inspector).filter(
        Inspector.id == inspector_id
    ).first()

    #if insp not found
    if not inspector:
        raise HTTPException(
            status_code = 401,
            detail = "Inspector not Found"
        )

    #return authenticated inp
    return inspector

#get approved inspector

def get_approved_inspector(
        current_inspector: Inspector = Depends(get_current_inspector)
):
    #check status of insp account
   if current_inspector.account_status != "APPROVED":

        if current_inspector.account_status == "PENDING":
            detail = "Inspector account is pending approval"

        elif current_inspector.account_status == "REJECTED":
            detail = "Inspector account has been rejected"

        else:
            detail = "Inspector account is not approved"

        raise HTTPException(
            status_code = 403,
            detail = detail
        )
   #return approved inspector
   return current_inspector