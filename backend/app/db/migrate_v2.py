"""
Database migration v2: Add email, auth_provider, google_id columns to users table.

Safely ALTERs the existing table without dropping it.
Idempotent — safe to run multiple times.

Usage:
    cd backend
    python -m app.db.migrate_v2
"""

import os
import sys

from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

DATABASE_URL = os.environ.get("DATABASE_URL_UNPOOLED")
if not DATABASE_URL:
    print("❌ DATABASE_URL_UNPOOLED not set in .env")
    sys.exit(1)

# Force psycopg2 driver (same fix as database.py)
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg2://", 1)


def run_migration():
    """Run all migration steps."""
    engine = create_engine(DATABASE_URL, isolation_level="AUTOCOMMIT")

    with engine.connect() as conn:
        # Step 1: Add 'email' column (nullable initially)
        print("Step 1: Adding 'email' column (nullable)...")
        try:
            conn.execute(text(
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);"
            ))
            print("  ✅ 'email' column added (or already exists).")
        except Exception as e:
            print(f"  ⚠️ 'email' column: {e}")

        # Step 2: Add 'auth_provider' column
        print("Step 2: Adding 'auth_provider' column...")
        try:
            conn.execute(text(
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) NOT NULL DEFAULT 'local';"
            ))
            print("  ✅ 'auth_provider' column added (or already exists).")
        except Exception as e:
            print(f"  ⚠️ 'auth_provider' column: {e}")

        # Step 3: Add 'google_id' column
        print("Step 3: Adding 'google_id' column...")
        try:
            conn.execute(text(
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255);"
            ))
            print("  ✅ 'google_id' column added (or already exists).")
        except Exception as e:
            print(f"  ⚠️ 'google_id' column: {e}")

        # Step 4: Make 'hashed_password' nullable
        print("Step 4: Making 'hashed_password' nullable...")
        try:
            conn.execute(text(
                "ALTER TABLE users ALTER COLUMN hashed_password DROP NOT NULL;"
            ))
            print("  ✅ 'hashed_password' is now nullable.")
        except Exception as e:
            print(f"  ⚠️ 'hashed_password': {e}")

        # Step 5: Backfill email from username for existing rows
        print("Step 5: Backfilling email from username for existing rows...")
        try:
            result = conn.execute(text(
                "UPDATE users SET email = username WHERE email IS NULL AND username IS NOT NULL;"
            ))
            print(f"  ✅ Backfilled {result.rowcount} row(s).")
        except Exception as e:
            print(f"  ⚠️ Backfill: {e}")

        # Step 6: Make 'email' NOT NULL
        print("Step 6: Making 'email' NOT NULL...")
        try:
            conn.execute(text(
                "ALTER TABLE users ALTER COLUMN email SET NOT NULL;"
            ))
            print("  ✅ 'email' is now NOT NULL.")
        except Exception as e:
            print(f"  ⚠️ 'email' NOT NULL: {e}")

        # Step 7: Add UNIQUE constraint on email
        print("Step 7: Adding UNIQUE constraint on email...")
        try:
            conn.execute(text(
                "ALTER TABLE users ADD CONSTRAINT uq_users_email UNIQUE (email);"
            ))
            print("  ✅ UNIQUE constraint on email added.")
        except Exception as e:
            if "already exists" in str(e):
                print("  ✅ UNIQUE constraint on email already exists.")
            else:
                print(f"  ⚠️ Email UNIQUE constraint: {e}")

        # Step 8: Add partial UNIQUE constraint on google_id
        print("Step 8: Adding UNIQUE constraint on google_id (partial)...")
        try:
            conn.execute(text(
                "CREATE UNIQUE INDEX IF NOT EXISTS uq_users_google_id ON users (google_id) WHERE google_id IS NOT NULL;"
            ))
            print("  ✅ UNIQUE index on google_id added (or already exists).")
        except Exception as e:
            print(f"  ⚠️ google_id UNIQUE index: {e}")

        # Step 9: Add index on email if not exists
        print("Step 9: Adding index on email...")
        try:
            conn.execute(text(
                "CREATE INDEX IF NOT EXISTS ix_users_email ON users (email);"
            ))
            print("  ✅ Index on email added (or already exists).")
        except Exception as e:
            print(f"  ⚠️ Email index: {e}")

    engine.dispose()
    print("\n🎉 Migration v2 complete!")


if __name__ == "__main__":
    run_migration()
