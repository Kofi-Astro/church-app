"""
Pydantic schemas for church-wide settings — currently just the livestream URL
shown in the mobile app (e.g. a YouTube/Facebook Live link updated on service
days). This is a single-row settings table, not per-user data.
"""
from datetime import datetime

from pydantic import BaseModel, Field


class ChurchSettingsRead(BaseModel):
    """The current church-wide settings as returned by the API."""

    # None when no livestream is currently configured/live.
    livestream_url: str | None
    updated_at: datetime


class ChurchSettingsUpdate(BaseModel):
    """Payload for updating church-wide settings (admin only)."""

    # Set to None to clear the livestream link (e.g. once a service ends).
    livestream_url: str | None = Field(default=None, max_length=500)
