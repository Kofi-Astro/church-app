"""
In-memory stand-ins for the Supabase-backed repositories, used so router
tests exercise real validation/role logic without needing a live Supabase
project. Kept intentionally minimal — just enough behavior for the router
tests in this package, not a full PostgREST simulator.
"""
import uuid
from datetime import UTC, datetime


def _new_id() -> str:
    return str(uuid.uuid4())


def _now() -> str:
    return datetime.now(UTC).isoformat()


class FakeHouseholdRepository:
    def __init__(self):
        self._rows: dict[str, dict] = {}

    def list(self, *, limit: int, offset: int):
        items = list(self._rows.values())[offset : offset + limit]
        return items, len(self._rows)

    def get(self, household_id: str):
        return self._rows.get(household_id)

    def create(self, data: dict):
        row = {**data, "id": _new_id(), "created_at": _now()}
        self._rows[row["id"]] = row
        return row

    def update(self, household_id: str, data: dict):
        if household_id not in self._rows:
            return None
        self._rows[household_id].update(data)
        return self._rows[household_id]

    def delete(self, household_id: str) -> bool:
        return self._rows.pop(household_id, None) is not None


class FakeMemberRepository:
    def __init__(self):
        self._rows: dict[str, dict] = {}

    def list(self, *, limit: int, offset: int, search: str | None = None, household_id=None):
        items = list(self._rows.values())
        if search:
            term = search.lower()
            items = [
                r
                for r in items
                if term in (r.get("full_name") or "").lower()
                or term in (r.get("email") or "").lower()
                or term in (r.get("phone") or "").lower()
            ]
        if household_id:
            items = [r for r in items if r.get("household_id") == household_id]
        return items[offset : offset + limit], len(items)

    def get(self, member_id: str):
        return self._rows.get(member_id)

    def create(self, data: dict):
        row = {"profile_id": None, **data, "id": _new_id(), "created_at": _now()}
        self._rows[row["id"]] = row
        return row

    def update(self, member_id: str, data: dict):
        if member_id not in self._rows:
            return None
        self._rows[member_id].update(data)
        return self._rows[member_id]

    def delete(self, member_id: str) -> bool:
        return self._rows.pop(member_id, None) is not None


class FakeAttendanceRepository:
    def __init__(self):
        self._services: dict[str, dict] = {}
        self._attendance: list[dict] = []

    def create_service(self, data: dict):
        row = {**data, "id": _new_id(), "created_at": _now()}
        self._services[row["id"]] = row
        return row

    def list_services(self, *, start=None, end=None):
        items = list(self._services.values())
        if start:
            items = [r for r in items if r["service_date"] >= start.isoformat()]
        if end:
            items = [r for r in items if r["service_date"] <= end.isoformat()]
        return sorted(items, key=lambda r: r["service_date"], reverse=True)

    def mark_attendance(self, data: dict):
        row = {**data, "id": _new_id(), "checked_in_at": _now()}
        self._attendance.append(row)
        return row

    def list_for_service(self, service_id: str):
        return [r for r in self._attendance if r["service_id"] == service_id]

    def count_for_service(self, service_id: str) -> int:
        return len(self.list_for_service(service_id))

    def report(self, *, start=None, end=None):
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


class FakeSermonRepository:
    def __init__(self):
        self._rows: dict[str, dict] = {}

    def list(
        self,
        *,
        limit: int,
        offset: int,
        series: str | None = None,
        speaker: str | None = None,
        search: str | None = None,
    ):
        items = list(self._rows.values())
        if series:
            items = [r for r in items if r.get("series") == series]
        if speaker:
            items = [r for r in items if r.get("speaker") == speaker]
        if search:
            term = search.lower()
            items = [r for r in items if term in (r.get("title") or "").lower()]
        items = sorted(items, key=lambda r: r["sermon_date"], reverse=True)
        return items[offset : offset + limit], len(items)

    def get(self, sermon_id: str):
        return self._rows.get(sermon_id)

    def create(self, data: dict):
        row = {"speaker": None, "series": None, "video_url": None, "description": None, **data,
               "id": _new_id(), "created_at": _now()}
        self._rows[row["id"]] = row
        return row

    def update(self, sermon_id: str, data: dict):
        if sermon_id not in self._rows:
            return None
        self._rows[sermon_id].update(data)
        return self._rows[sermon_id]

    def delete(self, sermon_id: str) -> bool:
        return self._rows.pop(sermon_id, None) is not None


class FakeChurchSettingsRepository:
    def __init__(self):
        self._row = {"livestream_url": None, "updated_at": _now()}

    def get(self):
        return self._row

    def update(self, data: dict):
        self._row.update(data)
        self._row["updated_at"] = _now()
        return self._row
