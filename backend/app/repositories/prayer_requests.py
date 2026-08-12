from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase
from app.schemas.profile import Profile

REQUESTS_TABLE = "prayer_requests"
INTERACTIONS_TABLE = "prayer_interactions"

LEADER_ROLES = ("admin", "group_leader", "finance_admin")


def can_view_prayer_request(profile: Profile, request: dict) -> bool:
    """
    The single source of truth for prayer-request visibility — used by
    both the list and get-one endpoints so they can never drift apart.

    Deliberately no admin override on 'private': the threat model calls
    prayer-request visibility bugs the most damaging failure mode in this
    app, so 'private' means the author and only the author, full stop.
    See backend/tests/test_prayer_requests.py for the negative tests that
    pin this down, including for an admin account.
    """
    if request["profile_id"] == profile.id:
        return True
    if request["visibility"] == "public":
        return True
    if request["visibility"] == "leaders" and profile.role in LEADER_ROLES:
        return True
    return False


class PrayerRequestRepository:
    def __init__(self, client: Client):
        self._client = client

    def create(self, data: dict) -> dict:
        response = self._client.table(REQUESTS_TABLE).insert(data).execute()
        return response.data[0]

    def list_all(self) -> list[dict]:
        response = (
            self._client.table(REQUESTS_TABLE).select("*").order("created_at", desc=True).execute()
        )
        return response.data or []

    def get(self, request_id: str) -> dict | None:
        response = (
            self._client.table(REQUESTS_TABLE)
            .select("*")
            .eq("id", request_id)
            .maybe_single()
            .execute()
        )
        return response.data if response else None

    def delete(self, request_id: str) -> bool:
        response = self._client.table(REQUESTS_TABLE).delete().eq("id", request_id).execute()
        return bool(response.data)

    def praying_count(self, request_id: str) -> int:
        response = (
            self._client.table(INTERACTIONS_TABLE)
            .select("id", count="exact", head=True)
            .eq("request_id", request_id)
            .execute()
        )
        return response.count or 0

    def is_praying(self, request_id: str, profile_id: str) -> bool:
        response = (
            self._client.table(INTERACTIONS_TABLE)
            .select("id")
            .eq("request_id", request_id)
            .eq("profile_id", profile_id)
            .maybe_single()
            .execute()
        )
        return bool(response and response.data)

    def add_interaction(self, request_id: str, profile_id: str) -> None:
        self._client.table(INTERACTIONS_TABLE).upsert(
            {"request_id": request_id, "profile_id": profile_id}
        ).execute()

    def remove_interaction(self, request_id: str, profile_id: str) -> None:
        self._client.table(INTERACTIONS_TABLE).delete().eq("request_id", request_id).eq(
            "profile_id", profile_id
        ).execute()


def get_prayer_request_repository(
    client: Client = Depends(get_supabase),
) -> PrayerRequestRepository:
    return PrayerRequestRepository(client)
