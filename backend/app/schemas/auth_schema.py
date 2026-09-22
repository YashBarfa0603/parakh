#This schema will validate the incoming signup request before we touch PostgreSQL.

from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class SignupRequest(BaseModel):
    name: str
    email: EmailStr 
    phone: str

    inspector_id: str

    department: str
    designation: str
    office: str

    state: str
    district: str
    city: str

    password: str = Field(
        min_length = 8,
        max_length = 72
    )

# why we are creating this But Flutter needs the JWT and inspector information to automatically log the user in.
#inspector response
#we're not returning password_hash to Flutter.
class InspectorResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    phone: str
    inspector_id: str

    department: str
    designation: str
    office: str

    state: str
    district: str
    city: str

    account_status: str
    rejection_reason: Optional[str] = None

#auth response

class AuthResponse(BaseModel):
    access_token: str
    token_type: str
    inspector: InspectorResponse

#login request 
class LoginRequest(BaseModel):
    email: EmailStr
    password: str
