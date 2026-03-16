"""
Stage 3: Text Generation
- Using the story bible, generate text for each page
- Each page should be age-appropriate length
- Text in Russian
- Progress: 30% -> 55%
"""
import json
import logging

from sqlalchemy import select

from shared.models.story import Story
from shared.models.page import Page
from app.services.openai_service import OpenAIService
from app.pipeline.base import PipelineContext, PipelineStage

logger = logging.getLogger("worker.pipeline.text_generation")

SYSTEM_PROMPT = """You are a talented Russian children's book author. Write fairy tale text in Russian.

Rules:
- Write ONLY in Russian
- Use age-appropriate vocabulary and sentence complexity
- Each page should be a self-contained scene that can be illustrated
- Maintain consistent character voices and story tone
- Include dialogue where appropriate
- End each page naturally so the reader wants to turn to the next one
- The last page should provide a satisfying conclusion

Output valid JSON:
{
  "text_content": "The story text for this page in Russian",
  "suggested_illustration": "Brief English description of what should be illustrated on this page"
}"""


class TextGenerationStage(PipelineStage):
    stage_name = "text_generation"
    stage_status = "text_generation"
    progress_start = 30
    progress_end = 55

    def __init__(self, db, redis, openai: OpenAIService):
        super().__init__(db, redis)
        self.openai = openai

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 30, "Начинаем писать сказку...")

        # Get story details
        result = await self.db.execute(select(Story).where(Story.id == ctx.story_id))
        story = result.scalar_one()

        page_count = story.page_count
        bible = ctx.story_bible or {}

        # Calculate text length per page based on age and reading time
        words_per_page = self._calculate_words_per_page(
            story.age_range, story.reading_duration_minutes, page_count
        )

        previous_pages = []
        for page_num in range(1, page_count + 1):
            user_prompt = self._build_page_prompt(
                page_num, page_count, bible, previous_pages, words_per_page,
                story.age_range, ctx.user_context
            )

            pct = self.progress_start + int(
                page_num / page_count * (self.progress_end - self.progress_start)
            )
            await self.update_progress(
                ctx, pct, f"Пишем страницу {page_num}/{page_count}..."
            )

            raw = await self.openai.chat_json(SYSTEM_PROMPT, user_prompt, max_tokens=1500)

            try:
                page_data = json.loads(raw)
            except json.JSONDecodeError:
                # Retry once
                raw = await self.openai.chat_json(
                    SYSTEM_PROMPT,
                    user_prompt + "\n\nReturn ONLY valid JSON.",
                    max_tokens=1500,
                )
                page_data = json.loads(raw)

            text_content = page_data.get("text_content", "")
            suggested_illustration = page_data.get("suggested_illustration", "")

            # Create page in DB
            page = Page(
                story_id=ctx.story_id,
                page_number=page_num,
                text_content=text_content,
                image_prompt=suggested_illustration,
            )
            self.db.add(page)
            await self.db.flush()

            previous_pages.append({"page_number": page_num, "text": text_content})
            ctx.pages_text.append({
                "page_number": page_num,
                "text_content": text_content,
                "page_id": str(page.id),
                "suggested_illustration": suggested_illustration,
            })

        await self.db.commit()
        await self.update_progress(ctx, 55, "Текст сказки готов!")

    def _calculate_words_per_page(
        self, age_range: str, duration_min: int, page_count: int
    ) -> int:
        # Average reading speeds (words per minute) by age group
        wpm = {"3-5": 60, "6-8": 100, "9-12": 150}
        speed = wpm.get(age_range, 100)
        total_words = speed * duration_min
        return max(30, total_words // page_count)

    def _build_page_prompt(
        self, page_num, total_pages, bible, previous_pages, words_per_page,
        age_range, user_context: str | None = None
    ):
        parts = []
        parts.append(
            f"Story bible: {json.dumps(bible, ensure_ascii=False, indent=None)[:3000]}"
        )
        parts.append(f"\nAge group: {age_range}")
        parts.append(f"Page {page_num} of {total_pages}")
        parts.append(f"Target length: approximately {words_per_page} words")

        # Remind model of user context on every page to ensure consistent weaving
        if user_context:
            parts.append(
                f"\n🌟 USER PERSONAL CONTEXT (must be woven into this page if relevant):\n{user_context}"
            )

        if page_num == 1:
            parts.append(
                "This is the FIRST page. Introduce the main character and setting."
            )
            if user_context:
                parts.append(
                    "IMPORTANT: On this first page, naturally introduce elements "
                    "from the user's personal context into the story world."
                )
        elif page_num == total_pages:
            parts.append(
                "This is the LAST page. Wrap up the story with a satisfying ending "
                "and subtle moral."
            )
            if user_context:
                parts.append(
                    "IMPORTANT: The ending should echo or resolve the personal context "
                    "in a meaningful, memorable way for the child."
                )
        else:
            progress_pct = page_num / total_pages
            if progress_pct < 0.35:
                parts.append(
                    "We are in Act 1: Setting up the story, introducing conflict."
                )
            elif progress_pct < 0.7:
                parts.append(
                    "We are in Act 2: Rising action, challenges, adventure."
                )
            else:
                parts.append(
                    "We are in Act 3: Climax and resolution approaching."
                )

        if previous_pages:
            last_pages = previous_pages[-3:]  # Context of last 3 pages
            parts.append("\nPrevious pages for context:")
            for pp in last_pages:
                parts.append(f"Page {pp['page_number']}: {pp['text'][:300]}...")

        return "\n".join(parts)
