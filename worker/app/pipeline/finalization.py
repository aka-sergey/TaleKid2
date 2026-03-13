"""
Stage 9: Finalization + Push Notification
- Set story status to 'completed'
- Set generation job to 'completed'
- Send push notification to user's devices via FCM
- Progress: 96% → 100%
"""

import logging

from sqlalchemy import select

from shared.models.device_token import DeviceToken

from app.pipeline.base import PipelineContext, PipelineStage
from app.services.push_service import PushService

logger = logging.getLogger("worker.pipeline.finalization")


class FinalizationStage(PipelineStage):
    stage_name = "finalization"
    stage_status = "saving"
    progress_start = 96
    progress_end = 100

    def __init__(self, db, redis):
        super().__init__(db, redis)
        self.push_service = PushService()

    async def execute(self, ctx: PipelineContext) -> None:
        await self.update_progress(ctx, 96, "Сохраняем и отправляем уведомление...")

        # Get story title for notification
        story_title = "Ваша сказка"
        if ctx.story_bible and ctx.story_bible.get("title_working"):
            story_title = ctx.story_bible["title_working"]

        # Send push notification
        try:
            result = await self.db.execute(
                select(DeviceToken).where(DeviceToken.user_id == ctx.user_id)
            )
            tokens = result.scalars().all()

            if tokens:
                token_strings = [t.token for t in tokens]
                await self.push_service.send_story_ready(
                    tokens=token_strings,
                    story_title=story_title,
                    story_id=ctx.story_id,
                )
                logger.info(
                    "Push notification sent to %d devices", len(token_strings)
                )
            else:
                logger.info("No device tokens found for user %s", ctx.user_id[:8])

        except Exception as e:
            # Push failure should not fail the pipeline
            logger.warning("Push notification failed: %s", e)

        await self.update_progress(ctx, 100, "Сказка готова!")
