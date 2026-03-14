import logging
import sys
from contextlib import asynccontextmanager
from pathlib import Path

# Make shared package importable
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.middleware import RequestLoggingMiddleware
from app.database import engine
from app.routers import auth, catalog, characters, generation, health, stories
from shared.models.base import Base

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s %(name)s  %(message)s",
)
logger = logging.getLogger("talekid")


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables if they do not exist (dev convenience; Alembic is the
    # canonical migration tool for production).
    async with engine.begin() as conn:
        # TEMPORARY: drop old tables from previous app version to fix schema mismatch.
        # Remove this line after first successful deployment!
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables recreated (schema migration)")
    yield
    await engine.dispose()
    logger.info("Database engine disposed")


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="TaleKID API",
    version="1.0.0",
    lifespan=lifespan,
)

# -- CORS ------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Will be restricted in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -- Request logging -------------------------------------------------------
app.add_middleware(RequestLoggingMiddleware)

# -- Routers ---------------------------------------------------------------
app.include_router(auth.router, prefix="/api/v1")
app.include_router(health.router, prefix="/api/v1")
app.include_router(characters.router, prefix="/api/v1")
app.include_router(catalog.router, prefix="/api/v1")
app.include_router(generation.router, prefix="/api/v1")
app.include_router(stories.router, prefix="/api/v1")
