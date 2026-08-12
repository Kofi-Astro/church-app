from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class PrayerVisibility(str, Enum):
    public = "public"
    leaders = "leaders"
    private = "private"


class PrayerRequestCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)
    visibility: PrayerVisibility = PrayerVisibility.public


class PrayerRequestRead(BaseModel):
    id: str
    profile_id: str
    content: str
    visibility: PrayerVisibility
    created_at: datetime
    praying_count: int
    is_praying: bool
