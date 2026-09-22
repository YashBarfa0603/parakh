from __future__ import annotations

import bcrypt
import os

from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from jose import jwt, JWTError

#admin password hashing 
def hash_admin_password(password: str) -> str:
    password_bytes = password.encode("utf-8")

    #bcrypt support max of 72 bytes
    if len(password_bytes) > 72:
        raise ValueError("Password is Too Long")

    hashed = bcrypt.hashpw(
        password_bytes,
        bcrypt.gensalt()
    )
    return hashed.decode("utf-8")

#admin passowrd verifictaion 
def verify_admin_password(
        plain_password: str,
        hashed_password: str
) -> bool:
    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed_password.encode("utf-8")
    )

#jwt configuration
load_dotenv()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
EXPIRE_MINUTES = int(
    os.getenv("JWT_EXPIRE_MINUTES", "60")
)

#create admin access token
def create_admin_access_token(
        admin_id: int,
        role: str
) -> str:

    expire = datetime.now(timezone.utc) + timedelta(
        minutes = EXPIRE_MINUTES
    )

    payload = {
        # Admin database ID
        "sub": str(admin_id),

        # Admin role for authorization
        "role": role,

        # Token expiration time
        "exp": expire,
    }

    return jwt.encode(
        payload,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

#decode admin access token
def decode_admin_access_token(token: str) -> dict:
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms = [ALGORITHM]
        )
        return payload
    except JWTError:
        raise ValueError("Invalid or Expired Admin Token")