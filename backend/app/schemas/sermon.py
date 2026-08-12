from datetime import date, datetime

from pydantic import BaseModel, Field


class SermonCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    speaker: str | None = Field(default=None, max_length=200)
    series: str | None = Field(default=None, max_length=200)
    sermon_date: date
    video_url: str | None = Field(default=None, max_length=500)
    description: str | None = Field(default=None, max_length=5000)


class SermonUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    speaker: str | None = Field(default=None, max_length=200)
    series: str | None = Field(default=None, max_length=200)
    sermon_date: date | None = None
    video_url: str | None = Field(default=None, max_length=500)
    description: str | None = Field(default=None, max_length=5000)


class SermonRead(BaseModel):
    id: str
    title: str
    speaker: str | None
    series: str | None
    sermon_date: date
    video_url: str | None
    description: str | None
    created_at: datetime
