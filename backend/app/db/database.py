"""
Synchronous SQLAlchemy engine wired to Neon Lakebase Postgres via psycopg2.

Connection strategy:
  DATABASE_URL_POOLED   → Neon's PgBouncer pooler — used for all app queries.
  DATABASE_URL_UNPOOLED → direct Postgres endpoint — for schema migrations.

CRITICAL: NullPool is mandatory when connecting through Neon's PgBouncer.
  Neon already pools connections server-side; SQLAlchemy's built-in pool on
  top of that causes "connection idle too long" and double-pooling timeouts.
  NullPool opens a fresh connection per request and closes it immediately
  after, letting PgBouncer manage the actual pooling.
"""

import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

# Load backend/.env
load_dotenv()

DATABASE_URL_POOLED = os.environ.get("DATABASE_URL_POOLED", "")
if not DATABASE_URL_POOLED:
    raise RuntimeError(
        "DATABASE_URL_POOLED is not set. "
        "Add it to backend/.env — see backend/.env for the expected format."
    )

# Force SQLAlchemy to use the psycopg2 driver (installed as psycopg2-binary).
# SQLAlchemy 2.x defaults to the psycopg (v3) dialect if the URL starts with
# "postgresql://" — we must specify "postgresql+psycopg2://" explicitly.
if DATABASE_URL_POOLED.startswith("postgresql://"):
    DATABASE_URL_POOLED = DATABASE_URL_POOLED.replace(
        "postgresql://", "postgresql+psycopg2://", 1
    )

# ── Engine ────────────────────────────────────────────────────────────────────
# NullPool: prevents double-pooling with Neon's PgBouncer
engine = create_engine(
    DATABASE_URL_POOLED,
    poolclass=NullPool,
    echo=False,
)

# ── Session factory ───────────────────────────────────────────────────────────
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

# ── Declarative base shared by all ORM models ────────────────────────────────
Base = declarative_base()


# ── FastAPI dependency ────────────────────────────────────────────────────────
def get_db():
    """Yield a synchronous session; the caller commits or rolls back."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
