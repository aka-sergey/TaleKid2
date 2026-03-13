"""
Stage 5: Character Reference Generation
- For each character, generate a reference illustration
- Used for consistent character appearance across all pages
- Upload to S3 and store URL in StoryCharacter.reference_image_url
- Progress: 65% → 70%
"""

import logging
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.orm import selectinload

from shared.models.story import StoryCharacter
from shared.models.character import Character

from app.pipeline.base import PipelineContext, PipelineStage
from app.services.image_service import ImageService
from app.services.s3_service import S3Service

logger = logging.getLogger("worker.pipeline.character_refs")


class CharacterReferencesStage(PipelineStage):
    stage_name = "character_references"
    stage_status = "character_references"
    progress_start = 65
    progress_end = 70

    def __init__(self, db, redis, image_svc: ImageService, s3_svc: S3Service):
        super().__init__(db, redis)
        self.image_svc = image_svc
        self.s3_svc = s3_svc

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 65, "Создаём образы персонажей...")

        # Get story characters
        result = await self.db.execute(
            select(StoryCharacter)
            .where(StoryCharacter.story_id == ctx.story_id)
            .options(selectinload(StoryCharacter.character))
        )
        story_characters = result.scalars().all()
        total = len(story_characters)

        for i, sc in enumerate(story_characters):
            character = sc.character
            char_description = ctx.character_descriptions.get(
                str(character.id), ""
            )

            if not char_description:
                char_description = character.appearance_description or character.name

            # Get visual style from story bible
            visual_style = ""
            if ctx.story_bible:
                visual_style = ctx.story_bible.get(
                    "visual_style",
                    "warm watercolor children's book illustration style",
                )

            try:
                # Generate character reference image
                logger.info("Generating reference for character: %s", character.name)
                image_urls = await self.image_svc.generate_character_reference(
                    character_description=char_description,
                    style_hint=visual_style,
                )

                if image_urls:
                    # Download and upload to S3
                    image_bytes = await self.image_svc.download_image(image_urls[0])
                    s3_key = f"stories/{ctx.story_id}/characters/{character.id}/reference.png"
                    s3_url = self.s3_svc.upload_bytes(s3_key, image_bytes)

                    # Save reference URL
                    sc.reference_image_url = s3_url
                    logger.info(
                        "Character reference uploaded: %s → %s",
                        character.name,
                        s3_key,
                    )

            except Exception as e:
                logger.warning(
                    "Failed to generate reference for %s: %s, skipping",
                    character.name,
                    e,
                )

            pct = self.progress_start + int(
                (i + 1) / total * (self.progress_end - self.progress_start)
            )
            await self.update_progress(
                ctx, pct, f"Образ персонажа {i + 1}/{total}: {character.name}"
            )

        await self.db.commit()
