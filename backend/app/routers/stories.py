import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.schemas.story import (
    StoryCharacterResponse,
    StoryDetailResponse,
    StoryListResponse,
    StoryResponse,
    StoryUpdateTitleRequest,
)
from app.services import story_service
from shared.models.user import User

router = APIRouter(prefix="/stories", tags=["stories"])


@router.get("", response_model=StoryListResponse)
async def list_stories(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all stories for the authenticated user (paginated)."""
    stories, total = await story_service.list_stories(
        user_id=current_user.id,
        db=db,
        skip=skip,
        limit=limit,
    )
    return StoryListResponse(stories=stories, total=total)


@router.get("/{story_id}", response_model=StoryDetailResponse)
async def get_story(
    story_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get full story details with pages and characters."""
    story = await story_service.get_story_detail(
        story_id=story_id,
        user_id=current_user.id,
        db=db,
    )
    # Build character response list from story_characters relationship
    characters = [
        StoryCharacterResponse(
            character_id=sc.character_id,
            character_name=sc.character.name,
            role_in_story=sc.role_in_story,
            reference_image_url=sc.reference_image_url,
        )
        for sc in story.story_characters
    ]
    return StoryDetailResponse(
        id=story.id,
        title=story.title,
        title_suggested=story.title_suggested,
        cover_image_url=story.cover_image_url,
        status=story.status,
        age_range=story.age_range,
        education_level=story.education_level,
        page_count=story.page_count,
        reading_duration_minutes=story.reading_duration_minutes,
        created_at=story.created_at,
        updated_at=story.updated_at,
        pages=story.pages,
        characters=characters,
    )


@router.put("/{story_id}/title", response_model=StoryResponse)
async def update_story_title(
    story_id: uuid.UUID,
    body: StoryUpdateTitleRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update the title of a story."""
    return await story_service.update_story_title(
        story_id=story_id,
        user_id=current_user.id,
        title=body.title,
        db=db,
    )


@router.delete("/{story_id}", status_code=204)
async def delete_story(
    story_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a story and all associated S3 images."""
    await story_service.delete_story(
        story_id=story_id,
        user_id=current_user.id,
        db=db,
    )
