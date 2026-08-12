from datetime import datetime

from pydantic import BaseModel, Field


class SmallGroupCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    leader_id: str | None = None


class SmallGroupRead(BaseModel):
    id: str
    name: str
    description: str | None
    leader_id: str | None
    created_at: datetime


class GroupMemberAdd(BaseModel):
    profile_id: str


class GroupMemberRead(BaseModel):
    group_id: str
    profile_id: str
    joined_at: datetime


class GroupMaterialCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    url: str | None = Field(default=None, max_length=500)
    description: str | None = Field(default=None, max_length=2000)


class GroupMaterialRead(BaseModel):
    id: str
    group_id: str
    title: str
    url: str | None
    description: str | None
    created_at: datetime
