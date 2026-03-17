"""
Stage 3+4: Text Generation + Scene Decomposition (merged, 2-wave parallel)

Strategy:
  Wave 1 – pages 1-3 in parallel (no previous context needed)
  Wave 2 – pages 4-N in parallel, using Wave 1 summaries as narrative context

Each page produces text + scene description in a SINGLE GPT call, so we
eliminate the old sequential Stage 4 entirely.

Progress: 30% -> 65%
"""
import asyncio
import json
import logging

from sqlalchemy import select

from shared.models.story import Story
from shared.models.page import Page
from app.services.openai_service import OpenAIService
from app.pipeline.base import PipelineContext, PipelineStage

logger = logging.getLogger("worker.pipeline.text_generation")

SYSTEM_PROMPT = """You are a talented Russian children's book author and expert art director.
For each page you will write the story text in Russian AND create a detailed illustration description.

Rules for story text:
- Write ONLY in Russian
- Use age-appropriate vocabulary and sentence complexity
- Each page should be a self-contained scene that can be illustrated
- Maintain consistent character voices and story tone
- Include dialogue where appropriate
- End each page naturally so the reader wants to turn to the next one
- The last page should provide a satisfying conclusion

Rules for illustration:
- scene_description: detailed visual breakdown (setting, characters, actions, mood, lighting, objects, palette)
- image_prompt: detailed English prompt for AI image generation (art style, composition, characters, setting, lighting, mood — under 300 words)

Output valid JSON only:
{
  "text_content": "The story text for this page in Russian",
  "scene_description": {
    "setting": "Description of the background/environment",
    "characters_present": ["list of character names visible in scene"],
    "character_actions": "What the characters are doing",
    "mood": "Emotional mood of the scene",
    "lighting": "Lighting description",
    "key_objects": ["important objects in the scene"],
    "color_palette": "Suggested color palette"
  },
  "image_prompt": "A detailed prompt for AI image generation in English. Include: art style (children's book illustration), scene composition, character descriptions, setting details, lighting, mood. Under 300 words."
}"""


