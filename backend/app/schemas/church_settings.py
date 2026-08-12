from datetime import datetime

from pydantic import BaseModel, Field


class ChurchSettingsRead(BaseModel):
    livestream_url: str | None
    updated_at: datetime


class ChurchSettingsUpdate(BaseModel):
    livestream_url: str | None = Field(default=None, max_length=500)
