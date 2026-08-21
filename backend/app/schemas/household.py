"""
Pydantic schemas for households — a family unit that members can be grouped
under (used for directory organization and household-level attendance/mailing
purposes).
"""
from datetime import datetime

from pydantic import BaseModel, Field


class HouseholdCreate(BaseModel):
    """Payload for creating a new household."""

    name: str = Field(min_length=1, max_length=200)
    address: str | None = Field(default=None, max_length=500)


class HouseholdUpdate(BaseModel):
    """Payload for updating a household. All fields optional — only send what's changing."""

    name: str | None = Field(default=None, min_length=1, max_length=200)
    address: str | None = Field(default=None, max_length=500)


class HouseholdRead(BaseModel):
    """A household as returned by the API."""

    id: str
    name: str
    address: str | None
    created_at: datetime
