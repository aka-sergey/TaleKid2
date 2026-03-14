import ssl
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import get_settings

settings = get_settings()

# SSL context for TimeWeb PostgreSQL
# Priority: root.crt (full verification) → permissive SSL (encrypted, no cert check)
ssl_certfile = Path(__file__).resolve().parent.parent / "root.crt"

if ssl_certfile.exists():
    ssl_context = ssl.create_default_context(cafile=str(ssl_certfile))
else:
    # No CA cert available — still use SSL but skip certificate verification.
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE

connect_args = {"ssl": ssl_context}

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
