"""
Church App backend — FastAPI entrypoint.

Phase 0 scope: app boots, has structured logging, and exposes a health
check the CI pipeline and hosting platform can use.

Phase 1 adds the member/household directory and attendance routers.
Phase 2 adds sermons and church-wide settings (e.g. the livestream URL);
the Bible reader itself calls a public third-party API directly from the
mobile app rather than through this backend — see
mobile/lib/features/bible/bible_api_service.dart.
Phase 3 adds reading plans and small groups (materials scoped to group
membership); per-user reading progress goes straight to Supabase from
the mobile app, same pattern as the Phase 2 Bible bookmarks.
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI  # type: ignore[import]

from app.api.v1.attendance import router as attendance_router
from app.api.v1.church_settings import router as church_settings_router
from app.api.v1.households import router as households_router
from app.api.v1.members import router as members_router
from app.api.v1.reading_plans import router as reading_plans_router
from app.api.v1.sermons import router as sermons_router
from app.api.v1.small_groups import router as small_groups_router
from app.core.config import get_settings
from app.core.logging import configure_logging

configure_logging()
logger = logging.getLogger("church_app")

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(
        "Starting %s in %s mode",
        settings.app_name,
        settings.environment,
    )
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="Backend API for the church mobile app.",
    lifespan=lifespan,
)

app.include_router(households_router, prefix="/api/v1")
app.include_router(members_router, prefix="/api/v1")
app.include_router(attendance_router, prefix="/api/v1")
app.include_router(sermons_router, prefix="/api/v1")
app.include_router(church_settings_router, prefix="/api/v1")
app.include_router(reading_plans_router, prefix="/api/v1")
app.include_router(small_groups_router, prefix="/api/v1")


@app.get("/health", tags=["system"])
async def health_check() -> dict:
    """
    Liveness/readiness check.

    Deliberately returns no sensitive info (no config values, no stack
    traces) — this endpoint is expected to be public and hit by uptime
    monitors.
    """
    return {"status": "ok", "environment": settings.environment}


@app.get("/", tags=["system"])
async def root() -> dict:
    return {"service": settings.app_name, "status": "running"}
