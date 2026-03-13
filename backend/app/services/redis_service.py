import json
import logging
from typing import Optional

import redis.asyncio as redis

from app.config import get_settings

logger = logging.getLogger("talekid.redis")

QUEUE_NAME = "talekid:jobs"
PROGRESS_KEY_PREFIX = "talekid:progress"


class RedisService:
    def __init__(self) -> None:
        settings = get_settings()
        self._redis: redis.Redis = redis.from_url(
            settings.REDIS_URL,
            decode_responses=True,
        )

    async def enqueue_job(self, job_id: str, payload: dict) -> None:
        """Push a generation job onto the queue (LPUSH)."""
        await self._redis.lpush(QUEUE_NAME, json.dumps({"job_id": job_id, **payload}))
        logger.info("Job %s enqueued", job_id)

    async def get_progress(self, job_id: str) -> Optional[dict]:
        """Return the current progress dict for a job, or None."""
        key = f"{PROGRESS_KEY_PREFIX}:{job_id}"
        raw = await self._redis.get(key)
        if raw is None:
            return None
        return json.loads(raw)

    async def set_progress(
        self, job_id: str, data: dict, ttl: int = 3600
    ) -> None:
        """Store progress data with a TTL (seconds)."""
        key = f"{PROGRESS_KEY_PREFIX}:{job_id}"
        await self._redis.set(key, json.dumps(data), ex=ttl)

    async def delete_progress(self, job_id: str) -> None:
        """Remove the progress key for a job."""
        key = f"{PROGRESS_KEY_PREFIX}:{job_id}"
        await self._redis.delete(key)

    async def close(self) -> None:
        """Gracefully close the underlying connection pool."""
        await self._redis.aclose()


# ---------------------------------------------------------------------------
# Lazy singleton – avoids initialisation at import time so the module can be
# imported safely even when Redis env-vars are not yet configured (e.g. during
# tests or when running unrelated CLI commands).
# ---------------------------------------------------------------------------
_redis_service: RedisService | None = None


def get_redis_service() -> RedisService:
    """Return the shared RedisService instance, creating it on first call."""
    global _redis_service
    if _redis_service is None:
        _redis_service = RedisService()
    return _redis_service
