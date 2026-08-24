"""
Pydantic schemas for small groups: ordinary Bible study/life groups, and
auxiliaries (Men's/Women's Auxiliary, Baptist Young Men/Women, Girls'
Auxiliary, Royal Ambassadors, ...) — the groups themselves, their membership
rosters, and study materials shared within a group.

Auxiliaries deliberately reuse this same table/schema rather than getting a
separate one — structurally an auxiliary is identical to a small group (a
named group with a leader, a roster, and shared materials). `GroupCategory`
just lets the app section "Auxiliaries" apart from ordinary small groups
when listing them.
"""
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class GroupCategory(str, Enum):
    """Whether a `small_groups` row is an ordinary small group or a standing auxiliary."""

    small_group = "small_group"
    auxiliary = "auxiliary"


class SmallGroupCreate(BaseModel):
    """Payload for creating a new small group or auxiliary."""

    name: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    # Profile id of the member leading this group, if assigned yet.
    leader_id: str | None = None
    category: GroupCategory = GroupCategory.small_group


class SmallGroupRead(BaseModel):
    """A small group (or auxiliary) as returned by the API."""

    id: str
    name: str
    description: str | None
    leader_id: str | None
    category: GroupCategory
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
