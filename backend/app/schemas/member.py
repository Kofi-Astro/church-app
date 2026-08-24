"""
Pydantic schemas for the member directory — the congregation's roster of
people, separate from `profiles` (which is only for people who have an app
login). Not every member has a login/profile; not every profile is a member.
"""
from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class MemberCreate(BaseModel):
    """Payload for adding a new member to the directory."""

    full_name: str = Field(min_length=1, max_length=200)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, max_length=30)
    # Optional link to the household this member belongs to.
    household_id: str | None = None
    # Which congregation (English, Akan, Youth Chapel, ...) this member
    # primarily belongs to. Optional — e.g. a new visitor may not have one
    # assigned yet.
    congregation_id: str | None = None


class MemberUpdate(BaseModel):
    """Payload for editing a member. All fields optional — only send what's changing."""

    full_name: str | None = Field(default=None, min_length=1, max_length=200)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, max_length=30)
    household_id: str | None = None
    congregation_id: str | None = None


class MemberRead(BaseModel):
    """A member as returned by the API."""

    id: str
    # Linked profile id if this member also has an app login; None if they're
    # a directory-only entry (e.g. added by an admin but hasn't signed up).
    profile_id: str | None
    household_id: str | None
    congregation_id: str | None
    full_name: str
    email: str | None
    phone: str | None
    created_at: datetime
