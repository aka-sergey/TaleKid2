from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ConflictException, NotFoundException, UnauthorizedException
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.schemas.auth import TokenResponse, UserResponse
from shared.models.user import User


async def register_user(
    email: str,
    password: str,
    display_name: str,
    db: AsyncSession,
) -> TokenResponse:
    """
    Register a new user. Hashes the password, persists to DB,
    and returns JWT token pair.
    """
    # Check for existing user
    result = await db.execute(select(User).where(User.email == email))
    if result.scalar_one_or_none() is not None:
        raise ConflictException(detail="A user with this email already exists")

    user = User(
        email=email,
        password_hash=hash_password(password),
        display_name=display_name,
    )
    db.add(user)
    await db.flush()  # populate user.id without committing

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
    )


async def login_user(
    email: str,
    password: str,
    db: AsyncSession,
) -> TokenResponse:
    """
    Authenticate an existing user by email/password and return JWT tokens.
    """
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(password, user.password_hash):
        raise UnauthorizedException(detail="Invalid email or password")

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
    )


async def refresh_token(
    token: str,
    db: AsyncSession,
) -> TokenResponse:
    """
    Verify a refresh token and issue a new access token (and new refresh token).
    """
    try:
        payload = decode_token(token)
    except Exception:
        raise UnauthorizedException(detail="Invalid or expired refresh token")

    if payload.get("type") != "refresh":
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

    new_access_token = create_access_token(user.id)
    new_refresh_token = create_refresh_token(user.id)

    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
    )


async def get_user_by_id(user_id: UUID, db: AsyncSession) -> User:
    """
    Look up a user by primary key. Raises 404 if not found.
    """
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise NotFoundException(detail="User not found")
    return user
