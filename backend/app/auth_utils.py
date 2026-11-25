"""
Production-grade authentication utilities.

- Password hashing: bcrypt with optional pepper from .env
- JWT tokens: HS256 via PyJWT with configurable expiry
- OAuth2 scheme: FastAPI dependency for protected routes
"""

import os
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.db.database import get_db

load_dotenv()

# ── Configuration from .env ──────────────────────────────────────────────────
JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "CHANGE-ME-IN-PRODUCTION")
JWT_ALGORITHM = os.environ.get("JWT_ALGORITHM", "HS256")
JWT_EXPIRE_MINUTES = int(os.environ.get("JWT_EXPIRE_MINUTES", "60"))
PASSWORD_PEPPER = os.environ.get("PASSWORD_PEPPER", "")


# ── OAuth2 Scheme ────────────────────────────────────────────────────────────
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/user/login")


# ── Password Hashing ────────────────────────────────────────────────────────
def hash_password(plain: str) -> str:
    """Hash a plaintext password with bcrypt + optional pepper.
    
    The pepper is a server-side secret prepended to the password before
    hashing, adding a layer of defense even if the DB is compromised.
    UTF-8 encoding is applied before hashing.
    """
    peppered = f"{PASSWORD_PEPPER}{plain}".encode("utf-8")
    return bcrypt.hashpw(peppered, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    """Verify a plaintext password against a bcrypt hash (with pepper)."""
    peppered = f"{PASSWORD_PEPPER}{plain}".encode("utf-8")
    return bcrypt.checkpw(peppered, hashed.encode("utf-8"))


# ── JWT Tokens ───────────────────────────────────────────────────────────────
def create_access_token(subject: str, extra_claims: dict | None = None) -> str:
    """Create a signed JWT with subject (user email) and expiry."""
    now = datetime.now(timezone.utc)
    payload = {
        "sub": subject,
        "iat": now,
        "exp": now + timedelta(minutes=JWT_EXPIRE_MINUTES),
        "type": "access",
    }
    if extra_claims:
        payload.update(extra_claims)
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> dict:
    """Decode and validate a JWT. Raises HTTPException on failure."""
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token.",
            headers={"WWW-Authenticate": "Bearer"},
        )


# ── FastAPI Dependencies ─────────────────────────────────────────────────────
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    """Dependency that extracts the current user from the JWT bearer token."""
    from app.db.models import User  # Deferred import to avoid circular
    from sqlalchemy import select

    payload = decode_access_token(token)
    email = payload.get("sub")
    if email is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject.",
        )
    user = db.execute(select(User).where(User.email == email)).scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found.",
        )
    return user
