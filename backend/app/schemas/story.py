import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Nested response schemas
# ---------------------------------------------------------------------------
class EducationalContentResponse(BaseModel):
    content_type: str
    text_ru: str
    answer_ru: Optional[str]
    topic: Optional[str]

    model_config = {"from_attributes": True}


class PageResponse(BaseModel):
    id: uuid.UUID
    page_number: int
    text_content: Optional[str]
    image_url: Optional[str]
    educational_content: Optional[EducationalContentResponse] = None

    model_config = {"from_attributes": True}


class StoryCharacterResponse(BaseModel):
    character_id: uuid.UUID
    character_name: str
    role_in_story: Optional[str]
    reference_image_url: Optional[str]


# ---------------------------------------------------------------------------
# Story response schemas
# ---------------------------------------------------------------------------
class StoryResponse(BaseModel):
    id: uuid.UUID
    title: Optional[str]
    title_suggested: Optional[str]
    cover_image_url: Optional[str]
    status: str
    age_range: str
    education_level: float
    page_count: int
    reading_duration_minutes: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class StoryDetailResponse(StoryResponse):
    pages: list[PageResponse]
    characters: list[StoryCharacterResponse]


class StoryListResponse(BaseModel):
    stories: list[StoryResponse]
    total: int


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------
class StoryUpdateTitleRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=300)
