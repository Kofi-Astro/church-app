"""
Persistence for prayer requests and the "praying" interactions members can
leave on them, plus the shared visibility rule (can_view_prayer_request) that
both the list and single-item endpoints rely on.
"""
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
    """
    Supabase-backed storage for prayer_requests and prayer_interactions. Note
    that list_all/get return every row regardless of visibility — filtering by
    can_view_prayer_request happens at the API layer, not here.
    """

    def __init__(self, client: Client):
        self._client = client

    def create(self, data: dict) -> dict:
        """Inserts a new prayer request row and returns it."""
        response = self._client.table(REQUESTS_TABLE).insert(data).execute()
        return response.data[0]

    def list_all(self) -> list[dict]:
        """Returns every prayer request, newest first, unfiltered by visibility."""
        response = (
            self._client.table(REQUESTS_TABLE).select("*").order("created_at", desc=True).execute()
        )
        return response.data or []

    def get(self, request_id: str) -> dict | None:
        """Fetches one prayer request by id, or None if it doesn't exist."""
        response = (
            self._client.table(REQUESTS_TABLE)
            .select("*")
            .eq("id", request_id)
            .maybe_single()
            .execute()
        )
        return response.data if response else None

    def delete(self, request_id: str) -> bool:
        """Deletes a prayer request by id. Returns True if a row was actually deleted."""
        response = self._client.table(REQUESTS_TABLE).delete().eq("id", request_id).execute()
        return bool(response.data)

    def praying_count(self, request_id: str) -> int:
        """Counts how many people have marked that they're praying for this request."""
        response = (
            self._client.table(INTERACTIONS_TABLE)
            .select("id", count="exact", head=True)
            .eq("request_id", request_id)
            .execute()
        )
        return response.count or 0

    def is_praying(self, request_id: str, profile_id: str) -> bool:
        """Whether a specific profile has marked that they're praying for this request."""
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
        """Marks a profile as "praying" for a request (idempotent via upsert)."""
        self._client.table(INTERACTIONS_TABLE).upsert(
            {"request_id": request_id, "profile_id": profile_id}
        ).execute()

    def remove_interaction(self, request_id: str, profile_id: str) -> None:
        """Un-marks a profile as "praying" for a request."""
        self._client.table(INTERACTIONS_TABLE).delete().eq("request_id", request_id).eq(
            "profile_id", profile_id
        ).execute()


def get_prayer_request_repository(
    client: Client = Depends(get_supabase),
) -> PrayerRequestRepository:
    """FastAPI dependency that builds a PrayerRequestRepository from the shared client."""
    return PrayerRequestRepository(client)
