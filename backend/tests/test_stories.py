"""Integration tests for /api/v1/stories endpoints."""

import os
import sys
import uuid
from pathlib import Path
from unittest.mock import MagicMock, patch

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
from shared.models.story import Story
from shared.models.page import Page


# ---------------------------------------------------------------------------
# Story-specific fixtures
# ---------------------------------------------------------------------------

@pytest_asyncio.fixture
async def genre(db_session: AsyncSession) -> Genre:
    g = Genre(
        slug="test-genre",
        name_ru="Тестовый жанр",
        prompt_hint="test genre prompt",
        sort_order=1,
    )
    db_session.add(g)
    await db_session.commit()
    await db_session.refresh(g)
    return g


@pytest_asyncio.fixture
async def world(db_session: AsyncSession) -> World:
    w = World(
        slug="test-world",
        name_ru="Тестовый мир",
        prompt_hint="test world prompt",
        visual_style_hint="test visual style",
        sort_order=1,
    )
    db_session.add(w)
    await db_session.commit()
    await db_session.refresh(w)
    return w


@pytest_asyncio.fixture
async def story(db_session: AsyncSession, test_user, genre, world) -> Story:
    """Create a completed story with one page."""
    s = Story(
        id=uuid.uuid4(),
        user_id=test_user.id,
        genre_id=genre.id,
        world_id=world.id,
        age_range="3-5",
        education_level=0.5,
        page_count=5,
        reading_duration_minutes=10,
        status="completed",
        title="Тестовая сказка",
    )
    db_session.add(s)
    await db_session.flush()

    p = Page(
        id=uuid.uuid4(),
        story_id=s.id,
        page_number=1,
        text_content="Жили-были в лесу зайчик и лисичка.",
    )
    db_session.add(p)
    await db_session.commit()
    await db_session.refresh(s)
    return s


# ---------------------------------------------------------------------------
# Tests — List Stories
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
class TestListStories:
    async def test_list_stories_empty(self, client, auth_headers):
        resp = await client.get("/api/v1/stories", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["stories"] == []
        assert data["total"] == 0

    async def test_list_stories_with_data(self, client, auth_headers, story):
        resp = await client.get("/api/v1/stories", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] == 1
        assert len(data["stories"]) == 1
        assert data["stories"][0]["title"] == "Тестовая сказка"
        assert data["stories"][0]["status"] == "completed"
        assert data["stories"][0]["age_range"] == "3-5"

    async def test_list_stories_pagination(self, client, auth_headers, story):
        resp = await client.get(
            "/api/v1/stories?skip=0&limit=1",
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["total"] == 1

    async def test_list_stories_no_auth(self, client):
        resp = await client.get("/api/v1/stories")
        assert resp.status_code == 403


# ---------------------------------------------------------------------------
# Tests — Update Title
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
class TestUpdateStoryTitle:
    async def test_update_title_success(self, client, auth_headers, story):
        resp = await client.put(
            f"/api/v1/stories/{story.id}/title",
            json={"title": "Новое название"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["title"] == "Новое название"

    async def test_update_title_not_found(self, client, auth_headers):
        fake_id = uuid.uuid4()
        resp = await client.put(
            f"/api/v1/stories/{fake_id}/title",
            json={"title": "Нет такой сказки"},
            headers=auth_headers,
        )
        assert resp.status_code == 404

    async def test_update_title_empty_string(self, client, auth_headers, story):
        resp = await client.put(
            f"/api/v1/stories/{story.id}/title",
            json={"title": ""},
            headers=auth_headers,
        )
        assert resp.status_code == 422  # min_length=1


# ---------------------------------------------------------------------------
# Tests — Delete Story
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
class TestDeleteStory:
    @patch("app.services.story_service.get_s3_service")
    async def test_delete_story_success(self, mock_s3_fn, client, auth_headers, story):
        mock_s3_fn.return_value = MagicMock()
        resp = await client.delete(
            f"/api/v1/stories/{story.id}",
            headers=auth_headers,
        )
        assert resp.status_code == 204

    async def test_delete_story_not_found(self, client, auth_headers):
        fake_id = uuid.uuid4()
        resp = await client.delete(
            f"/api/v1/stories/{fake_id}",
            headers=auth_headers,
        )
        assert resp.status_code == 404

    async def test_delete_story_no_auth(self, client, story):
        resp = await client.delete(f"/api/v1/stories/{story.id}")
        assert resp.status_code == 403
