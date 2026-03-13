"""
DALL-E image generation service (fallback for Leonardo.ai).

Uses OpenAI DALL-E 3 API for image generation when Leonardo is
unavailable or fails.
"""

import asyncio
import logging

import httpx
from openai import AsyncOpenAI

from app.config import get_settings

logger = logging.getLogger("worker.dalle")


class DalleService:
    """Async DALL-E 3 image generation service (fallback)."""

    def __init__(self):
        settings = get_settings()
        self._client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        self._semaphore = asyncio.Semaphore(5)  # DALL-E rate limits are stricter

    async def generate_image(
        self,
        prompt: str,
        size: str = "1024x1024",
        quality: str = "standard",
        style: str = "vivid",
    ) -> list[str]:
        """
        Generate an image using DALL-E 3.

        Args:
            prompt: Image description (will be prefixed with safety/style instructions)
            size: Image size (1024x1024, 1792x1024, 1024x1792)
            quality: standard or hd
            style: vivid or natural

        Returns:
            List with one generated image URL
        """
        async with self._semaphore:
            # Prepend children's book illustration instructions
            full_prompt = (
                f"Children's book illustration in warm watercolor style. "
                f"Safe, friendly, age-appropriate content for children. "
                f"No text or words in the image. "
                f"{prompt}"
            )

            try:
                response = await self._client.images.generate(
                    model="dall-e-3",
                    prompt=full_prompt[:4000],  # DALL-E 3 prompt limit
                    size=size,
                    quality=quality,
                    style=style,
                    n=1,
                )

                urls = [img.url for img in response.data if img.url]
                logger.info("DALL-E generated %d images", len(urls))
                return urls

            except Exception as e:
                logger.error("DALL-E generation failed: %s", e)
                raise

    async def download_image(self, url: str) -> bytes:
        """Download an image from URL and return raw bytes."""
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            return response.content

    async def generate_character_reference(
        self,
        character_description: str,
        style_hint: str = "children's book illustration, warm watercolor style",
    ) -> list[str]:
        """Generate a character reference image via DALL-E."""
        prompt = (
            f"Full body character portrait, {character_description}, "
            f"{style_hint}, white background, character sheet, "
            f"front view, clear features, high detail"
        )

        return await self.generate_image(
            prompt=prompt,
            size="1024x1024",
            quality="standard",
        )
