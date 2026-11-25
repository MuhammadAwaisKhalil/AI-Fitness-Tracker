"""
Authentication router — handles local signup/login and Google OAuth.

All three endpoints return a JWT bearer token on success.
Protected route /me demonstrates OAuth2PasswordBearer usage.
"""

import os

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth_utils import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)
from app.db.database import get_db
from app.db.models import User
from app.utils.schemas import (
    GoogleLoginRequest,
    TokenResponse,
    UserLogin,
    UserProfile,
    UserSignup,
)

router = APIRouter()

GOOGLE_CLIENT_ID = os.environ.get("GOOGLE_CLIENT_ID", "")


# ── POST /signup ─────────────────────────────────────────────────────────────
@router.post(
    "/signup",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new local account",
)
def signup(
    body: UserSignup,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """Create a local account with email + password."""
    existing = db.execute(
        select(User).where(User.email == body.email)
    ).scalar_one_or_none()

    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"An account with email '{body.email}' already exists.",
        )

    user = User(
        email=body.email,
        hashed_password=hash_password(body.password),
        auth_provider="local",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return TokenResponse(
        access_token=create_access_token(user.email),
        email=user.email,
        auth_provider="local",
    )


# ── POST /login ──────────────────────────────────────────────────────────────
@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Log in with email and password",
)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
) -> TokenResponse:
    """Authenticate with email (passed as 'username' in OAuth2 form) + password.
    
    Uses FastAPI's OAuth2PasswordRequestForm so the /login endpoint is
    compatible with the OpenAPI 'Authorize' button and standard OAuth2 flows.
    The 'username' field of the form carries the email address.
    """
    user = db.execute(
        select(User).where(User.email == form_data.username)
    ).scalar_one_or_none()

    if user is None or user.hashed_password is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return TokenResponse(
        access_token=create_access_token(user.email),
        email=user.email,
        auth_provider=user.auth_provider,
    )


# ── POST /google-login ───────────────────────────────────────────────────────
@router.post(
    "/google-login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Authenticate with a Google ID token",
)
def google_login(
    body: GoogleLoginRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """Validate a Google OAuth2 ID token and return a JWT.
    
    If the user doesn't exist, a new account is created automatically
    with auth_provider='google' and no password.
    """
    try:
        idinfo = google_id_token.verify_oauth2_token(
            body.id_token,
            google_requests.Request(),
            GOOGLE_CLIENT_ID,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google ID token: {e}",
        )

    google_email: str = idinfo.get("email", "")
    google_sub: str = idinfo.get("sub", "")

    if not google_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google token does not contain an email.",
        )

    # Check if user exists by email
    user = db.execute(
        select(User).where(User.email == google_email)
    ).scalar_one_or_none()

    if user is None:
        # Auto-register Google user
        user = User(
            email=google_email,
            hashed_password=None,
            auth_provider="google",
            google_id=google_sub,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    elif user.google_id is None:
        # Link Google ID to existing account
        user.google_id = google_sub
        if user.auth_provider == "local":
            user.auth_provider = "google"  # or keep "local" — policy choice
        db.commit()

    return TokenResponse(
        access_token=create_access_token(user.email),
        email=user.email,
        auth_provider=user.auth_provider,
    )


# ── GET /me (protected) ──────────────────────────────────────────────────────
@router.get(
    "/me",
    response_model=UserProfile,
    summary="Get current user profile (requires JWT)",
)
def get_me(current_user: User = Depends(get_current_user)) -> UserProfile:
    """Returns the authenticated user's profile."""
    return UserProfile(
        id=current_user.id,
        email=current_user.email,
        auth_provider=current_user.auth_provider,
    )
