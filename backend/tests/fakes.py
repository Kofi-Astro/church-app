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


class FakeReadingPlanRepository:
    def __init__(self):
        self._plans: dict[str, dict] = {}
        self._days: dict[str, dict] = {}

    def list_plans(self):
        return sorted(self._plans.values(), key=lambda r: r["title"])

    def get_plan(self, plan_id: str):
        return self._plans.get(plan_id)

    def create_plan(self, data: dict):
        row = {"description": None, **data, "id": _new_id(), "created_at": _now()}
        self._plans[row["id"]] = row
        return row

    def list_days(self, plan_id: str):
        days = [d for d in self._days.values() if d["plan_id"] == plan_id]
        return sorted(days, key=lambda d: d["day_number"])

    def create_day(self, data: dict):
        row = {"title": None, **data, "id": _new_id()}
        self._days[row["id"]] = row
        return row


class FakeSmallGroupRepository:
    def __init__(self):
        self._groups: dict[str, dict] = {}
        self._members: set[tuple[str, str]] = set()
        self._materials: dict[str, dict] = {}

    def list_groups(self):
        return sorted(self._groups.values(), key=lambda r: r["name"])

    def get_group(self, group_id: str):
        return self._groups.get(group_id)

    def create_group(self, data: dict):
        row = {
            "description": None,
            "leader_id": None,
            **data,
            "id": _new_id(),
            "created_at": _now(),
        }
        self._groups[row["id"]] = row
        return row

    def is_leader(self, group_id: str, profile_id: str) -> bool:
        group = self.get_group(group_id)
        return group is not None and group.get("leader_id") == profile_id

    def list_members(self, group_id: str):
        return [
            {"group_id": g, "profile_id": p, "joined_at": _now()}
            for (g, p) in self._members
            if g == group_id
        ]

    def is_member(self, group_id: str, profile_id: str) -> bool:
        return (group_id, profile_id) in self._members

    def add_member(self, group_id: str, profile_id: str):
        self._members.add((group_id, profile_id))
        return {"group_id": group_id, "profile_id": profile_id, "joined_at": _now()}

    def remove_member(self, group_id: str, profile_id: str) -> bool:
        if (group_id, profile_id) not in self._members:
            return False
        self._members.discard((group_id, profile_id))
        return True

    def list_materials(self, group_id: str):
        items = [m for m in self._materials.values() if m["group_id"] == group_id]
        return sorted(items, key=lambda m: m["created_at"], reverse=True)

    def create_material(self, data: dict):
        row = {"url": None, "description": None, **data, "id": _new_id(), "created_at": _now()}
        self._materials[row["id"]] = row
        return row

    def delete_material(self, material_id: str) -> bool:
        return self._materials.pop(material_id, None) is not None


class FakePrayerRequestRepository:
    def __init__(self):
        self._requests: dict[str, dict] = {}
        self._interactions: set[tuple[str, str]] = set()

    def create(self, data: dict):
        row = {**data, "id": _new_id(), "created_at": _now()}
        self._requests[row["id"]] = row
        return row

    def list_all(self):
        return sorted(self._requests.values(), key=lambda r: r["created_at"], reverse=True)

    def get(self, request_id: str):
        return self._requests.get(request_id)

    def delete(self, request_id: str) -> bool:
        return self._requests.pop(request_id, None) is not None

    def praying_count(self, request_id: str) -> int:
        return sum(1 for (rid, _) in self._interactions if rid == request_id)

    def is_praying(self, request_id: str, profile_id: str) -> bool:
        return (request_id, profile_id) in self._interactions

    def add_interaction(self, request_id: str, profile_id: str) -> None:
        self._interactions.add((request_id, profile_id))

    def remove_interaction(self, request_id: str, profile_id: str) -> None:
        self._interactions.discard((request_id, profile_id))


class FakeEventRepository:
    def __init__(self):
        self._events: dict[str, dict] = {}
        self._rsvps: dict[tuple[str, str], str] = {}

    def list(self):
        return sorted(self._events.values(), key=lambda e: e["event_date"])

    def get(self, event_id: str):
        return self._events.get(event_id)

    def create(self, data: dict):
        row = {"description": None, "location": None, **data, "id": _new_id(), "created_at": _now()}
        self._events[row["id"]] = row
        return row

    def delete(self, event_id: str) -> bool:
        return self._events.pop(event_id, None) is not None

    def rsvp_counts(self, event_id: str):
        counts = {"going": 0, "maybe": 0, "not_going": 0}
        for (eid, _), status in self._rsvps.items():
            if eid == event_id:
                counts[status] += 1
        return counts

    def my_rsvp(self, event_id: str, profile_id: str):
        return self._rsvps.get((event_id, profile_id))

    def upsert_rsvp(self, event_id: str, profile_id: str, status: str) -> None:
        self._rsvps[(event_id, profile_id)] = status

    def remove_rsvp(self, event_id: str, profile_id: str) -> None:
        self._rsvps.pop((event_id, profile_id), None)
