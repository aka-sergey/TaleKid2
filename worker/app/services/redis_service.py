import json
import logging

import redis.asyncio as redis

from app.config import get_settings

logger = logging.getLogger("worker.redis")
settings = get_settings()


class RedisService:
    def __init__(self):
        self._client: redis.Redis | None = None

    async def connect(self):
        if self._client is None:
            self._client = redis.from_url(
                settings.REDIS_URL,
                decode_responses=True,
            )
        return self._client

    async def wait_for_job(self, timeout: int = 5) -> dict | None:
        """BRPOP from the job queue. Returns parsed job payload or None on timeout."""
        client = await self.connect()
        result = await client.brpop(settings.REDIS_QUEUE, timeout=timeout)
        if result is None:
            return None
        _, raw = result
        return json.loads(raw)

    async def set_progress(self, job_id: str, data: dict):
        """Set real-time progress in Redis."""
        client = await self.connect()
        await client.set(
            f"{settings.REDIS_PROGRESS_PREFIX}:{job_id}",
            json.dumps(data, default=str),
            ex=settings.REDIS_PROGRESS_TTL,
        )

    async def delete_progress(self, job_id: str):
        client = await self.connect()
        await client.delete(f"{settings.REDIS_PROGRESS_PREFIX}:{job_id}")

    async def close(self):
        if self._client:
            await self._client.close()
            self._client = None
