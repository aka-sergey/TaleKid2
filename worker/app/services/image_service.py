"""
Unified image generation service.

Routes requests to Leonardo.ai or DALL-E based on config,
with automatic fallback on failure.
"""

import logging

from app.config import get_settings
from app.services.dalle_service import DalleService
from app.services.leonardo_service import LeonardoService

logger = logging.getLogger("worker.image")


class ImageService:
    """
    Unified interface for image generation.
    Uses Leonardo.ai as primary, DALL-E as fallback.
    """

    def __init__(self):
        settings = get_settings()
        self._engine = settings.IMAGE_ENGINE  # "leonardo" or "dalle"
        self._leonardo: LeonardoService | None = None
        self._dalle: DalleService | None = None

        if self._engine == "leonardo":
            self._leonardo = LeonardoService()
            self._dalle = DalleService()  # Fallback
        else:
            self._dalle = DalleService()

    async def generate_image(
        self,
        prompt: str,
        character_ref_url: str | None = None,
        character_ref_id: str | None = None,
        width: int = 1024,
        height: int = 768,
    ) -> list[str]:
        """
        Generate an illustration image.

        Args:
            prompt: Image description
            character_ref_url: DEPRECATED — use character_ref_id
            character_ref_id: Leonardo image ID for character reference
            width, height: Image dimensions

        Tries Leonardo first (with character_ref_id if provided),
        falls back to DALL-E on failure.
        """
        if self._engine == "leonardo" and self._leonardo:
            try:
                urls = await self._leonardo.generate_image(
                    prompt=prompt,
                    character_ref_id=character_ref_id,
                    width=width,
                    height=height,
                )
                if urls:
                    return urls
            except Exception as e:
                logger.warning(
                    "Leonardo generation failed, falling back to DALL-E: %s", e
                )

        # Fallback to DALL-E
        if self._dalle:
            # Map dimensions to DALL-E sizes
            if width > height:
                size = "1792x1024"
            elif height > width:
                size = "1024x1792"
            else:
                size = "1024x1024"

            return await self._dalle.generate_image(prompt=prompt, size=size)

        raise RuntimeError("No image generation service available")

    async def generate_character_reference(
        self,
        character_description: str,
        style_hint: str = "children's book illustration, warm watercolor style",
    ) -> list[dict]:
        """
        Generate a character reference image for consistent illustration.

        Returns list of {url, id} dicts when using Leonardo,
        or list of {url, id: None} dicts when using DALL-E fallback.
        """
        if self._engine == "leonardo" and self._leonardo:
            try:
                result = await self._leonardo.generate_character_reference(
                    character_description=character_description,
                    style_hint=style_hint,
                )
                if result:
                    return result
            except Exception as e:
                logger.warning(
                    "Leonardo char ref failed, falling back to DALL-E: %s", e
                )

        if self._dalle:
            urls = await self._dalle.generate_character_reference(
                character_description=character_description,
                style_hint=style_hint,
            )
            # DALL-E returns plain URLs — wrap as dicts without Leonardo ID
            return [{"url": u, "id": None} for u in urls]

        raise RuntimeError("No image generation service available")

    async def download_image(self, url: str) -> bytes:
        """Download image bytes from a URL."""
        if self._leonardo:
            return await self._leonardo.download_image(url)
        if self._dalle:
            return await self._dalle.download_image(url)

        import httpx
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            return response.content
