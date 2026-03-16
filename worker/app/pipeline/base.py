import json
import logging
from datetime import datetime, timezone

from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from shared.models.generation_job import GenerationJob
from app.services.redis_service import RedisService

logger = logging.getLogger("worker.pipeline")


class PipelineContext:
    """Shared state passed through all pipeline stages."""

    def __init__(self, job_id: str, story_id: str, user_id: str, payload: dict):
        self.job_id = job_id
        self.story_id = story_id
        self.user_id = user_id
        self.payload = payload
        # Accumulated data
        self.character_descriptions: dict[str, str] = {}  # char_id -> appearance description
        self.story_bible: dict | None = None
        self.pages_text: list[dict] = []  # [{page_number, text_content}]
        self.scenes: list[dict] = []  # [{page_number, scene_description, image_prompt}]
        # Leonardo image IDs for character references (char_id -> leonardo_image_id)
        # Used for initImageId + initImageType="GENERATED" in controlnets
        self.character_leonardo_ids: dict[str, str] = {}
        # Illustration style chosen by user (e.g. "watercolor", "3d-pixar")
        self.illustration_style: str | None = payload.get("illustration_style")
        # Personal context from user to weave into the story
        # (e.g. "We visited the zoo today and saw many animals")
        self.user_context: str | None = payload.get("user_context")


class PipelineStage:
    """Base class for a pipeline stage."""

    stage_name: str = "unknown"
    stage_status: str = "processing"
    progress_start: int = 0
    progress_end: int = 0

    def __init__(self, db: AsyncSession, redis: RedisService):
        self.db = db
        self.redis = redis

    async def execute(self, ctx: PipelineContext) -> None:
        raise NotImplementedError

    async def update_progress(self, ctx: PipelineContext, pct: int, message: str):
        """Update progress in both Redis (real-time) and DB."""
        clamped = max(self.progress_start, min(pct, self.progress_end))
        await self.redis.set_progress(ctx.job_id, {
            "status": self.stage_status,
            "progress_pct": clamped,
            "status_message": message,
        })
        await self.db.execute(
            update(GenerationJob)
            .where(GenerationJob.id == ctx.job_id)
            .values(
                status=self.stage_status,
                progress_pct=clamped,
                status_message=message,
            )
        )
        await self.db.commit()
        logger.info(
            "[%s] %s: %d%% - %s",
            ctx.job_id[:8],
            self.stage_name,
            clamped,
            message,
        )
