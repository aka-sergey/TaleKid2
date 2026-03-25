import logging

from openai import AsyncOpenAI
from langsmith import wrappers as ls_wrappers

from app.config import get_settings

logger = logging.getLogger("worker.openai")


class OpenAIService:
    def __init__(self):
        settings = get_settings()
        raw_client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        # Wrap with LangSmith — automatically traces all calls
        # (prompts, responses, tokens, latency). No-op if LANGCHAIN_TRACING_V2 is not set.
        self.client = ls_wrappers.wrap_openai(raw_client)
        self.model = settings.OPENAI_MODEL
        self.vision_model = settings.OPENAI_VISION_MODEL
        self.max_tokens = settings.OPENAI_MAX_TOKENS

    async def analyze_photo(self, image_url: str, prompt: str) -> str:
        """Use GPT-4 Vision to analyze a character photo."""
        response = await self.client.chat.completions.create(
            model=self.vision_model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are an expert at describing character appearances "
                        "for fairy tale illustrations. Provide detailed visual "
                        "descriptions in English."
                    ),
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": image_url}},
                    ],
                },
            ],
            max_tokens=500,
        )
        return response.choices[0].message.content.strip()

    async def chat(
        self,
        system_prompt: str,
        user_prompt: str,
        max_tokens: int | None = None,
        temperature: float = 0.8,
    ) -> str:
        """Standard chat completion."""
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            max_tokens=max_tokens or self.max_tokens,
            temperature=temperature,
        )
        return response.choices[0].message.content.strip()

    async def chat_json(
        self,
        system_prompt: str,
        user_prompt: str,
        max_tokens: int | None = None,
        temperature: float = 0.7,
    ) -> str:
        """Chat completion with JSON response format."""
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            max_tokens=max_tokens or self.max_tokens,
            temperature=temperature,
            response_format={"type": "json_object"},
        )
        return response.choices[0].message.content.strip()
