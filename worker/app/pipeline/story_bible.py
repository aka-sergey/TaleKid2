"""
Stage 2: Story Bible Generation
- Combine character descriptions, genre, world, base tale (if any)
- Generate a comprehensive story bible via OpenAI
- Store as JSONB in story.story_bible
- Progress: 15% -> 30%
"""
import json
import logging

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from shared.models.story import Story
from shared.models.genre import Genre
from shared.models.world import World
from shared.models.base_tale import BaseTale
from app.services.openai_service import OpenAIService
from app.pipeline.base import PipelineContext, PipelineStage

logger = logging.getLogger("worker.pipeline.story_bible")

SYSTEM_PROMPT = """You are a master children's storyteller. Create a detailed story bible (plan) for a personalized fairy tale.

Output valid JSON with this structure:
{
  "title_working": "Working title in Russian",
  "tone": "Description of the story's tone and mood",
  "setting_description": "Detailed description of the world/setting",
  "character_roles": [
    {
      "character_id": "uuid",
      "name": "Name",
      "role": "protagonist/antagonist/helper/secondary",
      "arc": "Brief character arc description in Russian"
    }
  ],
  "plot_outline": [
    {"act": 1, "summary": "Act 1 summary in Russian", "key_events": ["event1", "event2"]},
    {"act": 2, "summary": "Act 2 summary in Russian", "key_events": ["event1", "event2"]},
    {"act": 3, "summary": "Act 3 summary in Russian", "key_events": ["event1", "event2"]}
  ],
  "themes": ["theme1", "theme2"],
  "moral": "Story moral in Russian",
  "vocabulary_level": "simple/moderate/advanced",
  "visual_style": "Description of the illustration style to maintain consistency"
}"""


class StoryBibleStage(PipelineStage):
    stage_name = "story_bible"
    stage_status = "story_bible"
    progress_start = 15
    progress_end = 30

    def __init__(self, db, redis, openai: OpenAIService):
        super().__init__(db, redis)
        self.openai = openai

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 15, "Создаём план сказки...")

        # Load story with relationships
        result = await self.db.execute(
            select(Story)
            .where(Story.id == ctx.story_id)
            .options(
                selectinload(Story.genre),
                selectinload(Story.world),
                selectinload(Story.base_tale),
                selectinload(Story.story_characters),
            )
        )
        story = result.scalar_one()

        # Build the prompt
        user_prompt = self._build_prompt(story, ctx)

        await self.update_progress(ctx, 20, "ИИ придумывает сюжет...")

        raw = await self.openai.chat_json(SYSTEM_PROMPT, user_prompt, max_tokens=3000)

        try:
            story_bible = json.loads(raw)
        except json.JSONDecodeError:
            logger.error("Failed to parse story bible JSON, retrying...")
            raw = await self.openai.chat_json(
                SYSTEM_PROMPT,
                user_prompt + "\n\nIMPORTANT: Return ONLY valid JSON.",
                max_tokens=3000,
            )
            story_bible = json.loads(raw)

        # Save to DB
        story.story_bible = story_bible

        # Update character roles from the bible
        if "character_roles" in story_bible:
            for role_info in story_bible["character_roles"]:
                for sc in story.story_characters:
                    if str(sc.character_id) == role_info.get("character_id"):
                        sc.role_in_story = role_info.get("role", "secondary")

        await self.db.commit()
        ctx.story_bible = story_bible

        await self.update_progress(ctx, 30, "План сказки готов!")

    def _build_prompt(self, story, ctx: PipelineContext) -> str:
        parts = []

        # Age and education
        age_labels = {
            "3-5": "3-5 лет (простые слова, короткие предложения)",
            "6-8": "6-8 лет (более сложные слова, развёрнутые предложения)",
            "9-12": "9-12 лет (богатая лексика, сложный сюжет)",
        }
        parts.append(f"Возрастная группа: {age_labels.get(story.age_range, story.age_range)}")
        parts.append(f"Уровень образовательности: {story.education_level:.0%}")
        parts.append(f"Количество страниц: {story.page_count}")
        parts.append(f"Время чтения: {story.reading_duration_minutes} минут")

        # Genre
        if story.genre:
            parts.append(f"Жанр: {story.genre.name_ru}")
            if story.genre.prompt_hint:
                parts.append(f"Подсказка жанра: {story.genre.prompt_hint}")

        # World
        if story.world:
            parts.append(f"Мир/Сеттинг: {story.world.name_ru}")
            if story.world.prompt_hint:
                parts.append(f"Подсказка мира: {story.world.prompt_hint}")

        # Base tale
        if story.base_tale:
            parts.append(f"Сказка-основа: {story.base_tale.name_ru}")
            if story.base_tale.summary_ru:
                parts.append(f"Краткое содержание основы: {story.base_tale.summary_ru}")
            if story.base_tale.moral_ru:
                parts.append(f"Мораль основы: {story.base_tale.moral_ru}")
            if story.base_tale.plot_structure:
                parts.append(
                    f"Структура сюжета основы: "
                    f"{json.dumps(story.base_tale.plot_structure, ensure_ascii=False)}"
                )

        # Illustration style
        if ctx.illustration_style:
            from shared.constants import STYLE_PROMPTS
            style_desc = STYLE_PROMPTS.get(
                ctx.illustration_style,
                ctx.illustration_style
            )
            parts.append(
                f"\nСтиль иллюстраций (выбор пользователя): {ctx.illustration_style}"
            )
            parts.append(
                f"Описание стиля для иллюстраций: {style_desc}"
            )
            parts.append(
                "ВАЖНО: Поле visual_style в JSON должно точно описывать этот стиль."
            )

        # Characters
        parts.append("\nПерсонажи (пользователь добавил своих):")
        for char_id, description in ctx.character_descriptions.items():
            parts.append(f"- ID: {char_id}, Описание: {description}")

        return "\n".join(parts)
