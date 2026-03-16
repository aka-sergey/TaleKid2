import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.schemas.generation import GenerationCreateRequest
from app.services.redis_service import get_redis_service
from shared.constants import JobStatus, StoryStatus
from shared.models.base_tale import BaseTale
from shared.models.character import Character
from shared.models.generation_job import GenerationJob
from shared.models.genre import Genre
from shared.models.story import Story, StoryCharacter
from shared.models.world import World

logger = logging.getLogger("talekid.generation")


async def create_generation_job(
    user_id: uuid.UUID,
    request: GenerationCreateRequest,
    db: AsyncSession,
) -> GenerationJob:
    """
    Create a new story generation job:
    1. Validate character ownership, genre, world, and optional base tale.
    2. Create Story and StoryCharacter records.
    3. Create GenerationJob record.
    4. Enqueue job in Redis.
    """
    # --- Validate character_ids belong to user ---
    if not request.character_ids:
        raise BadRequestException(detail="At least one character is required")

    result = await db.execute(
        select(Character).where(
            Character.id.in_(request.character_ids),
            Character.user_id == user_id,
        )
    )
    characters = list(result.scalars().all())
    if len(characters) != len(request.character_ids):
        raise BadRequestException(
            detail="One or more characters not found or do not belong to you"
        )

    # --- Validate genre ---
    result = await db.execute(
        select(Genre).where(Genre.id == request.genre_id)
    )
    genre = result.scalar_one_or_none()
    if genre is None:
        raise NotFoundException(detail="Genre not found")

    # --- Validate world ---
    result = await db.execute(
        select(World).where(World.id == request.world_id)
    )
    world = result.scalar_one_or_none()
    if world is None:
        raise NotFoundException(detail="World not found")

    # --- Validate base_tale (optional) ---
    if request.base_tale_id is not None:
        result = await db.execute(
            select(BaseTale).where(BaseTale.id == request.base_tale_id)
        )
        base_tale = result.scalar_one_or_none()
        if base_tale is None:
            raise NotFoundException(detail="Base tale not found")

    # --- Create Story ---
    story = Story(
        user_id=user_id,
        genre_id=request.genre_id,
        world_id=request.world_id,
        base_tale_id=request.base_tale_id,
        age_range=request.age_range,
        education_level=request.education_level,
        page_count=request.page_count,
        reading_duration_minutes=request.reading_duration_minutes,
        illustration_style=request.illustration_style,
        user_context=request.user_context,
        status=StoryStatus.GENERATING.value,
    )
    db.add(story)
    await db.flush()

    # --- Create StoryCharacter records ---
    for character in characters:
        sc = StoryCharacter(
            story_id=story.id,
            character_id=character.id,
        )
        db.add(sc)
    await db.flush()

    # --- Create GenerationJob ---
    job = GenerationJob(
        story_id=story.id,
        status=JobStatus.QUEUED.value,
        progress_pct=0,
    )
    db.add(job)
    await db.flush()
    await db.refresh(job)

    # --- Enqueue in Redis ---
    redis_svc = get_redis_service()
    payload = {
        "story_id": str(story.id),
        "user_id": str(user_id),
        "character_ids": [str(cid) for cid in request.character_ids],
        "genre_id": request.genre_id,
        "world_id": request.world_id,
        "base_tale_id": request.base_tale_id,
        "age_range": request.age_range,
        "education_level": request.education_level,
        "page_count": request.page_count,
        "reading_duration_minutes": request.reading_duration_minutes,
        "illustration_style": request.illustration_style,
        "user_context": request.user_context,
    }
    await redis_svc.enqueue_job(str(job.id), payload)

    logger.info("Generation job %s created for story %s", job.id, story.id)
    return job


async def get_job_status(
    job_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> dict:
    """
    Return the current status of a generation job.
    Merges DB state with real-time Redis progress when available.
    """
    result = await db.execute(
        select(GenerationJob)
        .where(GenerationJob.id == job_id)
        .options(selectinload(GenerationJob.story))
    )
    job = result.scalar_one_or_none()
    if job is None:
        raise NotFoundException(detail="Generation job not found")

    # Ownership check via story
    if job.story.user_id != user_id:
        raise ForbiddenException(detail="Access denied")

    # Start with DB values
    status_data = {
        "job_id": job.id,
        "story_id": job.story_id,
        "status": job.status,
        "progress_pct": job.progress_pct,
        "status_message": job.status_message,
        "error_message": job.error_message,
        "story_title": None,
        "cover_image_url": None,
    }

    # Overlay real-time progress from Redis (if present)
    redis_svc = get_redis_service()
    progress = await redis_svc.get_progress(str(job_id))
    if progress is not None:
        status_data["status"] = progress.get("status", status_data["status"])
        status_data["progress_pct"] = progress.get(
            "progress_pct", status_data["progress_pct"]
        )
        status_data["status_message"] = progress.get(
            "status_message", status_data["status_message"]
        )

    # When completed, include story details
    if job.status == JobStatus.COMPLETED.value:
        status_data["story_title"] = job.story.title or job.story.title_suggested
        status_data["cover_image_url"] = job.story.cover_image_url

    return status_data


async def cancel_job(
    job_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> GenerationJob:
    """
    Cancel a running/queued generation job.
    Sets job status to 'failed' and story status to 'failed'.
    """
    result = await db.execute(
        select(GenerationJob)
        .where(GenerationJob.id == job_id)
        .options(selectinload(GenerationJob.story))
    )
    job = result.scalar_one_or_none()
    if job is None:
        raise NotFoundException(detail="Generation job not found")

    # Ownership check via story
    if job.story.user_id != user_id:
        raise ForbiddenException(detail="Access denied")

    # Only cancel if not already completed/failed
    if job.status in (JobStatus.COMPLETED.value, JobStatus.FAILED.value):
        raise BadRequestException(
            detail=f"Cannot cancel job with status '{job.status}'"
        )

    # Update job
    job.status = JobStatus.FAILED.value
    job.error_message = "Cancelled by user"
    job.completed_at = datetime.now(timezone.utc)

    # Update story
    job.story.status = StoryStatus.FAILED.value

    await db.flush()
    await db.refresh(job)

    # Clean up Redis progress
    redis_svc = get_redis_service()
    await redis_svc.delete_progress(str(job_id))

    logger.info("Generation job %s cancelled by user %s", job_id, user_id)
    return job
