import ssl
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import get_settings

settings = get_settings()

# SSL context for TimeWeb PostgreSQL
ssl_certfile = Path(__file__).resolve().parent.parent / "root.crt"
ssl_context = None
if ssl_certfile.exists():
    ssl_context = ssl.create_default_context(cafile=str(ssl_certfile))

connect_args = {}
if ssl_context is not None:
    connect_args["ssl"] = ssl_context

engine = create_async_engine(
    settings.database_url,
    echo=False,
    pool_size=5,
    max_overflow=5,
    pool_pre_ping=True,
    connect_args=connect_args,
)

async_session_factory = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False,
)
