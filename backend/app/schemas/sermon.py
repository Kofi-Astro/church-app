"""Pydantic schemas for sermons (past-service recordings/notes shown in the app)."""
from datetime import date, datetime

from pydantic import BaseModel, Field


class SermonCreate(BaseModel):
    """Payload for adding a new sermon."""

    title: str = Field(min_length=1, max_length=200)
    speaker: str | None = Field(default=None, max_length=200)
    # Name of the sermon series this belongs to, if any (e.g. "Advent 2025").
    series: str | None = Field(default=None, max_length=200)
    sermon_date: date
    # Link to the recording (e.g. YouTube), if one has been uploaded.
    video_url: str | None = Field(default=None, max_length=500)
    description: str | None = Field(default=None, max_length=5000)


class SermonUpdate(BaseModel):
    """Payload for editing a sermon. All fields optional — only send what's changing."""

    title: str | None = Field(default=None, min_length=1, max_length=200)
    speaker: str | None = Field(default=None, max_length=200)
    series: str | None = Field(default=None, max_length=200)
    sermon_date: date | None = None
    video_url: str | None = Field(default=None, max_length=500)
    description: str | None = Field(default=None, max_length=5000)


class SermonRead(BaseModel):
    """A sermon as returned by the API."""

    id: str
    title: str
    speaker: str | None
    series: str | None
    sermon_date: date
    video_url: str | None
    description: str | None
    created_at: datetime
