"""
TaleKID Worker — Main entry point.

Consumes generation jobs from Redis queue (BRPOP) and processes them
through a multi-stage pipeline:

Phase 4 (text):
  1. Photo analysis (GPT-4 Vision)
  2. Story bible generation
  3. Text generation (page by page)
  4. Scene decomposition

Phase 5 (images):
  5. Character reference generation (Leonardo.ai / DALL-E)
  6. Illustration generation (10 parallel threads)

Phase 6 (finalization):
  7. Educational content (facts & questions)
  8. Title generation (catchy Russian title)
  9. Finalization (push notification + save)

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

import langsmith

# Make shared package importable
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from sqlalchemy import select, update

from app.config import get_settings
from app.database import async_session_factory, engine
from app.services.openai_service import OpenAIService
from app.services.redis_service import RedisService
from app.services.s3_service import S3Service
from app.services.image_service import ImageService

from shared.models.base import Base
from shared.models.generation_job import GenerationJob
from shared.models.story import Story

from app.pipeline.photo_analysis import PhotoAnalysisStage
from app.pipeline.story_bible import StoryBibleStage
from app.pipeline.text_generation import TextGenerationStage
from app.pipeline.scene_decomposition import SceneDecompositionStage
from app.pipeline.character_references import CharacterReferencesStage
from app.pipeline.illustration import IllustrationStage
from app.pipeline.education import EducationStage
from app.pipeline.title_generation import TitleGenerationStage
from app.pipeline.finalization import FinalizationStage
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
    s3_svc = S3Service()
    image_svc = ImageService()

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

            # All OpenAI calls inside this block are grouped under one LangSmith trace.
            with langsmith.trace(
                name="generation_pipeline",
                run_type="chain",
                metadata={
                    "job_id": job_id,
                    "story_id": story_id,
                    "user_id": user_id,
                },
                tags=[f"job:{job_id[:8]}", f"story:{story_id[:8]}"],
            ):
                # ---- Stage 1: Photo Analysis (5% → 15%) ----
                with langsmith.trace(name="1_photo_analysis", run_type="chain"):
                    stage1 = PhotoAnalysisStage(db, redis, openai_svc)
                    await stage1.execute(ctx)

                # ---- Stage 2: Story Bible (15% → 30%) ----
                with langsmith.trace(name="2_story_bible", run_type="chain"):
                    stage2 = StoryBibleStage(db, redis, openai_svc)
                    await stage2.execute(ctx)

                # ---- Stage 3+4: Text + Scene Generation (30% → 65%, 2-wave parallel) ----
                with langsmith.trace(name="3_text_generation", run_type="chain"):
                    stage3 = TextGenerationStage(db, redis, openai_svc)
                    await stage3.execute(ctx)

                # Stage 4 is now a no-op (ctx.scenes already populated above).
                stage4 = SceneDecompositionStage(db, redis, openai_svc)
                await stage4.execute(ctx)

                # ---- Stage 5: Character References (65% → 70%) ----
                stage5 = CharacterReferencesStage(db, redis, image_svc, s3_svc)
                await stage5.execute(ctx)

                # ---- Stage 6: Illustration Generation (70% → 90%) ----
                stage6 = IllustrationStage(db, redis, image_svc, s3_svc)
                await stage6.execute(ctx)

                # ---- Stage 7: Educational Content (90% → 93%) ----
                with langsmith.trace(name="7_education", run_type="chain"):
                    stage7 = EducationStage(db, redis, openai_svc)
                    await stage7.execute(ctx)

                # ---- Stage 8: Title Generation (93% → 96%) ----
                with langsmith.trace(name="8_title_generation", run_type="chain"):
                    stage8 = TitleGenerationStage(db, redis, openai_svc)
                    await stage8.execute(ctx)

                # ---- Stage 9: Finalization + Push (96% → 100%) ----
                stage9 = FinalizationStage(db, redis)
                await stage9.execute(ctx)

            # Mark as completed
            await db.execute(
                update(GenerationJob)
                .where(GenerationJob.id == job_id)
                .values(
                    status="completed",
                    progress_pct=100,
                    status_message="Сказка готова!",
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
