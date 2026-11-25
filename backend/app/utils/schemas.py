"""
Pydantic schemas for request/response validation.
Uses EmailStr for strict email validation (requires pydantic[email]).
"""

import re
from pydantic import BaseModel, EmailStr, Field, field_validator


class UserSignup(BaseModel):
    """Request body for POST /user/signup (local account)."""

    email: EmailStr = Field(
        ...,
        examples=["user@example.com"],
        description="Valid email address.",
    )
    password: str = Field(
        ...,
        min_length=8,
        max_length=128,
        examples=["Str0ng!Pass"],
        description="Password (min 8 chars, must include uppercase, lowercase, digit, and special char).",
    )

    @field_validator("password")
    @classmethod
    def password_complexity(cls, v: str) -> str:
        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain at least one uppercase letter.")
        if not re.search(r"[a-z]", v):
            raise ValueError("Password must contain at least one lowercase letter.")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain at least one digit.")
        if not re.search(r"[!@#$%^&*()_+\-=\[\]{};':\"\\|,.<>\/?]", v):
            raise ValueError("Password must contain at least one special character.")
        return v


class UserLogin(BaseModel):
    """Request body for POST /user/login (local account) — used by OAuth2 form."""

    email: EmailStr = Field(..., examples=["user@example.com"])
    password: str = Field(..., examples=["Str0ng!Pass"])


class GoogleLoginRequest(BaseModel):
    """Request body for POST /user/google-login."""

    id_token: str = Field(
        ...,
        description="Google OAuth2 ID token obtained from the client SDK.",
    )


class TokenResponse(BaseModel):
    """Successful auth response containing a JWT bearer token."""

    access_token: str
    token_type: str = "bearer"
    email: str
    auth_provider: str = "local"


class UserProfile(BaseModel):
    """Public user profile (for protected endpoints)."""

    id: int
    email: str
    auth_provider: str

    class Config:
        from_attributes = True
