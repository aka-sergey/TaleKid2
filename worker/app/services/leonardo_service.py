"""
Leonardo.ai image generation service.

Uses the Leonardo API to generate fairy tale illustrations with
character reference support. Falls back to DALL-E on failure.

API flow:
  1. POST /generations → get generation_id
  2. Poll GET /generations/{id} → wait for status "COMPLETE"
  3. Download generated image URLs

Character Reference flow:
  1. Generate character reference image via Leonardo
  2. Get the Leonardo image ID from the response (generated_images[0].id)
  3. Pass initImageId + initImageType="GENERATED" to subsequent generations
"""

import asyncio
import logging

import httpx

from app.config import get_settings

logger = logging.getLogger("worker.leonardo")

LEONARDO_API_BASE = "https://cloud.leonardo.ai/api/rest/v1"

# Leonardo model IDs for high-quality illustration
# Using Leonardo Phoenix for best quality children's book illustrations
LEONARDO_MODEL_ID = "6b645e3a-d64f-4341-a6d8-7a3690fbf042"  # Leonardo Phoenix

# Preprocessor ID for Character Reference
CHARACTER_REF_PREPROCESSOR_ID = 133


class LeonardoService:
    """Async Leonardo.ai image generation service."""

    def __init__(self):
        settings = get_settings()
        self._api_key = settings.LEONARDO_API_KEY
        self._max_concurrent = settings.IMAGE_MAX_CONCURRENT
        self._semaphore = asyncio.Semaphore(self._max_concurrent)
        self._headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    async def generate_image(
        self,
        prompt: str,
        negative_prompt: str = "ugly, deformed, blurry, low quality, text, watermark, signature, adult content, violence, scary, horror",
        width: int = 1024,
        height: int = 768,
        num_images: int = 1,
        character_ref_url: str | None = None,
        character_ref_id: str | None = None,
        style_preset: str | None = "ILLUSTRATION",
    ) -> list[str]:
        """
        Generate an image using Leonardo.ai.

        Args:
            prompt: Image description
            negative_prompt: What to avoid
            width, height: Image dimensions
            num_images: Number of images to generate
            character_ref_url: DEPRECATED — ignored, use character_ref_id
            character_ref_id: Leonardo image ID for character reference (initImageId)
            style_preset: Leonardo style preset

        Returns:
            List of generated image URLs
        """
        async with self._semaphore:
            result = await self._generate(
                prompt=prompt,
                negative_prompt=negative_prompt,
                width=width,
                height=height,
                num_images=num_images,
                character_ref_id=character_ref_id,
                style_preset=style_preset,
            )
            return [item["url"] for item in result]

    async def _generate(
        self,
        prompt: str,
        negative_prompt: str,
        width: int,
        height: int,
        num_images: int,
        character_ref_id: str | None,
        style_preset: str | None,
    ) -> list[dict]:
        """Internal generation logic. Returns list of {url, id} dicts."""
        body: dict = {
            "modelId": LEONARDO_MODEL_ID,
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "width": width,
            "height": height,
            "num_images": num_images,
            "alchemy": True,
            "photoReal": False,
            "contrastRatio": 0.5,
        }

        if style_preset:
            body["presetStyle"] = style_preset

        # Add character reference using Leonardo image ID (initImageType: GENERATED)
        if character_ref_id:
            body["controlnets"] = [
                {
                    "initImageId": character_ref_id,
                    "initImageType": "GENERATED",
                    "preprocessorId": CHARACTER_REF_PREPROCESSOR_ID,
                    "strengthType": "Mid",
                }
            ]
            logger.info("Using character reference ID: %s", character_ref_id)

        async with httpx.AsyncClient(timeout=120.0) as client:
            # Step 1: Submit generation request
            response = await client.post(
                f"{LEONARDO_API_BASE}/generations",
                headers=self._headers,
                json=body,
            )
            response.raise_for_status()
            data = response.json()

            generation_id = data["sdGenerationJob"]["generationId"]
            logger.info("Leonardo generation submitted: %s", generation_id)

            # Step 2: Poll for completion
            return await self._poll_generation(client, generation_id)

    async def _poll_generation(
        self,
        client: httpx.AsyncClient,
        generation_id: str,
        max_attempts: int = 60,
        poll_interval: float = 3.0,
    ) -> list[dict]:
        """Poll Leonardo API until generation is complete.

        Returns list of {url, id} dicts for each generated image.
        """
        for attempt in range(max_attempts):
            await asyncio.sleep(poll_interval)

            response = await client.get(
                f"{LEONARDO_API_BASE}/generations/{generation_id}",
                headers=self._headers,
            )
            response.raise_for_status()
            data = response.json()

            gen_data = data.get("generations_by_pk", {})
            status = gen_data.get("status")

            if status == "COMPLETE":
                images = gen_data.get("generated_images", [])
                result = [
                    {"url": img["url"], "id": img["id"]}
                    for img in images
                    if img.get("url") and img.get("id")
                ]
                logger.info(
                    "Leonardo generation %s complete: %d images",
                    generation_id,
                    len(result),
                )
                return result

            if status == "FAILED":
                raise RuntimeError(
                    f"Leonardo generation {generation_id} failed"
                )

            logger.debug(
                "Polling generation %s: attempt %d/%d, status=%s",
                generation_id,
                attempt + 1,
                max_attempts,
                status,
            )

        raise TimeoutError(
            f"Leonardo generation {generation_id} timed out after {max_attempts} attempts"
        )

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
    ) -> list[dict]:
        """
        Generate a character reference image for consistent illustration.

        Returns list of {url, id} dicts.
        The Leonardo image ID is stored and passed as initImageId in
        subsequent page illustration generations.
        """
        prompt = (
            f"Full body character portrait, {character_description}, "
            f"{style_hint}, white background, character sheet, "
            f"front view, clear features, high detail, "
            f"children's fairy tale character design"
        )

        async with self._semaphore:
            return await self._generate(
                prompt=prompt,
                negative_prompt="ugly, deformed, blurry, low quality, text, watermark",
                width=768,
                height=1024,
                num_images=1,
                character_ref_id=None,
                style_preset="ILLUSTRATION",
            )
