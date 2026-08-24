"""
Persistence for congregations. See app/repositories/households.py for why
repositories are kept separate from routers.
"""
from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

TABLE = "congregations"


class CongregationRepository:
    """Supabase-backed storage for congregations."""

    def __init__(self, client: Client):
        self._client = client

    def list(self) -> list[dict]:
        """Lists all congregations, alphabetical by name."""
        response = self._client.table(TABLE).select("*").order("name").execute()
        return response.data or []

    def get(self, congregation_id: str) -> dict | None:
        """Fetches one congregation by id, or None if it doesn't exist."""
        response = (
            self._client.table(TABLE)
            .select("*")
            .eq("id", congregation_id)
            .maybe_single()
            .execute()
        )
        return response.data if response else None

    def create(self, data: dict) -> dict:
        """Inserts a new congregation row and returns it."""
        response = self._client.table(TABLE).insert(data).execute()
        return response.data[0]

    def update(self, congregation_id: str, data: dict) -> dict | None:
        """Updates a congregation by id and returns the new row, or None if it didn't exist."""
        response = self._client.table(TABLE).update(data).eq("id", congregation_id).execute()
        return response.data[0] if response.data else None

    def delete(self, congregation_id: str) -> bool:
        """Deletes a congregation by id. Returns True if a row was actually deleted."""
        response = self._client.table(TABLE).delete().eq("id", congregation_id).execute()
        return bool(response.data)


def get_congregation_repository(client: Client = Depends(get_supabase)) -> CongregationRepository:
    """FastAPI dependency that builds a CongregationRepository from the shared Supabase client."""
    return CongregationRepository(client)
