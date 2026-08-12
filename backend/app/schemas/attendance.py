from datetime import date, datetime

from pydantic import BaseModel, Field


class ServiceCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    service_date: date


class ServiceRead(BaseModel):
    id: str
    name: str
    service_date: date
    created_at: datetime


class AttendanceCreate(BaseModel):
    service_id: str
    member_id: str


class AttendanceRead(BaseModel):
    id: str
    service_id: str
    member_id: str
    checked_in_at: datetime
    checked_in_by: str | None


class AttendanceReportRow(BaseModel):
    service_id: str
    service_name: str
    service_date: date
    attendee_count: int
