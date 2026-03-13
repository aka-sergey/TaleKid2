from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # PostgreSQL (TimeWeb)
    POSTGRESQL_HOST: str
    POSTGRESQL_PORT: int = 5432
    POSTGRESQL_USER: str
    POSTGRESQL_PASSWORD: str
    POSTGRESQL_DBNAME: str
    POSTGRESQL_SSLMODE: str = "verify-full"

    # S3 (TimeWeb)
    S3_ENDPOINT_URL: str
    S3_ACCESS_KEY_ID: str
    S3_SECRET_ACCESS_KEY: str
    S3_BUCKET: str
    STORAGE_PUBLIC_URL: str

    # OpenAI
    OPENAI_API_KEY: str
    OPENAI_MODEL: str = "gpt-4o"
    OPENAI_VISION_MODEL: str = "gpt-4o"
    OPENAI_MAX_TOKENS: int = 4096

    # Leonardo.ai
    LEONARDO_API_KEY: str

    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    REDIS_QUEUE: str = "talekid:jobs"
    REDIS_PROGRESS_PREFIX: str = "talekid:progress"
    REDIS_PROGRESS_TTL: int = 3600

    # Worker
    WORKER_CONCURRENCY: int = 1
    IMAGE_MAX_CONCURRENT: int = 10
    IMAGE_ENGINE: str = "leonardo"  # leonardo or dalle

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.POSTGRESQL_USER}:{self.POSTGRESQL_PASSWORD}"
            f"@{self.POSTGRESQL_HOST}:{self.POSTGRESQL_PORT}/{self.POSTGRESQL_DBNAME}"
        )

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache
def get_settings() -> Settings:
    return Settings()
