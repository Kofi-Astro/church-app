"""
Persistence for services (individual gatherings) and attendance check-ins.
See app/repositories/households.py for why repositories are kept separate
from routers.
"""
from datetime import date

from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

SERVICES_TABLE = "services"
ATTENDANCE_TABLE = "attendance"


class AttendanceRepository:
    """Supabase-backed storage for services and attendance records."""

    def __init__(self, client: Client):
        self._client = client

    def create_service(self, data: dict) -> dict:
        """Inserts a new service row and returns it."""
        response = self._client.table(SERVICES_TABLE).insert(data).execute()
        return response.data[0]

    def list_services(
        self, *, start: date | None = None, end: date | None = None
    ) -> list[dict]:
        """Lists services, optionally restricted to a date range, newest first."""
        query = self._client.table(SERVICES_TABLE).select("*")
        if start:
            query = query.gte("service_date", start.isoformat())
        if end:
            query = query.lte("service_date", end.isoformat())
        response = query.order("service_date", desc=True).execute()
        return response.data or []

    def mark_attendance(self, data: dict) -> dict:
        """Inserts a new attendance (check-in) row and returns it."""
        response = self._client.table(ATTENDANCE_TABLE).insert(data).execute()
        return response.data[0]

    def list_for_service(self, service_id: str) -> list[dict]:
        """Lists every attendance record for a given service."""
        response = (
            self._client.table(ATTENDANCE_TABLE)
            .select("*")
            .eq("service_id", service_id)
            .execute()
        )
        return response.data or []

    def count_for_service(self, service_id: str) -> int:
        """
        Counts attendees for a service without fetching the rows themselves
        (head=True asks Postgres for just the count, which is cheaper).
        """
        response = (
            self._client.table(ATTENDANCE_TABLE)
            .select("id", count="exact", head=True)
            .eq("service_id", service_id)
            .execute()
        )
        return response.count or 0

    def report(self, *, start: date | None = None, end: date | None = None) -> list[dict]:
        """Attendee count per service in the given date range (inclusive)."""
        rows = []
        for service in self.list_services(start=start, end=end):
            rows.append(
                {
                    "service_id": service["id"],
                    "service_name": service["name"],
                    "service_date": service["service_date"],
                    "attendee_count": self.count_for_service(service["id"]),
                }
            )
        return rows


def get_attendance_repository(client: Client = Depends(get_supabase)) -> AttendanceRepository:
    """FastAPI dependency that builds an AttendanceRepository from the shared Supabase client."""
    return AttendanceRepository(client)
