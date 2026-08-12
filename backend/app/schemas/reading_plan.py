from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class PlanType(str, Enum):
    annual = "annual"
    topical = "topical"


class ReadingPlanCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    plan_type: PlanType = PlanType.topical


class ReadingPlanRead(BaseModel):
    id: str
    title: str
    description: str | None
    plan_type: PlanType
    created_at: datetime


class ReadingPlanDayCreate(BaseModel):
    day_number: int = Field(ge=1)
    reference: str = Field(min_length=1, max_length=200)
    title: str | None = Field(default=None, max_length=200)


class ReadingPlanDayRead(BaseModel):
    id: str
    plan_id: str
    day_number: int
    reference: str
    title: str | None
