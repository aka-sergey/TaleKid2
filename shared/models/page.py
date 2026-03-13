import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from shared.models.base import Base


class Page(Base):
    __tablename__ = "pages"

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
    page_number: Mapped[int] = mapped_column(
        Integer, nullable=False
    )
    text_content: Mapped[str] = mapped_column(
        Text, nullable=False
    )
    image_url: Mapped[Optional[str]] = mapped_column(
        String(1000), nullable=True
    )
    image_s3_key: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True
    )
    image_prompt: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )
    scene_description: Mapped[Optional[dict]] = mapped_column(
        JSONB, nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationships
    story: Mapped["Story"] = relationship(
        "Story", back_populates="pages"
    )
    educational_content: Mapped[Optional["EducationalContent"]] = relationship(
        "EducationalContent", back_populates="page", uselist=False, cascade="all, delete-orphan"
    )

    __table_args__ = (
        UniqueConstraint("story_id", "page_number", name="uq_pages_story_page_number"),
        Index("ix_pages_story_id", "story_id"),
    )


class EducationalContent(Base):
    __tablename__ = "educational_content"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    page_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("pages.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    content_type: Mapped[str] = mapped_column(
        String(20), nullable=False
    )
    text_ru: Mapped[str] = mapped_column(
        Text, nullable=False
    )
    answer_ru: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )
    topic: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True
    )

    # Relationships
    page: Mapped["Page"] = relationship(
        "Page", back_populates="educational_content"
    )

    __table_args__ = (
        CheckConstraint(
            "content_type IN ('fact', 'question')",
            name="ck_educational_content_content_type",
        ),
        Index("ix_educational_content_page_id", "page_id"),
    )
