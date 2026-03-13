"""Integration tests for /api/v1/catalog endpoints."""

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

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
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from shared.models.genre import Genre
from shared.models.world import World
from shared.models.base_tale import BaseTale, BaseTaleCharacter


# ---------------------------------------------------------------------------
# Test-specific fixtures
# ---------------------------------------------------------------------------

@pytest_asyncio.fixture
async def genres(db_session: AsyncSession) -> list[Genre]:
    """Create test genres."""
    items = [
        Genre(
            slug="adventure",
            name_ru="Приключение",
            prompt_hint="adventure story",
            sort_order=1,
        ),
        Genre(
            slug="fairy-tale",
            name_ru="Волшебная сказка",
            prompt_hint="magical fairy tale",
            sort_order=2,
        ),
    ]
    db_session.add_all(items)
    await db_session.commit()
    for g in items:
        await db_session.refresh(g)
    return items


@pytest_asyncio.fixture
async def worlds(db_session: AsyncSession) -> list[World]:
    """Create test worlds."""
    items = [
        World(
            slug="forest",
            name_ru="Волшебный лес",
            prompt_hint="magical forest",
            visual_style_hint="enchanted green forest",
            sort_order=1,
        ),
        World(
            slug="ocean",
            name_ru="Подводный мир",
            prompt_hint="underwater world",
            visual_style_hint="deep blue underwater kingdom",
            sort_order=2,
        ),
    ]
    db_session.add_all(items)
    await db_session.commit()
    for w in items:
        await db_session.refresh(w)
    return items


@pytest_asyncio.fixture
async def base_tales(db_session: AsyncSession) -> list[BaseTale]:
    """Create test base tales with characters."""
    tale = BaseTale(
        slug="cinderella",
        name_ru="Золушка",
        summary_ru="История о бедной девушке, которая стала принцессой",
        plot_structure={"acts": 3, "climax": "ball"},
        moral_ru="Доброта вознаграждается",
        sort_order=1,
    )
    db_session.add(tale)
    await db_session.flush()

    char = BaseTaleCharacter(
        base_tale_id=tale.id,
        name_ru="Золушка",
        role="protagonist",
        appearance_prompt="A young woman with golden hair and blue eyes",
        personality_ru="Добрая и трудолюбивая",
        sort_order=1,
    )
    db_session.add(char)
    await db_session.commit()
    await db_session.refresh(tale)
    return [tale]


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
class TestGenres:
    async def test_list_genres_empty(self, client):
        resp = await client.get("/api/v1/catalog/genres")
        assert resp.status_code == 200
        assert resp.json() == []

    async def test_list_genres(self, client, genres):
        resp = await client.get("/api/v1/catalog/genres")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 2
        assert data[0]["slug"] == "adventure"
        assert data[0]["name_ru"] == "Приключение"
        assert data[1]["slug"] == "fairy-tale"

    async def test_genre_response_shape(self, client, genres):
        resp = await client.get("/api/v1/catalog/genres")
        genre = resp.json()[0]
        assert "id" in genre
        assert "slug" in genre
        assert "name_ru" in genre
        assert "sort_order" in genre


@pytest.mark.asyncio
class TestWorlds:
    async def test_list_worlds_empty(self, client):
        resp = await client.get("/api/v1/catalog/worlds")
        assert resp.status_code == 200
        assert resp.json() == []

    async def test_list_worlds(self, client, worlds):
        resp = await client.get("/api/v1/catalog/worlds")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 2
        assert data[0]["slug"] == "forest"
        assert data[0]["name_ru"] == "Волшебный лес"
        assert data[1]["slug"] == "ocean"


@pytest.mark.asyncio
class TestBaseTales:
    async def test_list_base_tales_empty(self, client):
        resp = await client.get("/api/v1/catalog/base-tales")
        assert resp.status_code == 200
        assert resp.json() == []

    async def test_list_base_tales(self, client, base_tales):
        resp = await client.get("/api/v1/catalog/base-tales")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["slug"] == "cinderella"
        assert data[0]["name_ru"] == "Золушка"

    async def test_get_base_tale_with_characters(self, client, base_tales):
        tale_id = base_tales[0].id
        resp = await client.get(f"/api/v1/catalog/base-tales/{tale_id}")
        assert resp.status_code == 200
        data = resp.json()
        assert data["name_ru"] == "Золушка"
        assert data["summary_ru"] is not None
        assert len(data["characters"]) == 1
        assert data["characters"][0]["name_ru"] == "Золушка"
        assert data["characters"][0]["role"] == "protagonist"

    async def test_get_base_tale_not_found(self, client):
        resp = await client.get("/api/v1/catalog/base-tales/9999")
        assert resp.status_code == 404
