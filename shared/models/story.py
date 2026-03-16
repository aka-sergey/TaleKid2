import uuid
from datetime import datetime
from typing import List, Optional

from sqlalchemy import (
    CheckConstraint,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from shared.models.base import Base, TimestampMixin


class Story(TimestampMixin, Base):
    __tablename__ = "stories"

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
    title: Mapped[Optional[str]] = mapped_column(
        String(300), nullable=True
    )
    title_suggested: Mapped[Optional[str]] = mapped_column(
        String(300), nullable=True
    )
    base_tale_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("base_tales.id"),
        nullable=True,
    )
    genre_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("genres.id"),
        nullable=False,
    )
    world_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("worlds.id"),
        nullable=False,
    )
    age_range: Mapped[str] = mapped_column(
        String(10), nullable=False
    )
    education_level: Mapped[float] = mapped_column(
        Float, nullable=False, default=0.0, server_default=text("0.0")
    )
    page_count: Mapped[int] = mapped_column(
        Integer, nullable=False
    )
    reading_duration_minutes: Mapped[int] = mapped_column(
        Integer, nullable=False
    )
    cover_image_url: Mapped[Optional[str]] = mapped_column(
        String(1000), nullable=True
    )
    illustration_style: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="draft", server_default=text("'draft'")
    )
    story_bible: Mapped[Optional[dict]] = mapped_column(
        JSONB, nullable=True
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User", back_populates="stories"
    )
    pages: Mapped[List["Page"]] = relationship(
        "Page", back_populates="story", cascade="all, delete-orphan"
    )
    story_characters: Mapped[List["StoryCharacter"]] = relationship(
        "StoryCharacter", back_populates="story", cascade="all, delete-orphan"
    )
    generation_job: Mapped[Optional["GenerationJob"]] = relationship(
        "GenerationJob", back_populates="story", uselist=False, cascade="all, delete-orphan"
    )
    base_tale: Mapped[Optional["BaseTale"]] = relationship("BaseTale")
    genre: Mapped["Genre"] = relationship("Genre")
    world: Mapped["World"] = relationship("World")

    __table_args__ = (
        CheckConstraint(
            "age_range IN ('3-5', '6-8', '9-12')",
            name="ck_stories_age_range",
        ),
        CheckConstraint(
            "status IN ('draft', 'generating', 'completed', 'failed')",
            name="ck_stories_status",
        ),
        Index("ix_stories_user_id", "user_id"),
        Index("ix_stories_status", "status"),
    )


class StoryCharacter(Base):
    __tablename__ = "story_characters"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    story_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("stories.id", ondelete="CASCADE"),
        nullable=False,
    )
    character_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("characters.id", ondelete="CASCADE"),
        nullable=False,
    )
    role_in_story: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True
    )
    reference_image_url: Mapped[Optional[str]] = mapped_column(
        String(1000), nullable=True
    )

    # Relationships
    story: Mapped["Story"] = relationship(
        "Story", back_populates="story_characters"
    )
    character: Mapped["Character"] = relationship(
        "Character", back_populates="story_characters"
    )

    __table_args__ = (
        UniqueConstraint("story_id", "character_id", name="uq_story_characters_story_character"),
        Index("ix_story_characters_story_id", "story_id"),
        Index("ix_story_characters_character_id", "character_id"),
    )
