import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------
class CharacterCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    character_type: str = Field(..., pattern=r"^(child|adult|pet)$")
    gender: str = Field(..., pattern=r"^(male|female)$")
    age: Optional[int] = Field(None, ge=0, le=150)


class CharacterUpdateRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    character_type: Optional[str] = Field(None, pattern=r"^(child|adult|pet)$")
    gender: Optional[str] = Field(None, pattern=r"^(male|female)$")
    age: Optional[int] = Field(None, ge=0, le=150)


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------
class CharacterPhotoResponse(BaseModel):
    id: uuid.UUID
    s3_url: str
    sort_order: int

    model_config = {"from_attributes": True}


class CharacterResponse(BaseModel):
    id: uuid.UUID
    name: str
    character_type: str
    gender: str
    age: Optional[int]
    appearance_description: Optional[str]
    photos: list[CharacterPhotoResponse] = []
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class CharacterListResponse(BaseModel):
    characters: list[CharacterResponse]
