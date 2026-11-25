"""
Password hashing with bcrypt directly (no passlib wrapper).

passlib is unmaintained and breaks with bcrypt >= 4.1 due to removed
`__about__` attributes and a wrap-bug detection that feeds 73-byte
secrets.  Using bcrypt directly avoids all of that.
"""

import bcrypt


def hash_password(plain: str) -> str:
    """Return a bcrypt hash of *plain*."""
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    """Return True if *plain* matches the stored *hashed* value."""
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
