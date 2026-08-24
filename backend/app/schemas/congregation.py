"""
Pydantic schemas for congregations — the church's distinct standing service
tracks (English, Akan, Youth Chapel, Teens Chapel, French Chapel, Northern
Congregation, Children's Service, ...), as opposed to `services` in
app/schemas/attendance.py, which is one specific dated gathering that
belongs to one of these congregations.
"""
from datetime import datetime

from pydantic import BaseModel, Field


class CongregationCreate(BaseModel):
    """Payload for adding a new congregation."""

    name: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)


class CongregationUpdate(BaseModel):
    """Payload for editing a congregation. All fields optional — only send what's changing."""

    name: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)


class CongregationRead(BaseModel):
    """A congregation as returned by the API."""

    id: str
    name: str
    description: str | None
    created_at: datetime
