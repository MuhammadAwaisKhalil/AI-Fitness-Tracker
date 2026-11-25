"""
Mock JWT utility.

Generates a clearly fake, human-readable token so the JWT architecture is
visible end-to-end before a real signing library (python-jose / PyJWT) is
integrated. When the real DB and secret key are added:

1. pip install python-jose[cryptography]
2. Replace _create_mock_token() with jwt.encode(payload, SECRET_KEY, algorithm="HS256")
3. Add a verify_token() helper and protect routes with an OAuth2 dependency.
"""

import base64
import json
import time


_MOCK_HEADER = base64.urlsafe_b64encode(
    json.dumps({"alg": "MOCK", "typ": "JWT"}).encode()
).decode().rstrip("=")


def create_access_token(username: str) -> str:
    """Return a mock JWT-shaped string (header.payload.MOCK_SIG)."""
    payload = {
        "sub": username,
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,   # 1-hour expiry (not enforced yet)
    }
    encoded_payload = base64.urlsafe_b64encode(
        json.dumps(payload).encode()
    ).decode().rstrip("=")

    return f"{_MOCK_HEADER}.{encoded_payload}.MOCK_SIGNATURE"

