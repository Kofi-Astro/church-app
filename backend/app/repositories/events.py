"""
Persistence for events and their RSVPs. See app/repositories/households.py
for why repositories are kept separate from routers.
"""
from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

EVENTS_TABLE = "events"
RSVPS_TABLE = "event_rsvps"

RSVP_STATUSES = ("going", "maybe", "not_going")


class EventRepository:
    """Supabase-backed storage for events and event_rsvps."""

    def __init__(self, client: Client):
        self._client = client

    def list(self) -> list[dict]:
        """Lists all events, soonest first."""
        response = self._client.table(EVENTS_TABLE).select("*").order("event_date").execute()
        return response.data or []

    def get(self, event_id: str) -> dict | None:
        """Fetches one event by id, or None if it doesn't exist."""
        response = (
            self._client.table(EVENTS_TABLE).select("*").eq("id", event_id).maybe_single().execute()
        )
        return response.data if response else None

    def create(self, data: dict) -> dict:
        """Inserts a new event row and returns it."""
        response = self._client.table(EVENTS_TABLE).insert(data).execute()
        return response.data[0]

    def delete(self, event_id: str) -> bool:
        """Deletes an event by id. Returns True if a row was actually deleted."""
        response = self._client.table(EVENTS_TABLE).delete().eq("id", event_id).execute()
        return bool(response.data)

    def rsvp_counts(self, event_id: str) -> dict[str, int]:
        """
        Tallies RSVPs for an event by status, e.g. {"going": 12, "maybe": 3,
        "not_going": 1}. Always includes all three statuses, even at zero.
        """
        response = (
            self._client.table(RSVPS_TABLE).select("status").eq("event_id", event_id).execute()
        )
        counts = dict.fromkeys(RSVP_STATUSES, 0)
        for row in response.data or []:
            counts[row["status"]] = counts.get(row["status"], 0) + 1
        return counts

    def my_rsvp(self, event_id: str, profile_id: str) -> str | None:
        """Returns a specific profile's RSVP status for an event, or None if they haven't RSVP'd."""
        response = (
            self._client.table(RSVPS_TABLE)
            .select("status")
            .eq("event_id", event_id)
            .eq("profile_id", profile_id)
            .maybe_single()
            .execute()
        )
        return response.data["status"] if response and response.data else None

    def upsert_rsvp(self, event_id: str, profile_id: str, status: str) -> None:
        """Creates or updates a profile's RSVP for an event (one RSVP per profile per event)."""
        self._client.table(RSVPS_TABLE).upsert(
            {"event_id": event_id, "profile_id": profile_id, "status": status}
        ).execute()

    def remove_rsvp(self, event_id: str, profile_id: str) -> None:
        """Deletes a profile's RSVP for an event (used when a member withdraws their RSVP)."""
        self._client.table(RSVPS_TABLE).delete().eq("event_id", event_id).eq(
            "profile_id", profile_id
        ).execute()


def get_event_repository(client: Client = Depends(get_supabase)) -> EventRepository:
    """FastAPI dependency that builds an EventRepository from the shared Supabase client."""
    return EventRepository(client)
