from typing import Optional

from pydantic import BaseModel


# ---------------------------------------------------------------------------
# Genre
# ---------------------------------------------------------------------------
class GenreResponse(BaseModel):
    id: int
    slug: str
    name_ru: str
    description_ru: Optional[str]
    icon_url: Optional[str]
    sort_order: int

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# World
# ---------------------------------------------------------------------------
class WorldResponse(BaseModel):
    id: int
    slug: str
    name_ru: str
    description_ru: Optional[str]
    icon_url: Optional[str]
    sort_order: int

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# BaseTale
# ---------------------------------------------------------------------------
class BaseTaleCharacterResponse(BaseModel):
    id: int
    name_ru: str
    role: str
    personality_ru: Optional[str]

    model_config = {"from_attributes": True}


class BaseTaleResponse(BaseModel):
    id: int
    slug: str
    name_ru: str
    summary_ru: str
    moral_ru: Optional[str]
    icon_url: Optional[str]
    characters: list[BaseTaleCharacterResponse] = []

    model_config = {"from_attributes": True}


class BaseTaleListResponse(BaseModel):
    """Lightweight representation used in list endpoints (no characters)."""
    id: int
    slug: str
    name_ru: str
    icon_url: Optional[str]

    model_config = {"from_attributes": True}
