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
from shared.models.base_tale import BaseTale, BaseTaleCharacter
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

    # Seed base tales if empty
    await _seed_base_tales_if_empty()


async def _seed_base_tales_if_empty():
    """Insert a small set of popular base tales if the table is empty."""
    async with async_session_factory() as db:
        count = await db.scalar(select(func.count()).select_from(BaseTale))
        if count and count > 0:
            logger.info("Base tales already seeded (%d tales)", count)
            return

        tales_data = [
            {
                "slug": "little-red-riding-hood",
                "name_ru": "Красная Шапочка",
                "summary_ru": "Девочка идёт через лес к бабушке, но встречает хитрого волка.",
                "plot_structure": {"act1": "Мама отправляет Красную Шапочку к бабушке с пирожками.", "act2": "В лесу она встречает волка, который обманом опережает её.", "act3": "Охотник спасает бабушку и Красную Шапочку."},
                "moral_ru": "Не разговаривай с незнакомцами и слушай родителей.",
                "sort_order": 1,
                "characters": [
                    {"name_ru": "Красная Шапочка", "role": "protagonist", "appearance_prompt": "A young girl in a red hooded cape, carrying a basket", "personality_ru": "Добрая и доверчивая девочка", "sort_order": 1},
                    {"name_ru": "Волк", "role": "antagonist", "appearance_prompt": "A big gray wolf with cunning eyes", "personality_ru": "Хитрый и коварный", "sort_order": 2},
                    {"name_ru": "Бабушка", "role": "secondary", "appearance_prompt": "An elderly woman in a nightgown and cap", "personality_ru": "Добрая и любящая бабушка", "sort_order": 3},
                ],
            },
            {
                "slug": "three-little-pigs",
                "name_ru": "Три поросёнка",
                "summary_ru": "Три брата-поросёнка строят дома, но только самый трудолюбивый строит крепкий кирпичный дом.",
                "plot_structure": {"act1": "Три поросёнка решают построить свои домики.", "act2": "Волк легко сдувает домики из соломы и веток.", "act3": "Кирпичный домик третьего поросёнка выдерживает, и братья побеждают волка."},
                "moral_ru": "Трудолюбие и основательность всегда вознаграждаются.",
                "sort_order": 2,
                "characters": [
                    {"name_ru": "Наф-Наф", "role": "protagonist", "appearance_prompt": "A smart pig wearing overalls and a hard hat", "personality_ru": "Трудолюбивый и разумный поросёнок", "sort_order": 1},
                    {"name_ru": "Ниф-Ниф", "role": "secondary", "appearance_prompt": "A playful pig in a straw hat", "personality_ru": "Весёлый и легкомысленный", "sort_order": 2},
                    {"name_ru": "Нуф-Нуф", "role": "secondary", "appearance_prompt": "A carefree pig playing a flute", "personality_ru": "Беззаботный и ленивый", "sort_order": 3},
                ],
            },
            {
                "slug": "cinderella",
                "name_ru": "Золушка",
                "summary_ru": "Добрая девушка с помощью волшебства попадает на бал, где встречает принца.",
                "plot_structure": {"act1": "Золушка живёт с мачехой и сёстрами, мечтая о бале.", "act2": "Фея-крёстная помогает ей попасть на бал, но волшебство заканчивается в полночь.", "act3": "Принц находит Золушку по хрустальной туфельке."},
                "moral_ru": "Доброта и терпение всегда вознаграждаются.",
                "sort_order": 3,
                "characters": [
                    {"name_ru": "Золушка", "role": "protagonist", "appearance_prompt": "A beautiful young girl in a ball gown with glass slippers", "personality_ru": "Добрая, трудолюбивая и мечтательная", "sort_order": 1},
                    {"name_ru": "Принц", "role": "secondary", "appearance_prompt": "A handsome prince in royal attire", "personality_ru": "Благородный и романтичный", "sort_order": 2},
                    {"name_ru": "Фея-крёстная", "role": "helper", "appearance_prompt": "A kind fairy godmother with a magic wand and sparkly dress", "personality_ru": "Мудрая и волшебная", "sort_order": 3},
                ],
            },
            {
                "slug": "kolobok",
                "name_ru": "Колобок",
                "summary_ru": "Круглый румяный Колобок убегает от бабушки с дедушкой и встречает разных зверей.",
                "plot_structure": {"act1": "Бабушка испекла Колобка, а он убежал.", "act2": "Колобок встречает зайца, волка и медведя, от всех уходит с песенкой.", "act3": "Хитрая лиса обманывает Колобка."},
                "moral_ru": "Не стоит быть слишком самоуверенным.",
                "sort_order": 4,
                "characters": [
                    {"name_ru": "Колобок", "role": "protagonist", "appearance_prompt": "A round golden bread bun with a smiling face, arms and legs", "personality_ru": "Весёлый и самоуверенный", "sort_order": 1},
                    {"name_ru": "Лиса", "role": "antagonist", "appearance_prompt": "A cunning red fox with a bushy tail", "personality_ru": "Хитрая и льстивая", "sort_order": 2},
                ],
            },
            {
                "slug": "snow-queen",
                "name_ru": "Снежная Королева",
                "summary_ru": "Девочка Герда отправляется на поиски названного брата Кая, которого похитила Снежная Королева.",
                "plot_structure": {"act1": "Осколок зеркала попадает Каю в глаз, и Снежная Королева увозит его.", "act2": "Герда проходит через множество испытаний, ища Кая.", "act3": "Любовь Герды растапливает ледяное сердце Кая."},
                "moral_ru": "Любовь и верность сильнее любого зла.",
                "sort_order": 5,
                "characters": [
                    {"name_ru": "Герда", "role": "protagonist", "appearance_prompt": "A brave young girl in warm clothing, with determination in her eyes", "personality_ru": "Смелая, верная и любящая", "sort_order": 1},
                    {"name_ru": "Кай", "role": "secondary", "appearance_prompt": "A boy with an icy expression, sitting in an ice palace", "personality_ru": "Добрый мальчик, заколдованный льдом", "sort_order": 2},
                    {"name_ru": "Снежная Королева", "role": "antagonist", "appearance_prompt": "A tall majestic ice queen in a sparkling white gown with a crown of ice crystals", "personality_ru": "Холодная и величественная", "sort_order": 3},
                ],
            },
            {
                "slug": "masha-and-bear",
                "name_ru": "Маша и Медведь",
                "summary_ru": "Маша заблудилась в лесу и попала в дом медведя, но нашла способ вернуться домой.",
                "plot_structure": {"act1": "Маша идёт в лес за грибами и ягодами и теряется.", "act2": "Она попадает в избушку медведя, который не хочет её отпускать.", "act3": "Маша придумывает хитрость — прячется в коробе с пирожками, и медведь сам несёт её домой."},
                "moral_ru": "Смекалка и находчивость помогут выбраться из любой ситуации.",
                "sort_order": 6,
                "characters": [
                    {"name_ru": "Маша", "role": "protagonist", "appearance_prompt": "A clever young girl with a headscarf and a playful expression", "personality_ru": "Находчивая и хитрая", "sort_order": 1},
                    {"name_ru": "Медведь", "role": "secondary", "appearance_prompt": "A large brown bear with a kind but stern face", "personality_ru": "Добродушный, но упрямый", "sort_order": 2},
                ],
            },
        ]

        for td in tales_data:
            chars_data = td.pop("characters")
            tale = BaseTale(**td)
            db.add(tale)
            await db.flush()
            for cd in chars_data:
                db.add(BaseTaleCharacter(base_tale_id=tale.id, **cd))

        await db.commit()
        logger.info("Base tales seeded: %d tales", len(tales_data))


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="TaleKID API",
    version="1.0.0",
    lifespan=lifespan,
)

# -- CORS ------------------------------------------------------------------
# NOTE: allow_origins=["*"] + allow_credentials=True is invalid per the CORS
# spec — browsers block responses (even 401/403) when this combo is returned,
# causing Dio to see connectionError instead of the actual HTTP error.
# Always list explicit origins with allow_credentials=True.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://talekid2-production.up.railway.app",
        "https://talekid.ai",
        "https://www.talekid.ai",
    ],
    allow_origin_regex=r"http://localhost:\d+",  # Any localhost port for dev
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
