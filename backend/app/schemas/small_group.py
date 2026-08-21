"""
Pydantic schemas for small groups (e.g. Bible study/life groups): the groups
themselves, their membership rosters, and study materials shared within a
group.
"""
from datetime import datetime

from pydantic import BaseModel, Field


class SmallGroupCreate(BaseModel):
    """Payload for creating a new small group."""

    name: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    # Profile id of the member leading this group, if assigned yet.
    leader_id: str | None = None


class SmallGroupRead(BaseModel):
    """A small group as returned by the API."""

    id: str
    name: str
    description: str | None
    leader_id: str | None
    created_at: datetime


class GroupMemberAdd(BaseModel):
    """Payload for adding a member to a small group's roster."""

    profile_id: str


class GroupMemberRead(BaseModel):
    """One row of a small group's membership roster, as returned by the API."""

    group_id: str
    profile_id: str
    joined_at: datetime


class GroupMaterialCreate(BaseModel):
    """Payload for adding a study material/resource to a small group."""

    title: str = Field(min_length=1, max_length=200)
    # Link to the material (e.g. a PDF or video), if it's hosted elsewhere.
    url: str | None = Field(default=None, max_length=500)
    description: str | None = Field(default=None, max_length=2000)


class GroupMaterialRead(BaseModel):
    """A small group's study material as returned by the API."""

    id: str
    group_id: str
    title: str
    url: str | None
    description: str | None
    created_at: datetime
