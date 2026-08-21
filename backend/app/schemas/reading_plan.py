"""
Pydantic schemas for Bible reading plans — a plan (e.g. "Read the Bible in a
Year") made up of numbered days, each pointing to a scripture reference.
Per-user progress through a plan is tracked directly in Supabase from the
mobile app, not through this backend (see app/main.py's Phase 3 note).
"""
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class PlanType(str, Enum):
    """Whether a plan spans a full year or covers a shorter topical study."""

    annual = "annual"
    topical = "topical"


class ReadingPlanCreate(BaseModel):
    """Payload for creating a new reading plan."""

    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    plan_type: PlanType = PlanType.topical


class ReadingPlanRead(BaseModel):
    """A reading plan as returned by the API (without its individual days)."""

    id: str
    title: str
    description: str | None
    plan_type: PlanType
    created_at: datetime


class ReadingPlanDayCreate(BaseModel):
    """Payload for adding one day's reading to a plan."""

    # 1-based position of this day within the plan (day 1, day 2, ...).
    day_number: int = Field(ge=1)
    # The scripture passage for this day, e.g. "John 3:1-21".
    reference: str = Field(min_length=1, max_length=200)
    title: str | None = Field(default=None, max_length=200)


class ReadingPlanDayRead(BaseModel):
    """One day of a reading plan as returned by the API."""

    id: str
    plan_id: str
    day_number: int
    reference: str
    title: str | None
