"""Integration tests for /api/v1/auth endpoints."""

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Ensure env vars are set before importing
os.environ.setdefault("JWT_SECRET", "test-secret-key-for-testing-only-32chars!")
os.environ.setdefault("POSTGRESQL_HOST", "localhost")
os.environ.setdefault("POSTGRESQL_USER", "test")
os.environ.setdefault("POSTGRESQL_PASSWORD", "test")
os.environ.setdefault("POSTGRESQL_DBNAME", "test")
os.environ.setdefault("S3_ENDPOINT_URL", "https://s3.test")
os.environ.setdefault("S3_ACCESS_KEY_ID", "test")
os.environ.setdefault("S3_SECRET_ACCESS_KEY", "test")
os.environ.setdefault("S3_BUCKET", "test")
os.environ.setdefault("STORAGE_PUBLIC_URL", "https://cdn.test")
os.environ.setdefault("OPENAI_API_KEY", "sk-test")
os.environ.setdefault("LEONARDO_API_KEY", "leo-test")

import pytest


# ---------------------------------------------------------------------------
# Register
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
class TestRegister:
    async def test_register_success(self, client):
        resp = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "new@talekid.ai",
                "password": "secret123",
                "display_name": "New User",
            },
        )
        assert resp.status_code == 201
        data = resp.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"

    async def test_register_duplicate_email(self, client, test_user):
        resp = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test@talekid.ai",
                "password": "secret123",
                "display_name": "Dup",
            },
        )
        assert resp.status_code == 409

    async def test_register_invalid_email(self, client):
        resp = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "not-an-email",
                "password": "secret123",
                "display_name": "Bad Email",
            },
        )
        assert resp.status_code == 422

    async def test_register_short_password(self, client):
        resp = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "short@talekid.ai",
                "password": "abc",
                "display_name": "Short",
            },
        )
        assert resp.status_code == 422


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
class TestLogin:
    async def test_login_success(self, client, test_user):
        resp = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "test@talekid.ai",
                "password": "testpass123",
            },
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "access_token" in data
        assert "refresh_token" in data

    async def test_login_wrong_password(self, client, test_user):
        resp = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "test@talekid.ai",
                "password": "wrongpassword",
            },
        )
        assert resp.status_code == 401

    async def test_login_nonexistent_email(self, client):
        resp = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "nobody@talekid.ai",
                "password": "testpass123",
            },
        )
        assert resp.status_code == 401


# ---------------------------------------------------------------------------
# Token Refresh
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
class TestRefreshToken:
    async def test_refresh_success(self, client, test_user):
        # First login to get tokens
        login_resp = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "test@talekid.ai",
                "password": "testpass123",
            },
        )
        refresh_token = login_resp.json()["refresh_token"]

        # Use refresh token
        resp = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "access_token" in data
        assert "refresh_token" in data

    async def test_refresh_invalid_token(self, client):
        resp = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": "invalid.token.here"},
        )
        assert resp.status_code == 401

    async def test_refresh_access_token_rejected(self, client, test_user):
        """An access token should not be accepted as a refresh token."""
        from app.core.security import create_access_token

        access_token = create_access_token(test_user.id)
        resp = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": access_token},
        )
        assert resp.status_code == 401


# ---------------------------------------------------------------------------
# Me (current user)
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
class TestMe:
    async def test_me_authenticated(self, client, auth_headers):
        resp = await client.get("/api/v1/auth/me", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["email"] == "test@talekid.ai"
        assert data["display_name"] == "Test User"
        assert "id" in data
        assert "created_at" in data

    async def test_me_no_auth(self, client):
        resp = await client.get("/api/v1/auth/me")
        assert resp.status_code == 403  # HTTPBearer returns 403 when no creds

    async def test_me_invalid_token(self, client):
        resp = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert resp.status_code == 401
