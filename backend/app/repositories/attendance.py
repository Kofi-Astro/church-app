from datetime import date

from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

SERVICES_TABLE = "services"
ATTENDANCE_TABLE = "attendance"


class AttendanceRepository:
    def __init__(self, client: Client):
        self._client = client

    def create_service(self, data: dict) -> dict:
        response = self._client.table(SERVICES_TABLE).insert(data).execute()
        return response.data[0]

    def list_services(
        self, *, start: date | None = None, end: date | None = None
    ) -> list[dict]:
        query = self._client.table(SERVICES_TABLE).select("*")
        if start:
            query = query.gte("service_date", start.isoformat())
        if end:
            query = query.lte("service_date", end.isoformat())
        response = query.order("service_date", desc=True).execute()
        return response.data or []

    def mark_attendance(self, data: dict) -> dict:
        response = self._client.table(ATTENDANCE_TABLE).insert(data).execute()
        return response.data[0]

    def list_for_service(self, service_id: str) -> list[dict]:
        response = (
            self._client.table(ATTENDANCE_TABLE)
            .select("*")
            .eq("service_id", service_id)
            .execute()
        )
        return response.data or []

    def count_for_service(self, service_id: str) -> int:
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
    return AttendanceRepository(client)