class TextGenerationStage(PipelineStage):
    stage_name = "text_generation"
    stage_status = "text_generation"
    progress_start = 30
    progress_end = 65

    def __init__(self, db, redis, openai: OpenAIService):
        super().__init__(db, redis)
        self.openai = openai

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 30, "Начинаем писать сказку...")

        result = await self.db.execute(select(Story).where(Story.id == ctx.story_id))
        story = result.scalar_one()

        page_count = story.page_count
        bible = ctx.story_bible or {}

        words_per_page = self._calculate_words_per_page(
            story.age_range, story.reading_duration_minutes, page_count
        )
        visual_style = self._get_visual_style(ctx, bible)

        # ── Wave 1: pages 1-3 in parallel (no prior narrative context) ──────
        wave1_nums = list(range(1, min(4, page_count + 1)))
        logger.info(
            "[%s] Wave 1: generating pages %s in parallel",
            ctx.job_id[:8], wave1_nums
        )
        await self.update_progress(ctx, 33, "Пишем первые страницы...")

        wave1_results: list[dict] = await asyncio.gather(*[
            self._generate_page(
                page_num=p,
                total_pages=page_count,
                bible=bible,
                previous_summaries=[],
                words_per_page=words_per_page,
                age_range=story.age_range,
                user_context=ctx.user_context,
                visual_style=visual_style,
                character_descriptions=ctx.character_descriptions,
            )
            for p in wave1_nums
        ])
        wave1_results = sorted(wave1_results, key=lambda r: r["page_number"])

        await self.update_progress(ctx, 47, "Продолжаем историю...")

        # ── Wave 2: pages 4-N in parallel, wave 1 summaries as context ───────
        wave2_nums = list(range(4, page_count + 1))
        wave1_summaries = [
            {"page_number": r["page_number"], "text": r["text_content"][:300]}
            for r in wave1_results
        ]

        if wave2_nums:
            logger.info(
                "[%s] Wave 2: generating pages %s in parallel",
                ctx.job_id[:8], wave2_nums
            )
            wave2_results: list[dict] = await asyncio.gather(*[
                self._generate_page(
                    page_num=p,
                    total_pages=page_count,
                    bible=bible,
                    previous_summaries=wave1_summaries,
                    words_per_page=words_per_page,
                    age_range=story.age_range,
                    user_context=ctx.user_context,
                    visual_style=visual_style,
                    character_descriptions=ctx.character_descriptions,
                )
                for p in wave2_nums
            ])
            wave2_results = sorted(wave2_results, key=lambda r: r["page_number"])
        else:
            wave2_results = []

        await self.update_progress(ctx, 60, "Сохраняем страницы...")

        # ── Persist to DB in page order ───────────────────────────────────────
        all_results = sorted(
            list(wave1_results) + list(wave2_results),
            key=lambda r: r["page_number"],
        )

        for r in all_results:
            page = Page(
                story_id=ctx.story_id,
                page_number=r["page_number"],
                text_content=r["text_content"],
                scene_description=r["scene_description"],
                image_prompt=r["image_prompt"],
            )
            self.db.add(page)
            await self.db.flush()

            ctx.pages_text.append({
                "page_number": r["page_number"],
                "text_content": r["text_content"],
                "page_id": str(page.id),
                "suggested_illustration": r["image_prompt"],
            })
            ctx.scenes.append({
                "page_number": r["page_number"],
                "page_id": str(page.id),
                "scene_description": r["scene_description"],
                "image_prompt": r["image_prompt"],
            })

        await self.db.commit()
        logger.info(
            "[%s] Text+Scene generation complete: %d pages",
            ctx.job_id[:8], len(all_results)
        )
        await self.update_progress(ctx, 65, "Текст и описания сцен готовы!")

    # ── Helpers ───────────────────────────────────────────────────────────────

    async def _generate_page(
        self,
        page_num: int,
        total_pages: int,
        bible: dict,
        previous_summaries: list[dict],
        words_per_page: int,
        age_range: str,
        user_context: str | None,
        visual_style: str,
        character_descriptions: dict,
    ) -> dict:
        """Generate a single page's text + scene in one GPT call."""
        user_prompt = self._build_page_prompt(
            page_num, total_pages, bible, previous_summaries,
            words_per_page, age_range, user_context,
            visual_style, character_descriptions,
        )

        raw = await self.openai.chat_json(SYSTEM_PROMPT, user_prompt, max_tokens=2000)

        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            logger.warning(
                "Page %d JSON parse failed, retrying with explicit instruction", page_num
            )
            raw = await self.openai.chat_json(
                SYSTEM_PROMPT,
                user_prompt + "\n\nReturn ONLY valid JSON, no markdown fences.",
                max_tokens=2000,
            )
            data = json.loads(raw)

        return {
            "page_number": page_num,
            "text_content": data.get("text_content", ""),
            "scene_description": data.get("scene_description", {}),
            "image_prompt": data.get("image_prompt", ""),
        }

    def _get_visual_style(self, ctx: PipelineContext, bible: dict) -> str:
        if ctx.illustration_style:
            from shared.constants import STYLE_PROMPTS
            return STYLE_PROMPTS.get(
                ctx.illustration_style,
                bible.get("visual_style", "warm watercolor children's book illustration style"),
            )
        return bible.get(
            "visual_style",
            "warm watercolor children's book illustration style",
        )

    def _calculate_words_per_page(
        self, age_range: str, duration_min: int, page_count: int
    ) -> int:
        wpm = {"3-5": 60, "6-8": 100, "9-12": 150}
        speed = wpm.get(age_range, 100)
        total_words = speed * duration_min
        return max(30, total_words // page_count)

    def _build_page_prompt(
        self,
        page_num: int,
        total_pages: int,
        bible: dict,
        previous_summaries: list[dict],
        words_per_page: int,
        age_range: str,
        user_context: str | None,
        visual_style: str,
        character_descriptions: dict,
    ) -> str:
        parts: list[str] = []

        parts.append(
            f"Story bible: {json.dumps(bible, ensure_ascii=False, indent=None)[:3000]}"
        )
        parts.append(f"\nAge group: {age_range}")
        parts.append(f"Page {page_num} of {total_pages}")
        parts.append(f"Target text length: approximately {words_per_page} words")
        parts.append(f"\nIllustration style: {visual_style}")

        if character_descriptions:
            parts.append("\nCharacter appearance references for illustration:")
            for desc in character_descriptions.values():
                parts.append(f"- {desc}")

        if user_context:
            parts.append(
                f"\n🌟 USER PERSONAL CONTEXT (weave into this page where natural):\n{user_context}"
            )

        # Page role in story structure
        if page_num == 1:
            parts.append(
                "\nThis is the FIRST page. Introduce the main character and setting. "
                "Make the opening scene inviting and establish the mood."
            )
            if user_context:
                parts.append(
                    "IMPORTANT: Naturally introduce elements from the user's personal "
                    "context into the story world on this first page."
                )
        elif page_num == total_pages:
            parts.append(
                "\nThis is the LAST page. Wrap up the story with a satisfying ending "
                "and a subtle moral. Make the final scene warm and conclusive."
            )
            if user_context:
                parts.append(
                    "IMPORTANT: The ending should echo or resolve the personal context "
                    "in a meaningful, memorable way for the child."
                )
        else:
            progress_pct = page_num / total_pages
            if progress_pct < 0.35:
                parts.append("We are in Act 1: Setting up the story, introducing conflict.")
            elif progress_pct < 0.70:
                parts.append("We are in Act 2: Rising action, challenges, adventure.")
            else:
                parts.append("We are in Act 3: Climax and resolution approaching.")

        if previous_summaries:
            parts.append("\nPrevious pages for narrative continuity:")
            for pp in previous_summaries[-3:]:
                parts.append(f"  Page {pp['page_number']}: {pp['text']}...")

        return "\n".join(parts)
