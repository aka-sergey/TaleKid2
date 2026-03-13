from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import NotFoundException
from app.dependencies import get_db
from app.schemas.catalog import (
    BaseTaleListResponse,
    BaseTaleResponse,
    GenreResponse,
    WorldResponse,
)
from shared.models.base_tale import BaseTale
from shared.models.genre import Genre
from shared.models.world import World

router = APIRouter(prefix="/catalog", tags=["catalog"])


@router.get("/genres", response_model=list[GenreResponse])
async def list_genres(db: AsyncSession = Depends(get_db)):
    """Return all genres ordered by sort_order."""
    result = await db.execute(
        select(Genre).order_by(Genre.sort_order)
    )
    return result.scalars().all()


@router.get("/worlds", response_model=list[WorldResponse])
async def list_worlds(db: AsyncSession = Depends(get_db)):
    """Return all worlds ordered by sort_order."""
    result = await db.execute(
        select(World).order_by(World.sort_order)
    )
    return result.scalars().all()


@router.get("/base-tales", response_model=list[BaseTaleListResponse])
async def list_base_tales(db: AsyncSession = Depends(get_db)):
    """Return all base tales (brief, without characters)."""
    result = await db.execute(
        select(BaseTale).order_by(BaseTale.sort_order)
    )
    return result.scalars().all()


@router.get("/base-tales/{tale_id}", response_model=BaseTaleResponse)
async def get_base_tale(tale_id: int, db: AsyncSession = Depends(get_db)):
    """Return a single base tale with its characters."""
    result = await db.execute(
        select(BaseTale)
        .where(BaseTale.id == tale_id)
        .options(selectinload(BaseTale.characters))
    )
    tale = result.scalar_one_or_none()
    if tale is None:
        raise NotFoundException(detail="Base tale not found")
    return tale
