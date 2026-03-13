import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.schemas.generation import (
    GenerationCreateRequest,
    GenerationJobResponse,
    GenerationStatusResponse,
)
from app.services import generation_service
from shared.models.user import User

router = APIRouter(prefix="/generation", tags=["generation"])


@router.post("/create", response_model=GenerationJobResponse, status_code=201)
async def create_generation(
    body: GenerationCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new story generation job."""
    job = await generation_service.create_generation_job(
        user_id=current_user.id,
        request=body,
        db=db,
    )
    return job


@router.get("/{job_id}/status", response_model=GenerationStatusResponse)
async def get_generation_status(
    job_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the current status of a generation job."""
    return await generation_service.get_job_status(
        job_id=job_id,
        user_id=current_user.id,
        db=db,
    )


@router.post("/{job_id}/cancel", response_model=GenerationJobResponse)
async def cancel_generation(
    job_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel a running or queued generation job."""
    return await generation_service.cancel_job(
        job_id=job_id,
        user_id=current_user.id,
        db=db,
    )
