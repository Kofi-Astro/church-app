from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class MemberCreate(BaseModel):
    full_name: str = Field(min_length=1, max_length=200)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, max_length=30)
    household_id: str | None = None


class MemberUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=200)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, max_length=30)
    household_id: str | None = None


class MemberRead(BaseModel):
    id: str
    profile_id: str | None
    household_id: str | None
    full_name: str
    email: str | None
    phone: str | None
    created_at: datetime
