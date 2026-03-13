from typing import List, Optional

from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, String, Text, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from shared.models.base import Base


class BaseTale(Base):
    __tablename__ = "base_tales"

    id: Mapped[int] = mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    slug: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False
    )
    name_ru: Mapped[str] = mapped_column(
        String(200), nullable=False
    )
    summary_ru: Mapped[str] = mapped_column(
        Text, nullable=False
    )
    plot_structure: Mapped[dict] = mapped_column(
        JSONB, nullable=False
    )
    moral_ru: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )
    icon_url: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True
    )
    sort_order: Mapped[int] = mapped_column(
        Integer, default=0, server_default=text("0"), nullable=False
    )

    # Relationships
    characters: Mapped[List["BaseTaleCharacter"]] = relationship(
        "BaseTaleCharacter", back_populates="base_tale", cascade="all, delete-orphan"
    )


class BaseTaleCharacter(Base):
    __tablename__ = "base_tale_characters"

    id: Mapped[int] = mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    base_tale_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("base_tales.id", ondelete="CASCADE"),
        nullable=False,
    )
    name_ru: Mapped[str] = mapped_column(
        String(100), nullable=False
    )
    role: Mapped[str] = mapped_column(
        String(50), nullable=False
    )
    appearance_prompt: Mapped[str] = mapped_column(
        Text, nullable=False
    )
    personality_ru: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )
    sort_order: Mapped[int] = mapped_column(
        Integer, default=0, server_default=text("0"), nullable=False
    )

    # Relationships
    base_tale: Mapped["BaseTale"] = relationship(
        "BaseTale", back_populates="characters"
    )

    __table_args__ = (
        CheckConstraint(
            "role IN ('protagonist', 'antagonist', 'helper', 'secondary')",
            name="ck_base_tale_characters_role",
        ),
        Index("ix_base_tale_characters_base_tale_id", "base_tale_id"),
    )
