"""
Seed the catalog with genres, worlds, and base tales.
Run: python -m scripts.seed_catalog
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.database import async_session_factory, engine
from shared.models.genre import Genre
from shared.models.world import World
from shared.models.base_tale import BaseTale
from shared.models.base_tale_character import BaseTaleCharacter

GENRES = [
    {
        "slug": "adventure",
        "name_ru": "Приключения",
        "description_ru": "Захватывающие путешествия и открытия",
        "prompt_hint": "An adventure story with exciting journey, discoveries, and overcoming obstacles. Include vivid descriptions of landscapes and thrilling moments.",
        "sort_order": 1,
    },
    {
        "slug": "fairy-tale",
        "name_ru": "Волшебная сказка",
        "description_ru": "Магия, чудеса и волшебные превращения",
        "prompt_hint": "A magical fairy tale with enchantments, magical creatures, and wonderful transformations. Include elements of wonder and fantasy.",
        "sort_order": 2,
    },
    {
        "slug": "educational",
        "name_ru": "Познавательная",
        "description_ru": "Интересные факты об окружающем мире",
        "prompt_hint": "An educational story that teaches interesting facts about the world in an engaging narrative. Weave real knowledge into the plot naturally.",
        "sort_order": 3,
    },
    {
        "slug": "friendship",
        "name_ru": "О дружбе",
        "description_ru": "Истории о настоящей дружбе и взаимопомощи",
        "prompt_hint": "A heartwarming story about friendship, loyalty, and helping each other. Show how friends overcome challenges together.",
        "sort_order": 4,
    },
    {
        "slug": "funny",
        "name_ru": "Смешная история",
        "description_ru": "Весёлые и забавные приключения",
        "prompt_hint": "A funny and humorous story with comic situations, wordplay, and lighthearted adventures. Make the reader laugh.",
        "sort_order": 5,
    },
    {
        "slug": "bedtime",
        "name_ru": "Сказка на ночь",
        "description_ru": "Спокойная и уютная история перед сном",
        "prompt_hint": "A calm, soothing bedtime story with gentle imagery, soft descriptions, and a peaceful resolution. The story should help a child relax and feel safe.",
        "sort_order": 6,
    },
]

WORLDS = [
    {
        "slug": "enchanted-forest",
        "name_ru": "Волшебный лес",
        "description_ru": "Таинственный лес с говорящими животными и магическими существами",
        "prompt_hint": "Set in an enchanted forest with talking animals, magical creatures, ancient trees, and hidden clearings.",
        "visual_style_hint": "Lush green forest, dappled sunlight, mushrooms, fairy lights, woodland creatures. Studio Ghibli inspired, warm tones.",
        "sort_order": 1,
    },
    {
        "slug": "space",
        "name_ru": "Космос",
        "description_ru": "Далёкие планеты, звёзды и космические станции",
        "prompt_hint": "Set in outer space with planets, stars, space stations, alien worlds, and cosmic adventures.",
        "visual_style_hint": "Colorful nebulae, bright stars, futuristic space stations, friendly aliens, vibrant planets. Pixar-style, kid-friendly sci-fi.",
        "sort_order": 2,
    },
    {
        "slug": "underwater",
        "name_ru": "Подводный мир",
        "description_ru": "Морские глубины с коралловыми рифами и подводными городами",
        "prompt_hint": "Set in an underwater world with coral reefs, underwater cities, merfolk, and deep sea creatures.",
        "visual_style_hint": "Crystal clear blue water, colorful coral reefs, tropical fish, bioluminescent creatures. Bright, saturated underwater palette.",
        "sort_order": 3,
    },
    {
        "slug": "medieval-kingdom",
        "name_ru": "Сказочное королевство",
        "description_ru": "Замки, рыцари, принцессы и драконы",
        "prompt_hint": "Set in a medieval fantasy kingdom with castles, knights, princesses, dragons, and magical quests.",
        "visual_style_hint": "Fairytale castles, colorful banners, cobblestone streets, rolling green hills. Classic Disney storybook illustration style.",
        "sort_order": 4,
    },
    {
        "slug": "modern-city",
        "name_ru": "Современный город",
        "description_ru": "Знакомый мир: школа, парк, дом",
        "prompt_hint": "Set in a modern city with schools, parks, homes, and everyday settings that children recognize.",
        "visual_style_hint": "Friendly modern city, colorful buildings, parks with trees, playgrounds. Warm, inviting, relatable urban scenes.",
        "sort_order": 5,
    },
    {
        "slug": "dinosaur-world",
        "name_ru": "Мир динозавров",
        "description_ru": "Доисторический мир с динозаврами и вулканами",
        "prompt_hint": "Set in a prehistoric world with friendly dinosaurs, volcanoes, jungles, and ancient landscapes.",
        "visual_style_hint": "Lush prehistoric jungle, friendly cartoon dinosaurs, volcanic mountains, ferns and palm trees. Bright, adventurous palette.",
        "sort_order": 6,
    },
]

BASE_TALES = [
    {
        "slug": "kolobok",
        "name_ru": "Колобок",
        "summary_ru": "Круглый хлебец убегает от бабушки и дедушки, встречает зверей и поёт песенку",
        "plot_structure": {
            "setup": "Бабушка и дедушка испекли колобка, он остыл на окошке и убежал",
            "encounters": ["Заяц", "Волк", "Медведь", "Лиса"],
            "climax": "Лиса хитростью обманывает колобка",
            "moral": "Не стоит быть слишком самоуверенным и доверять незнакомцам"
        },
        "moral_ru": "Не будь слишком самоуверенным",
        "sort_order": 1,
    },
    {
        "slug": "teremok",
        "name_ru": "Теремок",
        "summary_ru": "Звери по очереди селятся в маленьком домике, пока он не разваливается",
        "plot_structure": {
            "setup": "В поле стоит маленький теремок",
            "encounters": ["Мышка", "Лягушка", "Зайчик", "Лисичка", "Волк", "Медведь"],
            "climax": "Медведь пытается залезть и теремок разваливается",
            "resolution": "Все вместе строят новый, большой теремок",
            "moral": "Вместе можно всё преодолеть"
        },
        "moral_ru": "Вместе мы сильнее",
        "sort_order": 2,
    },
    {
        "slug": "repka",
        "name_ru": "Репка",
        "summary_ru": "Дедушка не может вытащить огромную репку и зовёт на помощь",
        "plot_structure": {
            "setup": "Посадил дед репку, выросла репка большая-пребольшая",
            "encounters": ["Бабка", "Внучка", "Жучка", "Кошка", "Мышка"],
            "climax": "Все тянут вместе и наконец вытаскивают репку",
            "moral": "Даже маленькая помощь может стать решающей"
        },
        "moral_ru": "Каждый вклад важен",
        "sort_order": 3,
    },
]


async def seed():
    async with async_session_factory() as db:
        # --- Genres ---
        for data in GENRES:
            genre = Genre(**data)
            db.add(genre)
        print(f"Added {len(GENRES)} genres")

        # --- Worlds ---
        for data in WORLDS:
            world = World(**data)
            db.add(world)
        print(f"Added {len(WORLDS)} worlds")

        # --- Base Tales ---
        for data in BASE_TALES:
            tale = BaseTale(**data)
            db.add(tale)
        print(f"Added {len(BASE_TALES)} base tales")

        await db.commit()
        print("Catalog seeded successfully!")


if __name__ == "__main__":
    asyncio.run(seed())
