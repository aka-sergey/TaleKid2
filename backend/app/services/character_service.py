import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.services.s3_service import get_s3_service
from shared.models.character import Character
from shared.models.character_photo import CharacterPhoto

MAX_PHOTOS_PER_CHARACTER = 3


async def list_characters(user_id: uuid.UUID, db: AsyncSession) -> list[Character]:
    """Return all characters belonging to *user_id* with photos eager-loaded."""
    result = await db.execute(
        select(Character)
        .where(Character.user_id == user_id)
        .options(selectinload(Character.photos))
        .order_by(Character.created_at.desc())
    )
    return list(result.scalars().all())


async def get_character(
    character_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> Character:
    """Return a single character (with ownership check)."""
    result = await db.execute(
        select(Character)
        .where(Character.id == character_id)
        .options(selectinload(Character.photos))
    )
    character = result.scalar_one_or_none()
    if character is None:
        raise NotFoundException(detail="Character not found")
    if character.user_id != user_id:
        raise ForbiddenException(detail="Access denied")
    return character


async def create_character(
    user_id: uuid.UUID,
    data: dict,
    db: AsyncSession,
) -> Character:
    """Create a new character for *user_id*."""
    character = Character(user_id=user_id, **data)
    db.add(character)
    await db.flush()
    await db.refresh(character, attribute_names=["photos"])
    return character


async def update_character(
    character_id: uuid.UUID,
    user_id: uuid.UUID,
    data: dict,
    db: AsyncSession,
) -> Character:
    """Update an existing character (ownership check included)."""
    character = await get_character(character_id, user_id, db)
    for key, value in data.items():
        if value is not None:
            setattr(character, key, value)
    await db.flush()
    await db.refresh(character, attribute_names=["photos"])
    return character


async def delete_character(
    character_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> None:
    """Delete a character and all associated photos from S3 + database."""
    character = await get_character(character_id, user_id, db)

    # Delete photos from S3
    s3 = get_s3_service()
    s3.delete_prefix(f"character-photos/{user_id}/{character_id}/")

    await db.delete(character)
    await db.flush()


async def add_photo(
    character_id: uuid.UUID,
    user_id: uuid.UUID,
    file_data: bytes,
    filename: str,
    content_type: str,
    db: AsyncSession,
) -> CharacterPhoto:
    """Upload a photo for a character (max 3 photos enforced)."""
    character = await get_character(character_id, user_id, db)

    if len(character.photos) >= MAX_PHOTOS_PER_CHARACTER:
        raise BadRequestException(
            detail=f"Maximum {MAX_PHOTOS_PER_CHARACTER} photos per character"
        )

    # Determine sort order
    sort_order = max((p.sort_order for p in character.photos), default=-1) + 1

    # Upload to S3
    s3_key = f"character-photos/{user_id}/{character_id}/{filename}"
    s3 = get_s3_service()
    s3_url = s3.upload_file(key=s3_key, data=file_data, content_type=content_type)

    photo = CharacterPhoto(
        character_id=character_id,
        s3_key=s3_key,
        s3_url=s3_url,
        sort_order=sort_order,
    )
    db.add(photo)
    await db.flush()
    await db.refresh(photo)
    return photo


async def delete_photo(
    character_id: uuid.UUID,
    photo_id: uuid.UUID,
    user_id: uuid.UUID,
    db: AsyncSession,
) -> None:
    """Delete a single photo from a character."""
    # Ownership check via character
    await get_character(character_id, user_id, db)

    result = await db.execute(
        select(CharacterPhoto).where(
            CharacterPhoto.id == photo_id,
            CharacterPhoto.character_id == character_id,
        )
    )
    photo = result.scalar_one_or_none()
    if photo is None:
        raise NotFoundException(detail="Photo not found")

    # Delete from S3
    s3 = get_s3_service()
    s3.delete_file(photo.s3_key)

    await db.delete(photo)
    await db.flush()
