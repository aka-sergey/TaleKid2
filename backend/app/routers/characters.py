import uuid

from fastapi import APIRouter, Depends, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.schemas.character import (
    CharacterCreateRequest,
    CharacterListResponse,
    CharacterPhotoResponse,
    CharacterResponse,
    CharacterUpdateRequest,
)
from app.services import character_service
from shared.models.user import User

router = APIRouter(prefix="/characters", tags=["characters"])


@router.get("", response_model=CharacterListResponse)
async def list_characters(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all characters belonging to the authenticated user."""
    characters = await character_service.list_characters(current_user.id, db)
    return CharacterListResponse(characters=characters)


@router.post("", response_model=CharacterResponse, status_code=201)
async def create_character(
    body: CharacterCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new character."""
    character = await character_service.create_character(
        user_id=current_user.id,
        data=body.model_dump(exclude_unset=True),
        db=db,
    )
    return character


@router.get("/{character_id}", response_model=CharacterResponse)
async def get_character(
    character_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get a character by ID (with photos)."""
    return await character_service.get_character(character_id, current_user.id, db)


@router.put("/{character_id}", response_model=CharacterResponse)
async def update_character(
    character_id: uuid.UUID,
    body: CharacterUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update a character."""
    return await character_service.update_character(
        character_id=character_id,
        user_id=current_user.id,
        data=body.model_dump(exclude_unset=True),
        db=db,
    )


@router.delete("/{character_id}", status_code=204)
async def delete_character(
    character_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a character and all associated photos."""
    await character_service.delete_character(character_id, current_user.id, db)


@router.post(
    "/{character_id}/photos",
    response_model=CharacterPhotoResponse,
    status_code=201,
)
async def upload_photo(
    character_id: uuid.UUID,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Upload a photo for a character (max 3 per character)."""
    file_data = await file.read()
    content_type = file.content_type or "image/jpeg"
    filename = file.filename or f"{uuid.uuid4()}.jpg"

    photo = await character_service.add_photo(
        character_id=character_id,
        user_id=current_user.id,
        file_data=file_data,
        filename=filename,
        content_type=content_type,
        db=db,
    )
    return photo


@router.delete("/{character_id}/photos/{photo_id}", status_code=204)
async def delete_photo(
    character_id: uuid.UUID,
    photo_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a specific photo from a character."""
    await character_service.delete_photo(character_id, photo_id, current_user.id, db)
