from typing import AsyncGenerator
from uuid import UUID

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import UnauthorizedException
from app.core.security import decode_token
from app.database import get_async_session
from shared.models.user import User

security_scheme = HTTPBearer()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yield an async database session."""
    async for session in get_async_session():
        yield session


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Extract and validate the JWT from the Authorization header,
    then return the corresponding User from the database.
    """
    token = credentials.credentials

    try:
        payload = decode_token(token)
    except JWTError:
        raise UnauthorizedException(detail="Invalid or expired token")

    token_type = payload.get("type")
    if token_type != "access":
        raise UnauthorizedException(detail="Invalid token type")

    user_id_str: str | None = payload.get("sub")
    if user_id_str is None:
        raise UnauthorizedException(detail="Token missing subject")

    try:
        user_id = UUID(user_id_str)
    except ValueError:
        raise UnauthorizedException(detail="Invalid token subject")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise UnauthorizedException(detail="User not found")

    return user
