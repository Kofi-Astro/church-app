"""
Pydantic schemas for church events (e.g. picnics, conferences, outreach) and
member RSVPs to them.
"""
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class RsvpStatus(str, Enum):
    """The three ways a member can respond to an event invite."""

    going = "going"
    maybe = "maybe"
    not_going = "not_going"


class EventCreate(BaseModel):
    """Payload for creating a new event."""

    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    event_date: datetime
    location: str | None = Field(default=None, max_length=300)


class EventRead(BaseModel):
    """An event as returned by the API, enriched with RSVP info for convenience."""

    id: str
    title: str
    description: str | None
    event_date: datetime
    location: str | None
    created_at: datetime
    # Tally of RSVPs by status, e.g. {"going": 12, "maybe": 3, "not_going": 1}.
    rsvp_counts: dict[str, int]
    # The current caller's own RSVP status, or None if they haven't RSVP'd yet.
    my_rsvp: RsvpStatus | None


class RsvpCreate(BaseModel):
    """Payload for a member RSVP'ing to an event; defaults to "going"."""

    status: RsvpStatus = RsvpStatus.going
