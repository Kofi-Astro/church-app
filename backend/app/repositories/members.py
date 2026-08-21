"""
Persistence for the member directory. See app/repositories/households.py for
why repositories are kept separate from routers.
"""
from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

TABLE = "members"


class MemberRepository:
    """Supabase-backed storage for members."""

    def __init__(self, client: Client):
        self._client = client

    def list(
        self,
        *,
        limit: int,
        offset: int,
        search: str | None = None,
        household_id: str | None = None,
    ) -> tuple[list[dict], int]:
        """
        Paginated, alphabetical list of members. `search` does a case-insensitive
        partial match across name/email/phone; `household_id` filters to one
        household. Returns (rows, total_count).
        """
        query = self._client.table(TABLE).select("*", count="exact")
        if search:
            term = f"%{search}%"
            query = query.or_(f"full_name.ilike.{term},email.ilike.{term},phone.ilike.{term}")
        if household_id:
            query = query.eq("household_id", household_id)
        response = query.order("full_name").range(offset, offset + limit - 1).execute()
        return response.data or [], response.count or 0

    def get(self, member_id: str) -> dict | None:
        """Fetches one member by id, or None if they don't exist."""
        response = (
            self._client.table(TABLE).select("*").eq("id", member_id).maybe_single().execute()
        )
        return response.data if response else None

    def create(self, data: dict) -> dict:
        """Inserts a new member row and returns it."""
        response = self._client.table(TABLE).insert(data).execute()
        return response.data[0]

    def update(self, member_id: str, data: dict) -> dict | None:
        """Updates a member by id and returns the new row, or None if they didn't exist."""
        response = self._client.table(TABLE).update(data).eq("id", member_id).execute()
        return response.data[0] if response.data else None

    def delete(self, member_id: str) -> bool:
        """Deletes a member by id. Returns True if a row was actually deleted."""
        response = self._client.table(TABLE).delete().eq("id", member_id).execute()
        return bool(response.data)


def get_member_repository(client: Client = Depends(get_supabase)) -> MemberRepository:
    """FastAPI dependency that builds a MemberRepository from the shared Supabase client."""
    return MemberRepository(client)
