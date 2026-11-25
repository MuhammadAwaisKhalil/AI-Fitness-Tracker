"""
SQLAlchemy ORM models for Neon Lakebase Postgres.
"""

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class User(Base):
    """Registered users — stored in Neon Lakebase Postgres.
    
    Supports two auth providers:
      - 'local'  → email + bcrypt-hashed password
      - 'google' → email + google_id (hashed_password is NULL)
    """

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    # Kept for backward compatibility — old username-based rows still have this.
    username: Mapped[Optional[str]] = mapped_column(
        String(50), unique=True, nullable=True, index=True
    )
    hashed_password: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True
    )
    auth_provider: Mapped[str] = mapped_column(
        String(20), nullable=False, server_default="local"
    )
    google_id: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True, unique=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r} provider={self.auth_provider!r}>"
