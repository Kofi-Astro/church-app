"""
Household persistence. Thin wrapper around Supabase's PostgREST client —
kept separate from the router so business/validation logic and storage
concerns don't get tangled, and so tests can swap in an in-memory fake
without needing a live Supabase project.
"""
from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

TABLE = "households"


class HouseholdRepository:
    def __init__(self, client: Client):
        self._client = client

    def list(self, *, limit: int, offset: int) -> tuple[list[dict], int]:
        response = (
            self._client.table(TABLE)
            .select("*", count="exact")
            .order("name")
            .range(offset, offset + limit - 1)
            .execute()
        )
        return response.data or [], response.count or 0

    def get(self, household_id: str) -> dict | None:
        response = (
            self._client.table(TABLE).select("*").eq("id", household_id).maybe_single().execute()
        )
        return response.data if response else None

    def create(self, data: dict) -> dict:
        response = self._client.table(TABLE).insert(data).execute()
        return response.data[0]

    def update(self, household_id: str, data: dict) -> dict | None:
        response = self._client.table(TABLE).update(data).eq("id", household_id).execute()
        return response.data[0] if response.data else None

    def delete(self, household_id: str) -> bool:
        response = self._client.table(TABLE).delete().eq("id", household_id).execute()
        return bool(response.data)


def get_household_repository(client: Client = Depends(get_supabase)) -> HouseholdRepository:
    return HouseholdRepository(client)
