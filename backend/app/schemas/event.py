from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class RsvpStatus(str, Enum):
    going = "going"
    maybe = "maybe"
    not_going = "not_going"


class EventCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    event_date: datetime
    location: str | None = Field(default=None, max_length=300)


class EventRead(BaseModel):
    id: str
    title: str
    description: str | None
    event_date: datetime
    location: str | None
    created_at: datetime
    rsvp_counts: dict[str, int]
    my_rsvp: RsvpStatus | None


class RsvpCreate(BaseModel):
    status: RsvpStatus = RsvpStatus.going
