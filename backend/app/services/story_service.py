import logging
import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import ForbiddenException, NotFoundException
from app.services.s3_service import get_s3_service
from shared.models.page import Page
from shared.models.story import Story, StoryCharacter

logger = logging.getLogger("talekid.stories")


async def list_stories(
    user_id: uuid.UUID,
    db: AsyncSession,
    skip: int = 0,
    limit: int = 20,
) -> tuple[list[Story], int]:
    """Return paginated stories for a user, ordered by created_at descending."""
    # Total count
    count_result = await db.execute(
        select(func.count()).select_from(Story).where(Story.user_id == user_id)
    )
    total = count_result.scalar_one()

    # Fetch stories
    result = await db.execute(
        select(Story)
        .where(Story.user_id == user_id)
        .order_by(Story.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    stories = list(result.scalars().all())
    return stories, total


async def get_story_detail(
    story_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> Story:
    """Return a story with pages, characters, and educational content."""
    result = await db.execute(
        select(Story)
        .where(Story.id == story_id)
        .options(
            selectinload(Story.pages).selectinload(Page.educational_content),
            selectinload(Story.story_characters).selectinload(StoryCharacter.character),
        )
    )
    story = result.scalar_one_or_none()
    if story is None:
        raise NotFoundException(detail="Story not found")
    if story.user_id != user_id:
        raise ForbiddenException(detail="Access denied")
    return story


async def update_story_title(
    story_id: uuid.UUID,
    user_id: uuid.UUID,
    title: str,
    db: AsyncSession,
) -> Story:
    """Update the title of a story (ownership check included)."""
    result = await db.execute(
        select(Story).where(Story.id == story_id)
    )
    story = result.scalar_one_or_none()
    if story is None:
        raise NotFoundException(detail="Story not found")
    if story.user_id != user_id:
        raise ForbiddenException(detail="Access denied")

    story.title = title
    await db.flush()
    await db.refresh(story)
    return story


async def delete_story(
    story_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> None:
    """Delete a story plus associated S3 images."""
    result = await db.execute(
        select(Story)
        .where(Story.id == story_id)
        .options(selectinload(Story.pages))
    )
    story = result.scalar_one_or_none()
    if story is None:
        raise NotFoundException(detail="Story not found")
    if story.user_id != user_id:
        raise ForbiddenException(detail="Access denied")

    # Delete page images and cover image from S3
    s3 = get_s3_service()
    s3.delete_prefix(f"stories/{story_id}/")

    await db.delete(story)
    await db.flush()

    logger.info("Story %s deleted by user %s", story_id, user_id)
