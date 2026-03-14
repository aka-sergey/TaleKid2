import logging
import sys
from contextlib import asynccontextmanager
from pathlib import Path

# Make shared package importable
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from sqlalchemy import select, func

from app.core.middleware import RequestLoggingMiddleware
from app.database import engine, async_session_factory
from app.routers import auth, catalog, characters, generation, health, stories
from shared.models.base import Base
from shared.models.genre import Genre
from shared.models.world import World

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s %(name)s  %(message)s",
)
logger = logging.getLogger("talekid")


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables if they do not exist (dev convenience; Alembic is the
    # canonical migration tool for production).
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables verified / created")

    # Auto-seed catalog if empty
    await _seed_catalog_if_empty()

    yield
    await engine.dispose()
    logger.info("Database engine disposed")


async def _seed_catalog_if_empty():
    """Insert default genres and worlds if the tables are empty."""
    async with async_session_factory() as db:
        count = await db.scalar(select(func.count()).select_from(Genre))
        if count and count > 0:
            logger.info("Catalog already seeded (%d genres)", count)
            return

        genres = [
            Genre(slug="adventure", name_ru="Приключения", description_ru="Захватывающие путешествия и открытия", prompt_hint="An adventure story with exciting journey, discoveries, and overcoming obstacles. Include vivid descriptions of landscapes and thrilling moments.", sort_order=1),
            Genre(slug="fairy-tale", name_ru="Волшебная сказка", description_ru="Магия, чудеса и волшебные превращения", prompt_hint="A magical fairy tale with enchantments, magical creatures, and wonderful transformations. Include elements of wonder and fantasy.", sort_order=2),
            Genre(slug="educational", name_ru="Познавательная", description_ru="Интересные факты об окружающем мире", prompt_hint="An educational story that teaches interesting facts about the world in an engaging narrative. Weave real knowledge into the plot naturally.", sort_order=3),
            Genre(slug="friendship", name_ru="О дружбе", description_ru="Истории о настоящей дружбе и взаимопомощи", prompt_hint="A heartwarming story about friendship, loyalty, and helping each other. Show how friends overcome challenges together.", sort_order=4),
            Genre(slug="funny", name_ru="Смешная история", description_ru="Весёлые и забавные приключения", prompt_hint="A funny and humorous story with comic situations, wordplay, and lighthearted adventures.", sort_order=5),
            Genre(slug="bedtime", name_ru="Сказка на ночь", description_ru="Спокойная и уютная история перед сном", prompt_hint="A calm, soothing bedtime story with gentle imagery, soft descriptions, and a peaceful resolution.", sort_order=6),
        ]

        worlds = [
            World(slug="enchanted-forest", name_ru="Волшебный лес", description_ru="Таинственный лес с говорящими животными", prompt_hint="Set in an enchanted forest with talking animals, magical creatures, ancient trees, and hidden clearings.", visual_style_hint="Lush green forest, dappled sunlight, mushrooms, fairy lights. Studio Ghibli inspired, warm tones.", sort_order=1),
            World(slug="space", name_ru="Космос", description_ru="Далёкие планеты, звёзды и космические станции", prompt_hint="Set in outer space with planets, stars, space stations, and cosmic adventures.", visual_style_hint="Colorful nebulae, bright stars, futuristic space stations, friendly aliens. Pixar-style, kid-friendly sci-fi.", sort_order=2),
            World(slug="underwater", name_ru="Подводный мир", description_ru="Морские глубины с коралловыми рифами", prompt_hint="Set in an underwater world with coral reefs, underwater cities, merfolk, and deep sea creatures.", visual_style_hint="Crystal clear blue water, colorful coral reefs, tropical fish, bioluminescent creatures.", sort_order=3),
            World(slug="medieval-kingdom", name_ru="Сказочное королевство", description_ru="Замки, рыцари, принцессы и драконы", prompt_hint="Set in a medieval fantasy kingdom with castles, knights, princesses, dragons.", visual_style_hint="Fairytale castles, colorful banners, cobblestone streets. Classic Disney storybook style.", sort_order=4),
            World(slug="modern-city", name_ru="Современный город", description_ru="Знакомый мир: школа, парк, дом", prompt_hint="Set in a modern city with schools, parks, homes, and everyday settings.", visual_style_hint="Friendly modern city, colorful buildings, parks with trees, playgrounds. Warm, inviting.", sort_order=5),
            World(slug="dinosaur-world", name_ru="Мир динозавров", description_ru="Доисторический мир с динозаврами и вулканами", prompt_hint="Set in a prehistoric world with friendly dinosaurs, volcanoes, jungles.", visual_style_hint="Lush prehistoric jungle, friendly cartoon dinosaurs, volcanic mountains. Bright, adventurous.", sort_order=6),
        ]

        db.add_all(genres + worlds)
        await db.commit()
        logger.info("Catalog seeded: %d genres, %d worlds", len(genres), len(worlds))


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="TaleKID API",
    version="1.0.0",
    lifespan=lifespan,
)

# -- CORS ------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Will be restricted in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -- Request logging -------------------------------------------------------
app.add_middleware(RequestLoggingMiddleware)

# -- Routers ---------------------------------------------------------------
app.include_router(auth.router, prefix="/api/v1")
app.include_router(health.router, prefix="/api/v1")
app.include_router(characters.router, prefix="/api/v1")
app.include_router(catalog.router, prefix="/api/v1")
app.include_router(generation.router, prefix="/api/v1")
app.include_router(stories.router, prefix="/api/v1")
