"""
Pydantic schemas for prayer requests. See app/repositories/prayer_requests.py
for the visibility/access-control rules (kept there since that's the source
of truth for who can see what); this file just defines the request/response
shapes.
"""
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class PrayerVisibility(str, Enum):
    """
    Who can see a prayer request. "public" = whole congregation, "leaders" =
    group leaders/admins only, "private" = only the author (and admins).
    """

    public = "public"
    leaders = "leaders"
    private = "private"


class PrayerRequestCreate(BaseModel):
    """Payload for submitting a new prayer request."""

    content: str = Field(min_length=1, max_length=2000)
    visibility: PrayerVisibility = PrayerVisibility.public


class PrayerRequestRead(BaseModel):
    """A prayer request as returned by the API."""

    id: str
    profile_id: str
    content: str
    visibility: PrayerVisibility
    created_at: datetime
    # How many people have marked that they're praying for this request.
    praying_count: int
    # Whether the current caller specifically is one of those people.
    is_praying: bool
