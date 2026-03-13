import uuid
from datetime import datetime
from typing import List, Optional

from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from shared.models.base import Base, TimestampMixin


class Character(TimestampMixin, Base):
    __tablename__ = "characters"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(
        String(100), nullable=False
    )
    character_type: Mapped[str] = mapped_column(
        String(20), nullable=False
    )
    gender: Mapped[str] = mapped_column(
        String(10), nullable=False
    )
    age: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True
    )
    appearance_description: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User", back_populates="characters"
    )
    photos: Mapped[List["CharacterPhoto"]] = relationship(
        "CharacterPhoto", back_populates="character", cascade="all, delete-orphan"
    )
    story_characters: Mapped[List["StoryCharacter"]] = relationship(
        "StoryCharacter", back_populates="character", cascade="all, delete-orphan"
    )

    __table_args__ = (
        CheckConstraint(
            "character_type IN ('child', 'adult', 'pet')",
            name="ck_characters_character_type",
        ),
        CheckConstraint(
            "gender IN ('male', 'female')",
            name="ck_characters_gender",
        ),
        Index("ix_characters_user_id", "user_id"),
    )
