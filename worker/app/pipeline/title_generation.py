"""
Stage 8: Title Generation
- Generate a catchy Russian title for the story
- Based on the story bible, text, and characters
- Save as story.title_suggested
- Progress: 93% → 96%
"""

import json
import logging

from sqlalchemy import select, update

from shared.models.story import Story

from app.pipeline.base import PipelineContext, PipelineStage
from app.services.openai_service import OpenAIService

logger = logging.getLogger("worker.pipeline.title")

SYSTEM_PROMPT = """You are a creative Russian children's book title specialist.

Generate a captivating title for a fairy tale in Russian. The title should be:
- Short (2-6 words)
- Memorable and catchy
- Age-appropriate
- Reflecting the story's theme and characters
- In Russian

Also generate 2 alternative titles.

Output valid JSON:
{
  "title": "Main title in Russian",
  "alternatives": ["Alternative 1", "Alternative 2"]
}"""


class TitleGenerationStage(PipelineStage):
    stage_name = "title_generation"
    stage_status = "title_generation"
    progress_start = 93
    progress_end = 96

    def __init__(self, db, redis, openai: OpenAIService):
        super().__init__(db, redis)
        self.openai = openai

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 93, "Придумываем название...")

        bible = ctx.story_bible or {}

        # Build prompt from story bible and first/last page text
        parts = []

        if bible.get("title_working"):
            parts.append(f"Working title: {bible['title_working']}")
        if bible.get("themes"):
            parts.append(f"Themes: {', '.join(bible['themes'])}")
        if bible.get("moral"):
            parts.append(f"Moral: {bible['moral']}")
        if bible.get("tone"):
            parts.append(f"Tone: {bible['tone']}")

        # Add character names
        char_names = []
        for char_id, desc in ctx.character_descriptions.items():
            char_names.append(desc.split(",")[0] if "," in desc else desc[:50])
        if char_names:
            parts.append(f"Characters: {', '.join(char_names[:4])}")

        # Add first page text for context
        if ctx.pages_text:
            first_page = ctx.pages_text[0].get("text_content", "")
            parts.append(f"\nFirst page:\n{first_page[:300]}")

            if len(ctx.pages_text) > 1:
                last_page = ctx.pages_text[-1].get("text_content", "")
                parts.append(f"\nLast page:\n{last_page[:300]}")

        user_prompt = "\n".join(parts)

        try:
            raw = await self.openai.chat_json(
                SYSTEM_PROMPT, user_prompt, max_tokens=300
            )
            data = json.loads(raw)
            title = data.get("title", "Сказка")

            # Save title
            await self.db.execute(
                update(Story)
                .where(Story.id == ctx.story_id)
                .values(title_suggested=title)
            )
            await self.db.commit()

            logger.info("Generated title: %s", title)

        except Exception as e:
            logger.warning("Title generation failed: %s, using fallback", e)
            await self.db.execute(
                update(Story)
                .where(Story.id == ctx.story_id)
                .values(title_suggested="Волшебная сказка")
            )
            await self.db.commit()

        await self.update_progress(ctx, 96, "Название готово!")
