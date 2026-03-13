"""Unit tests for the worker pipeline context and stage base class."""

import os
import sys
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

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
os.environ.setdefault("REDIS_URL", "redis://localhost:6379")
os.environ.setdefault("JWT_SECRET", "test-secret")

import pytest

from app.pipeline.base import PipelineContext, PipelineStage


# ---------------------------------------------------------------------------
# PipelineContext tests
# ---------------------------------------------------------------------------

class TestPipelineContext:
    def test_initialization(self):
        ctx = PipelineContext(
            job_id="job-123",
            story_id="story-456",
            user_id="user-789",
            payload={"genre_id": 1, "world_id": 2},
        )
        assert ctx.job_id == "job-123"
        assert ctx.story_id == "story-456"
        assert ctx.user_id == "user-789"
        assert ctx.payload == {"genre_id": 1, "world_id": 2}

    def test_empty_collections(self):
        ctx = PipelineContext(
            job_id="j", story_id="s", user_id="u", payload={}
        )
        assert ctx.character_descriptions == {}
        assert ctx.story_bible is None
        assert ctx.pages_text == []
        assert ctx.scenes == []

    def test_mutable_state(self):
        ctx = PipelineContext(
            job_id="j", story_id="s", user_id="u", payload={}
        )
        ctx.character_descriptions["char-1"] = "Brown hair, blue eyes"
        ctx.story_bible = {"style": "watercolor"}
        ctx.pages_text.append({"page_number": 1, "text_content": "Once upon a time"})
        ctx.scenes.append({"page_number": 1, "scene": "forest"})

        assert len(ctx.character_descriptions) == 1
        assert ctx.story_bible["style"] == "watercolor"
        assert len(ctx.pages_text) == 1
        assert len(ctx.scenes) == 1


# ---------------------------------------------------------------------------
# PipelineStage tests
# ---------------------------------------------------------------------------

class TestPipelineStage:
    def test_base_stage_defaults(self):
        db = MagicMock()
        redis = MagicMock()
        stage = PipelineStage(db=db, redis=redis)
        assert stage.stage_name == "unknown"
        assert stage.stage_status == "processing"
        assert stage.progress_start == 0
        assert stage.progress_end == 0

    @pytest.mark.asyncio
    async def test_execute_raises_not_implemented(self):
        db = MagicMock()
        redis = MagicMock()
        stage = PipelineStage(db=db, redis=redis)
        ctx = PipelineContext(
            job_id="j", story_id="s", user_id="u", payload={}
        )
        with pytest.raises(NotImplementedError):
            await stage.execute(ctx)

    @pytest.mark.asyncio
    async def test_update_progress_clamps(self):
        """Progress should be clamped between progress_start and progress_end."""
        db = AsyncMock()
        db.execute = AsyncMock()
        db.commit = AsyncMock()

        redis = MagicMock()
        redis.set_progress = AsyncMock()

        stage = PipelineStage(db=db, redis=redis)
        stage.progress_start = 10
        stage.progress_end = 30

        ctx = PipelineContext(
            job_id="test-job", story_id="s", user_id="u", payload={}
        )

        # Value below start → clamped to start
        await stage.update_progress(ctx, 5, "Too low")
        redis.set_progress.assert_called()
        call_args = redis.set_progress.call_args[0]
        assert call_args[1]["progress_pct"] == 10

        # Value above end → clamped to end
        await stage.update_progress(ctx, 50, "Too high")
        call_args = redis.set_progress.call_args[0]
        assert call_args[1]["progress_pct"] == 30

        # Value in range → passed through
        await stage.update_progress(ctx, 20, "Just right")
        call_args = redis.set_progress.call_args[0]
        assert call_args[1]["progress_pct"] == 20


# ---------------------------------------------------------------------------
# Custom PipelineStage subclass test
# ---------------------------------------------------------------------------

class MockStage(PipelineStage):
    """Minimal concrete stage for testing."""
    stage_name = "mock_stage"
    stage_status = "mocking"
    progress_start = 0
    progress_end = 100

    def __init__(self, db, redis):
        super().__init__(db, redis)
        self.executed = False

    async def execute(self, ctx: PipelineContext) -> None:
        self.executed = True
        await self.update_progress(ctx, 50, "Half done")


class TestCustomStage:
    @pytest.mark.asyncio
    async def test_concrete_stage_executes(self):
        db = AsyncMock()
        db.execute = AsyncMock()
        db.commit = AsyncMock()

        redis = MagicMock()
        redis.set_progress = AsyncMock()

        stage = MockStage(db=db, redis=redis)
        ctx = PipelineContext(
            job_id="j", story_id="s", user_id="u", payload={}
        )

        await stage.execute(ctx)
        assert stage.executed is True
        assert redis.set_progress.called
