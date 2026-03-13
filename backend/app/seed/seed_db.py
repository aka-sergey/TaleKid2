"""
Seed script for the TaleKID database.

Reads genres.json, worlds.json, and base_tales.json from the seed directory
and performs upsert operations (check by slug, update if exists, create if not).

Usage:
    python -m app.seed.seed_db
"""

import asyncio
import json
import logging
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Make shared package importable when invoked via `python -m app.seed.seed_db`
# from the backend/ directory.
# ---------------------------------------------------------------------------
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from sqlalchemy import select

from app.database import async_session_factory
from shared.models.base_tale import BaseTale, BaseTaleCharacter
from shared.models.genre import Genre
from shared.models.world import World

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)-8s %(message)s")
logger = logging.getLogger("seed")

SEED_DIR = Path(__file__).resolve().parent


def _load_json(name: str) -> list[dict]:
    """Load a JSON file from the seed directory and return its contents."""
    path = SEED_DIR / name
    if not path.exists():
        logger.warning("Seed file %s not found – skipping", path)
        return []
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


async def _seed_genres(session) -> None:
    data = _load_json("genres.json")
    if not data:
        return

    for item in data:
        slug = item["slug"]
        result = await session.execute(select(Genre).where(Genre.slug == slug))
        existing = result.scalar_one_or_none()

        if existing:
            for key, value in item.items():
                setattr(existing, key, value)
            logger.info("Updated genre: %s", slug)
        else:
            session.add(Genre(**item))
            logger.info("Created genre: %s", slug)

    await session.flush()


async def _seed_worlds(session) -> None:
    data = _load_json("worlds.json")
    if not data:
        return

    for item in data:
        slug = item["slug"]
        result = await session.execute(select(World).where(World.slug == slug))
        existing = result.scalar_one_or_none()

        if existing:
            for key, value in item.items():
                setattr(existing, key, value)
            logger.info("Updated world: %s", slug)
        else:
            session.add(World(**item))
            logger.info("Created world: %s", slug)

    await session.flush()


async def _seed_base_tales(session) -> None:
    data = _load_json("base_tales.json")
    if not data:
        return

    for item in data:
        slug = item["slug"]
        characters_data = item.pop("characters", [])

        result = await session.execute(select(BaseTale).where(BaseTale.slug == slug))
        existing = result.scalar_one_or_none()

        if existing:
            for key, value in item.items():
                setattr(existing, key, value)
            logger.info("Updated base tale: %s", slug)

            # Remove old characters and re-create
            await session.execute(
                select(BaseTaleCharacter).where(
                    BaseTaleCharacter.base_tale_id == existing.id
                )
            )
            # Delete existing characters for this tale
            from sqlalchemy import delete
            await session.execute(
                delete(BaseTaleCharacter).where(
                    BaseTaleCharacter.base_tale_id == existing.id
                )
            )
            await session.flush()

            for char_data in characters_data:
                session.add(BaseTaleCharacter(base_tale_id=existing.id, **char_data))
        else:
            tale = BaseTale(**item)
            session.add(tale)
            await session.flush()

            for char_data in characters_data:
                session.add(BaseTaleCharacter(base_tale_id=tale.id, **char_data))

            logger.info("Created base tale: %s", slug)

    await session.flush()


async def seed() -> None:
    """Run all seed operations inside a single transaction."""
    async with async_session_factory() as session:
        async with session.begin():
            await _seed_genres(session)
            await _seed_worlds(session)
            await _seed_base_tales(session)
        logger.info("Seed completed successfully")


if __name__ == "__main__":
    asyncio.run(seed())
