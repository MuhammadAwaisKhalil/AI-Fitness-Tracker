"""Quick endpoint smoke-test."""
import json
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8000"

def post(path, body):
    data = json.dumps(body).encode()
    req = urllib.request.Request(f"{BASE}{path}", data=data, headers={"Content-Type": "application/json"})
    try:
        r = urllib.request.urlopen(req)
        return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode())

# Test 1: Duplicate signup (testuser already exists from prior run)
print("=== DUPLICATE SIGNUP (expect 409) ===")
status, body = post("/user/signup", {"username": "testuser", "password": "test123456"})
print(f"Status: {status}")
print(f"Body: {body}")
print()

# Test 2: Wrong password login
print("=== WRONG PASSWORD LOGIN (expect 401) ===")
status, body = post("/user/login", {"username": "testuser", "password": "wrongpassword"})
print(f"Status: {status}")
print(f"Body: {body}")
print()

# Test 3: Non-existent user login
print("=== NON-EXISTENT USER LOGIN (expect 401) ===")
status, body = post("/user/login", {"username": "ghostuser", "password": "test123456"})
print(f"Status: {status}")
print(f"Body: {body}")
print()

# Test 4: New user signup + login roundtrip
print("=== NEW USER SIGNUP (testuser2) ===")
status, body = post("/user/signup", {"username": "testuser2", "password": "securepass"})
print(f"Status: {status}")
print(f"Body: {body}")
print()

print("=== LOGIN testuser2 ===")
status, body = post("/user/login", {"username": "testuser2", "password": "securepass"})
print(f"Status: {status}")
print(f"Body: {body}")

