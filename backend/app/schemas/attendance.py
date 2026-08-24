"""
Pydantic schemas for church services and attendance check-ins.

A "service" is one occurrence of a gathering (e.g. "Sunday 9am Service" on a
given date). "Attendance" rows record which member checked in to which
service. AttendanceReportRow is a read-only summary row used for reporting
(counts per service), not a table of its own.
"""
from datetime import date, datetime

from pydantic import BaseModel, Field


class ServiceCreate(BaseModel):
    """Payload for creating a new service (e.g. a specific Sunday's gathering)."""

    name: str = Field(min_length=1, max_length=200)
    service_date: date
    # Which congregation (English, Akan, Youth Chapel, ...) this specific
    # dated gathering is for — required so every new service is attributed
    # to one of the church's standing service tracks. See
    # app/schemas/congregation.py.
    congregation_id: str


class ServiceRead(BaseModel):
    """A service as returned by the API, including its generated id and creation time."""

    id: str
    name: str
    service_date: date
    # Nullable in the read model even though creation requires it, since
    # older rows from before congregations existed may not have one.
    congregation_id: str | None
    created_at: datetime


class AttendanceCreate(BaseModel):
    """Payload for checking a member in to a service."""

    service_id: str
    member_id: str


class AttendanceRead(BaseModel):
    """An attendance record as returned by the API."""

    id: str
    service_id: str
    member_id: str
    checked_in_at: datetime
    # Profile id of whoever performed the check-in (e.g. an admin checking in
    # a member at the door). None if the check-in wasn't attributed to anyone.
    checked_in_by: str | None


class AttendanceReportRow(BaseModel):
    """One row of an attendance report: a service plus how many people attended it."""

    service_id: str
    service_name: str
    service_date: date
    # Which congregation this service belonged to — lets the report be
    # filtered/grouped per congregation instead of relying on parsing
    # service names.
    congregation_id: str | None
    attendee_count: int
