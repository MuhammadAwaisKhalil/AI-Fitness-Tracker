from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import user


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup/shutdown lifecycle."""
    print("🚀 AI Fitness Coach API starting up...")
    print("📦 Database: Neon Lakebase Postgres (psycopg2 + NullPool)")
    yield
    print("🛑 AI Fitness Coach API shutting down...")


app = FastAPI(
    title="AI Fitness Coach API",
    description=(
        "Central backend for the AI Fitness Coach app. "
        "Handles authentication (local + Google OAuth), BMR/Nutrition calculations, "
        "workout plan generation, and LLM chat integration.\n\n"
        "**Architectural Boundary**: the Flutter frontend handles only "
        "UI, local camera/CV processing, and SQLite caching. "
        "All heavy logic lives here.\n\n"
        "**Database**: Neon Lakebase Postgres (psycopg2 + SQLAlchemy, NullPool).\n\n"
        "**Auth**: Local (email+password+bcrypt) and Google OAuth2, JWT (HS256)."
    ),
    version="0.3.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Tighten before going to production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(user.router, prefix="/user", tags=["Authentication"])


@app.get("/", tags=["Health"])
def root():
    return {
        "status": "ok",
        "message": "AI Fitness Coach API is running.",
        "db": "Neon Lakebase Postgres",
        "auth": "local + google",
        "version": "0.3.0",
    }
