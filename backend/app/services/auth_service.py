from __future__ import annotations

import bcrypt
import os
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from jose import jwt, JWTError

load_dotenv()

#jwt configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
EXPIRE_MINUTES = int(
    os.getenv("JWT_EXPIRE_MINUTES", "1440")
)

#access token
def create_access_token(inspector_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes = EXPIRE_MINUTES
    )

    payload = {
        #sub means subject :- it tells, This token belongs to inspector ID 1
        "sub": str(inspector_id),
        "exp": expire,
    }

    return jwt.encode(
        payload,
        SECRET_KEY,
        algorithm = ALGORITHM
    )

# decode access token

def decode_access_token(token: str)-> dict:
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms = [ALGORITHM]
        )
        return payload
    except JWTError:
        raise ValueError("Invalid or expired token")


#password hashing
def hash_password(password: str) -> str:
    password_bytes = password.encode("utf-8")
    if len(password_bytes) > 72:
        raise ValueError("Password is Too Long")
    hashed = bcrypt.hashpw(
        password_bytes,
        bcrypt.gensalt()
    )

    return hashed.decode("utf-8")

#password verify
def verify_password(
    plain_password: str,
    hashed_password: str,
) -> bool:
    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed_password.encode("utf-8")
    )