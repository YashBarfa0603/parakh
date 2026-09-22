from __future__ import annotations

from pydantic import BaseModel, EmailStr

#admin login request 
class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str

#admin response
class AdminResponse(BaseModel):
    id: int 
    name: str
    email: EmailStr
    role: str
    is_active: bool

#admin auth response
class AdminAuthResponse(BaseModel):
    access_token: str
    token_type: str
    admin: AdminResponse