"""
Stage 6: Illustration Generation
- Generate illustrations for every page using Leonardo.ai / DALL-E
- Uses 10 parallel threads via asyncio.Semaphore (controlled by ImageService)
- Uses character reference images for consistency
- Upload to S3 and store URL in Page.image_url
- First page illustration also becomes the cover
- Progress: 70% → 90%
"""

import asyncio
import logging
from uuid import UUID

from sqlalchemy import select, update

from shared.models.page import Page
from shared.models.story import Story, StoryCharacter

from app.pipeline.base import PipelineContext, PipelineStage
from app.services.image_service import ImageService
from app.services.s3_service import S3Service

logger = logging.getLogger("worker.pipeline.illustration")


class IllustrationStage(PipelineStage):
    stage_name = "illustration"
    stage_status = "illustration"
    progress_start = 70
    progress_end = 90

    def __init__(self, db, redis, image_svc: ImageService, s3_svc: S3Service):
        super().__init__(db, redis)
        self.image_svc = image_svc
        self.s3_svc = s3_svc

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 70, "Начинаем рисовать иллюстрации...")

        scenes = ctx.scenes
        total = len(scenes)

        if total == 0:
            logger.warning("No scenes to illustrate")
            await self.update_progress(ctx, 90, "Нет сцен для иллюстрации")
            return

        # Get character reference URLs for consistent illustration
        result = await self.db.execute(
            select(StoryCharacter)
            .where(StoryCharacter.story_id == ctx.story_id)
        )
        story_characters = result.scalars().all()

        # Pick the protagonist's reference image (if available)
        protagonist_ref_url = None
        for sc in story_characters:
            if sc.role_in_story == "protagonist" and sc.reference_image_url:
                protagonist_ref_url = sc.reference_image_url
                break

        # If no protagonist ref, use any available reference
        if not protagonist_ref_url:
            for sc in story_characters:
                if sc.reference_image_url:
                    protagonist_ref_url = sc.reference_image_url
                    break

        # Generate illustrations in parallel batches
        completed = 0
        cover_url = None

        # Process in batches of 10 (semaphore handles concurrency)
        tasks = []
        for scene in scenes:
            task = self._generate_single_illustration(
                ctx=ctx,
                scene=scene,
                character_ref_url=protagonist_ref_url,
            )
            tasks.append(task)

        # Run all tasks concurrently — ImageService.semaphore limits to 10
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Process results and update progress
        for i, (scene, result) in enumerate(zip(scenes, results)):
            page_id = scene["page_id"]
            page_num = scene["page_number"]

            if isinstance(result, Exception):
                logger.error(
                    "Illustration failed for page %d: %s", page_num, result
                )
                continue

            s3_url = result
            if s3_url:
                # Update page with image URL
                await self.db.execute(
                    update(Page)
                    .where(Page.id == page_id)
                    .values(
                        image_url=s3_url,
                        image_s3_key=f"stories/{ctx.story_id}/pages/{page_num}.png",
                    )
                )

                # First page becomes the cover
                if page_num == 1:
                    cover_url = s3_url

                completed += 1

            pct = self.progress_start + int(
                (i + 1) / total * (self.progress_end - self.progress_start)
            )
            await self.update_progress(
                ctx, pct, f"Иллюстрация {i + 1}/{total}..."
            )

        # Set cover image
        if cover_url:
            await self.db.execute(
                update(Story)
                .where(Story.id == ctx.story_id)
                .values(cover_image_url=cover_url)
            )

        await self.db.commit()

        logger.info(
            "Illustration complete: %d/%d pages illustrated",
            completed,
            total,
        )
        await self.update_progress(
            ctx, 90, f"Иллюстрации готовы ({completed}/{total})!"
        )

    async def _generate_single_illustration(
        self,
        ctx: PipelineContext,
        scene: dict,
        character_ref_url: str | None,
    ) -> str | None:
        """Generate and upload a single page illustration."""
        page_num = scene["page_number"]
        image_prompt = scene.get("image_prompt", "")

        if not image_prompt:
            logger.warning("No image prompt for page %d, skipping", page_num)
            return None

        try:
            # Generate image
            image_urls = await self.image_svc.generate_image(
                prompt=image_prompt,
                character_ref_url=character_ref_url,
                width=1024,
                height=768,
            )

            if not image_urls:
                logger.warning("No images generated for page %d", page_num)
                return None

            # Download generated image
            image_bytes = await self.image_svc.download_image(image_urls[0])

            # Upload to S3
            s3_key = f"stories/{ctx.story_id}/pages/{page_num}.png"
            s3_url = self.s3_svc.upload_bytes(s3_key, image_bytes)

            logger.info("Page %d illustration uploaded: %s", page_num, s3_key)
            return s3_url

        except Exception as e:
            logger.error("Illustration generation failed for page %d: %s", page_num, e)
            raise
