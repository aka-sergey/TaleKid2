"""Unit tests for JWT and password security utilities."""

import os
import sys
from pathlib import Path
from uuid import uuid4

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

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)


class TestPasswordHashing:
    def test_hash_returns_string(self):
        hashed = hash_password("password123")
        assert isinstance(hashed, str)
        assert hashed != "password123"

    def test_hash_is_unique(self):
        h1 = hash_password("password123")
        h2 = hash_password("password123")
        assert h1 != h2  # bcrypt uses random salt

    def test_verify_correct_password(self):
        hashed = hash_password("mypassword")
        assert verify_password("mypassword", hashed) is True

    def test_verify_wrong_password(self):
        hashed = hash_password("mypassword")
        assert verify_password("wrongpassword", hashed) is False


class TestJWT:
    def test_access_token_creation(self):
        user_id = uuid4()
        token = create_access_token(user_id)
        assert isinstance(token, str)
        assert len(token) > 20

    def test_refresh_token_creation(self):
        user_id = uuid4()
        token = create_refresh_token(user_id)
        assert isinstance(token, str)
        assert len(token) > 20

    def test_decode_access_token(self):
        user_id = uuid4()
        token = create_access_token(user_id)
        payload = decode_token(token)
        assert payload["sub"] == str(user_id)
        assert payload["type"] == "access"

    def test_decode_refresh_token(self):
        user_id = uuid4()
        token = create_refresh_token(user_id)
        payload = decode_token(token)
        assert payload["sub"] == str(user_id)
        assert payload["type"] == "refresh"

    def test_tokens_are_different(self):
        user_id = uuid4()
        access = create_access_token(user_id)
        refresh = create_refresh_token(user_id)
        assert access != refresh

    def test_decode_invalid_token_raises(self):
        from jose import JWTError

        try:
            decode_token("invalid.token.here")
            assert False, "Should have raised"
        except JWTError:
            pass

    def test_extra_claims(self):
        user_id = uuid4()
        token = create_access_token(user_id, extra_claims={"role": "admin"})
        payload = decode_token(token)
        assert payload["role"] == "admin"
