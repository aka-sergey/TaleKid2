from typing import Optional

from sqlalchemy import Integer, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from shared.models.base import Base


class World(Base):
    __tablename__ = "worlds"

    id: Mapped[int] = mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    slug: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False
    )
    name_ru: Mapped[str] = mapped_column(
        String(100), nullable=False
    )
    description_ru: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )
    prompt_hint: Mapped[str] = mapped_column(
        Text, nullable=False
    )
    visual_style_hint: Mapped[str] = mapped_column(
        Text, nullable=False
    )
    icon_url: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True
    )
    sort_order: Mapped[int] = mapped_column(
        Integer, default=0, server_default=text("0"), nullable=False
    )
