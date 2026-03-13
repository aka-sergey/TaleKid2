"""
Stage 1: Photo Analysis
- For each character in the story, analyze their photos with GPT-4 Vision
- Generate a detailed appearance description in English
- Save appearance_description to the Character record
- Progress: 5% -> 15%
"""
import logging

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from shared.models.character import Character
from shared.models.story import StoryCharacter
from app.services.openai_service import OpenAIService
from app.pipeline.base import PipelineContext, PipelineStage

logger = logging.getLogger("worker.pipeline.photo_analysis")


class PhotoAnalysisStage(PipelineStage):
    stage_name = "photo_analysis"
    stage_status = "photo_analysis"
    progress_start = 5
    progress_end = 15

    def __init__(self, db, redis, openai: OpenAIService):
        super().__init__(db, redis)
        self.openai = openai

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 5, "Анализируем фотографии персонажей...")

        # Get story characters with their photos
        result = await self.db.execute(
            select(StoryCharacter)
            .where(StoryCharacter.story_id == ctx.story_id)
            .options(
                selectinload(StoryCharacter.character)
                .selectinload(Character.photos)
            )
        )
        story_characters = result.scalars().all()

        total = len(story_characters)
        for i, sc in enumerate(story_characters):
            character = sc.character
            photos = character.photos

            if photos:
                # Use first photo for analysis
                photo_url = photos[0].s3_url
                prompt = (
                    f"Describe this person's/character's appearance in detail for a fairy tale illustrator. "
                    f"Context: This is a {character.character_type}, name: {character.name}, "
                    f"gender: {character.gender}"
                    f"{f', age: {character.age}' if character.age else ''}. "
                    f"Focus on: hair color/style, eye color, skin tone, facial features, "
                    f"body build, distinguishing features. "
                    f"If there are multiple photos, this is the primary reference. "
                    f"Output a concise English description suitable for image generation prompts."
                )
                try:
                    description = await self.openai.analyze_photo(photo_url, prompt)
                    character.appearance_description = description
                    ctx.character_descriptions[str(character.id)] = description
                    logger.info("Analyzed photos for character: %s", character.name)
                except Exception as e:
                    logger.warning(
                        "Photo analysis failed for %s: %s, using fallback",
                        character.name,
                        e,
                    )
                    # Fallback description
                    description = self._generate_fallback_description(character)
                    character.appearance_description = description
                    ctx.character_descriptions[str(character.id)] = description
            else:
                # No photos -- generate a basic description from metadata
                description = self._generate_fallback_description(character)
                character.appearance_description = description
                ctx.character_descriptions[str(character.id)] = description

            pct = self.progress_start + int(
                (i + 1) / total * (self.progress_end - self.progress_start)
            )
            await self.update_progress(
                ctx, pct, f"Анализ персонажа {i + 1}/{total}: {character.name}"
            )

        await self.db.commit()

    def _generate_fallback_description(self, character) -> str:
        """Generate a basic appearance description from character metadata."""
        parts = []
        if character.character_type == "child":
            if character.gender == "male":
                parts.append("A young boy")
            else:
                parts.append("A young girl")
            if character.age:
                parts.append(f"approximately {character.age} years old")
        elif character.character_type == "adult":
            if character.gender == "male":
                parts.append("An adult man")
            else:
                parts.append("An adult woman")
        elif character.character_type == "pet":
            parts.append("A cute pet animal")

        parts.append(f"named {character.name}")
        parts.append("with a friendly, warm expression, in a fairy tale illustration style")
        return ", ".join(parts)
