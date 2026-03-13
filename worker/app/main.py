"""
TaleKID Worker — Main entry point.

Consumes generation jobs from Redis queue (BRPOP) and processes them
through a multi-stage pipeline:

Phase 4 (text):
  1. Photo analysis (GPT-4 Vision)
  2. Story bible generation
  3. Text generation (page by page)
  4. Scene decomposition

Phase 5 (images, to be added):
  5. Character reference generation
  6. Illustration generation (Leonardo.ai / DALL-E)

Phase 6 (finalization, to be added):
  7. Educational content
  8. Title generation
  9. Saving & push notification

Usage:
    python -m app.main
"""

import asyncio
import json
import logging
import signal
import sys
from datetime import datetime, timezone
from pathlib import Path
from uuid import UUID

# Make shared package importable
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from sqlalchemy import select, update

from app.config import get_settings
from app.database import async_session_factory, engine
from app.services.openai_service import OpenAIService
from app.services.redis_service import RedisService
from app.services.s3_service import S3Service

from shared.models.base import Base
from shared.models.generation_job import GenerationJob
from shared.models.story import Story

from app.pipeline.photo_analysis import PhotoAnalysisStage
from app.pipeline.story_bible import StoryBibleStage
from app.pipeline.text_generation import TextGenerationStage
from app.pipeline.scene_decomposition import SceneDecompositionStage
from app.pipeline.base import PipelineContext

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s [%(name)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("worker")

# ---------------------------------------------------------------------------
# Graceful shutdown
# ---------------------------------------------------------------------------
shutdown_event = asyncio.Event()


def _signal_handler():
    logger.info("Shutdown signal received")
    shutdown_event.set()


# ---------------------------------------------------------------------------
# Pipeline orchestrator
# ---------------------------------------------------------------------------
async def run_pipeline(payload: dict, redis: RedisService) -> None:
    """Execute the full generation pipeline for a single job."""
    job_id = payload["job_id"]
    story_id = payload["story_id"]
    user_id = payload["user_id"]

    logger.info("Starting pipeline for job %s (story %s)", job_id[:8], story_id[:8])

    # Services
    openai_svc = OpenAIService()
    # s3_svc = S3Service()  # Will be used in Phase 5

    async with async_session_factory() as db:
        try:
            # Mark job as processing
            await db.execute(
                update(GenerationJob)
                .where(GenerationJob.id == job_id)
                .values(
                    status="processing",
                    started_at=datetime.now(timezone.utc),
                    progress_pct=0,
                    status_message="Начинаем создание сказки...",
                )
            )
            await db.execute(
                update(Story).where(Story.id == story_id).values(status="generating")
            )
            await db.commit()

            # Build context
            ctx = PipelineContext(
                job_id=job_id,
                story_id=story_id,
                user_id=user_id,
                payload=payload,
            )

            # ---- Stage 1: Photo Analysis (5% → 15%) ----
            stage1 = PhotoAnalysisStage(db, redis, openai_svc)
            await stage1.execute(ctx)

            # ---- Stage 2: Story Bible (15% → 30%) ----
            stage2 = StoryBibleStage(db, redis, openai_svc)
            await stage2.execute(ctx)

            # ---- Stage 3: Text Generation (30% → 55%) ----
            stage3 = TextGenerationStage(db, redis, openai_svc)
            await stage3.execute(ctx)

            # ---- Stage 4: Scene Decomposition (55% → 65%) ----
            stage4 = SceneDecompositionStage(db, redis, openai_svc)
            await stage4.execute(ctx)

            # ---- Phases 5-6 placeholder ----
            # Stage 5: Character references (65% → 70%)
            # Stage 6: Illustration generation (70% → 90%)
            # Stage 7: Educational content (90% → 93%)
            # Stage 8: Title generation (93% → 96%)
            # Stage 9: Finalization + push (96% → 100%)

            # For now, mark as completed at 65% until Phase 5-6 are implemented
            await db.execute(
                update(GenerationJob)
                .where(GenerationJob.id == job_id)
                .values(
                    status="completed",
                    progress_pct=100,
                    status_message="Сказка готова! (текст создан, иллюстрации будут в следующей версии)",
                    completed_at=datetime.now(timezone.utc),
                )
            )
            await db.execute(
                update(Story).where(Story.id == story_id).values(status="completed")
            )
            await db.commit()

            await redis.set_progress(job_id, {
                "status": "completed",
                "progress_pct": 100,
                "status_message": "Сказка готова!",
            })

            logger.info("Pipeline completed successfully for job %s", job_id[:8])

        except Exception as e:
            logger.exception("Pipeline failed for job %s: %s", job_id[:8], e)

            # Mark as failed
            try:
                await db.rollback()
                await db.execute(
                    update(GenerationJob)
                    .where(GenerationJob.id == job_id)
                    .values(
                        status="failed",
                        error_message=str(e)[:2000],
                        status_message="Произошла ошибка при создании сказки",
                        completed_at=datetime.now(timezone.utc),
                    )
                )
                await db.execute(
                    update(Story).where(Story.id == story_id).values(status="failed")
                )
                await db.commit()

                await redis.set_progress(job_id, {
                    "status": "failed",
                    "progress_pct": 0,
                    "status_message": "Ошибка создания сказки",
                    "error_message": str(e)[:500],
                })
            except Exception as inner_e:
                logger.error("Failed to mark job as failed: %s", inner_e)


# ---------------------------------------------------------------------------
# Main consumer loop
# ---------------------------------------------------------------------------
async def consumer_loop() -> None:
    """Main loop: BRPOP from Redis, dispatch to pipeline."""
    settings = get_settings()
    redis = RedisService()

    logger.info("Worker started. Listening on queue: %s", settings.REDIS_QUEUE)

    try:
        while not shutdown_event.is_set():
            try:
                payload = await redis.wait_for_job(timeout=5)
                if payload is None:
                    continue  # Timeout, check shutdown flag and loop

                logger.info("Received job: %s", json.dumps(payload, default=str)[:200])
                await run_pipeline(payload, redis)

            except Exception as e:
                logger.exception("Error in consumer loop: %s", e)
                # Brief pause before retrying to avoid tight error loops
                await asyncio.sleep(2)
    finally:
        await redis.close()
        await engine.dispose()
        logger.info("Worker shut down cleanly")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def main():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    # Register signal handlers
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, _signal_handler)

    try:
        loop.run_until_complete(consumer_loop())
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
    finally:
        loop.close()


if __name__ == "__main__":
    main()
