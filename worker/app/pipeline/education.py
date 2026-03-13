"""
Stage 7: Educational Content Generation
- For each page, generate educational content (fact or question)
- Based on education_level: higher = more educational content
- Content types: 'fact' (interesting fact) or 'question' (quiz question with answer)
- Progress: 90% → 93%
"""

import json
import logging
import random

from sqlalchemy import select

from shared.models.page import EducationalContent, Page
from shared.models.story import Story

from app.pipeline.base import PipelineContext, PipelineStage
from app.services.openai_service import OpenAIService

logger = logging.getLogger("worker.pipeline.education")

SYSTEM_PROMPT = """You are an expert children's educator. Based on a fairy tale page text, generate educational content in Russian that is age-appropriate and engaging.

Output valid JSON:
{
  "content_type": "fact" or "question",
  "text_ru": "The educational fact or question in Russian",
  "answer_ru": "Answer in Russian (only for questions, null for facts)",
  "topic": "Short topic label in Russian (e.g., 'Природа', 'Математика', 'История')"
}

Rules:
- Facts should be surprising and related to the story context
- Questions should be answerable by the target age group
- Topics should be diverse across pages (nature, science, geography, history, math, language, art)
- Everything must be in Russian
- Keep facts to 1-2 sentences
- Questions should be clear and have a definitive answer"""


class EducationStage(PipelineStage):
    stage_name = "education"
    stage_status = "education"
    progress_start = 90
    progress_end = 93

    def __init__(self, db, redis, openai: OpenAIService):
        super().__init__(db, redis)
        self.openai = openai

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 90, "Добавляем образовательный контент...")

        # Get story for education_level
        result = await self.db.execute(
            select(Story).where(Story.id == ctx.story_id)
        )
        story = result.scalar_one()
        education_level = story.education_level  # 0.0 to 1.0

        # Get pages
        result = await self.db.execute(
            select(Page)
            .where(Page.story_id == ctx.story_id)
            .order_by(Page.page_number)
        )
        pages = result.scalars().all()
        total = len(pages)

        if total == 0:
            await self.update_progress(ctx, 93, "Нет страниц для обучения")
            return

        # Determine which pages get educational content
        # education_level 0.0 = ~20% of pages, 1.0 = ~100% of pages
        target_count = max(1, int(total * (0.2 + 0.8 * education_level)))
        # Always include content on random pages, spread evenly
        if target_count >= total:
            selected_indices = list(range(total))
        else:
            step = total / target_count
            selected_indices = [int(i * step) for i in range(target_count)]

        # Alternate between facts and questions
        used_topics = set()

        for idx, page_idx in enumerate(selected_indices):
            page = pages[page_idx]

            # Alternate type, with slight preference for facts
            content_type = "fact" if idx % 3 != 2 else "question"

            user_prompt = (
                f"Age group: {story.age_range}\n"
                f"Page {page.page_number} text:\n{page.text_content[:500]}\n\n"
                f"Generate a '{content_type}' type educational content.\n"
                f"Already used topics: {', '.join(used_topics) if used_topics else 'none'}\n"
                f"Please choose a DIFFERENT topic."
            )

            try:
                raw = await self.openai.chat_json(
                    SYSTEM_PROMPT, user_prompt, max_tokens=500
                )
                data = json.loads(raw)

                edu = EducationalContent(
                    page_id=page.id,
                    content_type=data.get("content_type", content_type),
                    text_ru=data["text_ru"],
                    answer_ru=data.get("answer_ru"),
                    topic=data.get("topic"),
                )
                self.db.add(edu)

                if data.get("topic"):
                    used_topics.add(data["topic"])

            except Exception as e:
                logger.warning(
                    "Education content failed for page %d: %s",
                    page.page_number,
                    e,
                )

            pct = self.progress_start + int(
                (idx + 1) / len(selected_indices) * (self.progress_end - self.progress_start)
            )
            await self.update_progress(
                ctx, pct, f"Образовательный контент {idx + 1}/{len(selected_indices)}..."
            )

        await self.db.commit()
        logger.info(
            "Educational content created for %d/%d pages",
            len(selected_indices),
            total,
        )
