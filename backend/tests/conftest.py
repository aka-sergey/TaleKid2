"""
Backend test fixtures.

Uses SQLite in-memory for fast isolated testing.
Patches Settings so no real env vars are needed.
"""

import os
import sys
import uuid as _uuid
from contextlib import asynccontextmanager
from pathlib import Path

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import event as sa_event
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import StaticPool

# ---- path setup ----
ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "backend"))

# ---- mock settings BEFORE importing app modules ----
_MOCK_ENV = {
    "POSTGRESQL_HOST": "localhost",
    "POSTGRESQL_PORT": "5432",
    "POSTGRESQL_USER": "test",
    "POSTGRESQL_PASSWORD": "test",
    "POSTGRESQL_DBNAME": "test",
    "POSTGRESQL_SSLMODE": "disable",
    "S3_ENDPOINT_URL": "https://s3.test",
    "S3_ACCESS_KEY_ID": "test",
    "S3_SECRET_ACCESS_KEY": "test",
    "S3_BUCKET": "test-bucket",
    "STORAGE_PUBLIC_URL": "https://cdn.test",
    "JWT_SECRET": "test-secret-key-for-testing-only-32chars!",
    "JWT_ALGORITHM": "HS256",
    "OPENAI_API_KEY": "sk-test",
    "LEONARDO_API_KEY": "leo-test",
    "REDIS_URL": "redis://localhost:6379",
}

for k, v in _MOCK_ENV.items():
    os.environ.setdefault(k, v)

# Clear the lru_cache so Settings re-reads from env
from app.config import get_settings

get_settings.cache_clear()

# Import ALL shared models so Base.metadata knows about every table
from shared.models import (  # noqa: F401
    Base,
    BaseTale,
    BaseTaleCharacter,
    Character,
    CharacterPhoto,
    DeviceToken,
    EducationalContent,
    GenerationJob,
    Genre,
    Page,
    Story,
    StoryCharacter,
    User,
    World,
)
from app.core.security import create_access_token, hash_password

# ---- Teach SQLite how to render PostgreSQL-specific types ----
from sqlalchemy.dialects.sqlite import base as _sqlite_base
from sqlalchemy.dialects.postgresql import UUID as _PG_UUID

_sqlite_base.SQLiteTypeCompiler.visit_JSONB = _sqlite_base.SQLiteTypeCompiler.visit_JSON

# Fix UUID server_defaults for SQLite: gen_random_uuid() must be wrapped
# in parentheses to be a valid DEFAULT expression in SQLite DDL.
# We remove the server_default and provide a Python-level default via event.
_original_server_defaults: dict = {}

for _table in Base.metadata.tables.values():
    for _col in _table.columns:
        sd = _col.server_default
        if sd is not None and hasattr(sd, "arg") and hasattr(sd.arg, "text"):
            if "gen_random_uuid" in str(sd.arg.text):
                _original_server_defaults[(_table.name, _col.name)] = sd
                _col.server_default = None


# Auto-generate UUIDs at Python level for UUID primary key columns
@sa_event.listens_for(Base, "init", propagate=True)
def _auto_set_uuid(target, args, kwargs):
    for col in target.__class__.__table__.primary_key.columns:
        if isinstance(col.type, _PG_UUID):
            attr = col.key
            if getattr(target, attr, None) is None:
                setattr(target, attr, _uuid.uuid4())


# ---- SQLite async engine for tests ----
TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(
    TEST_DB_URL,
    echo=False,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)


TestSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest_asyncio.fixture
async def db_session():
    """Create all tables and yield a clean session per test."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with TestSessionLocal() as session:
        yield session

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    """Create and return a test user."""
    user = User(
        id=_uuid.uuid4(),
        email="test@talekid.ai",
        password_hash=hash_password("testpass123"),
        display_name="Test User",
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
def auth_headers(test_user: User) -> dict:
    """Return Authorization headers with a valid JWT."""
    token = create_access_token(test_user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def client(db_session: AsyncSession):
    """
    Async HTTP client using the FastAPI app with DB override.
    Disables lifespan to avoid connecting to real PostgreSQL.
    """
    from app.main import app
    from app.dependencies import get_db

    # Replace lifespan with a noop (tables are created by db_session fixture)
    @asynccontextmanager
    async def _noop_lifespan(_app):
        yield

    original_lifespan = app.router.lifespan_context
    app.router.lifespan_context = _noop_lifespan

    async def _override_get_db():
        try:
            yield db_session
            await db_session.commit()
        except Exception:
            await db_session.rollback()
            raise

    app.dependency_overrides[get_db] = _override_get_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()
    app.router.lifespan_context = original_lifespan
