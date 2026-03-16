import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from shared.constants import STYLE_PROMPTS, VALID_ILLUSTRATION_STYLES  # noqa: F401 (re-exported)


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------
class GenerationCreateRequest(BaseModel):
    character_ids: list[uuid.UUID]
    genre_id: int
    world_id: int
    base_tale_id: Optional[int] = None
    age_range: str = Field(..., pattern=r"^(3-5|6-8|9-12)$")
    education_level: float = Field(0.5, ge=0.0, le=1.0)
    page_count: int = Field(10, ge=5, le=30)
    reading_duration_minutes: int = Field(10, ge=5, le=30)
    illustration_style: Optional[str] = Field(
        None,
        description="One of: watercolor, 3d-pixar, disney, comic, anime, pastel, classic-book, pop-art",
    )
    user_context: Optional[str] = Field(
        None,
        max_length=1000,
        description="Personal context from user to weave into the story (e.g. 'We visited the zoo today')",
    )


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------
class GenerationJobResponse(BaseModel):
    id: uuid.UUID
    story_id: uuid.UUID
    status: str
    progress_pct: int
    status_message: Optional[str]
    error_message: Optional[str]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}


class GenerationStatusResponse(BaseModel):
    job_id: uuid.UUID
    story_id: uuid.UUID
    status: str
    progress_pct: int
    status_message: Optional[str]
    error_message: Optional[str]
    story_title: Optional[str] = None
    cover_image_url: Optional[str] = None
