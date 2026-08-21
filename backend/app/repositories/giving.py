"""
Persistence for giving transactions (Paystack-backed donations). See
app/repositories/households.py for why repositories are kept separate from
routers.
"""
from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

TABLE = "giving_transactions"


class GivingRepository:
    """Supabase-backed storage for giving_transactions."""

    def __init__(self, client: Client):
        self._client = client

    def create_pending(self, data: dict) -> dict:
        """
        Inserts a new transaction row with status forced to "pending" — used right
        after asking Paystack to initialize a transaction, before payment completes.
        """
        response = self._client.table(TABLE).insert({**data, "status": "pending"}).execute()
        return response.data[0]

    def list_for_profile(
        self, profile_id: str, *, limit: int, offset: int
    ) -> tuple[list[dict], int]:
        """
        Paginated giving history for one profile (a member viewing their own
        history), newest first. Returns (rows, total_count).
        """
        response = (
            self._client.table(TABLE)
            .select("*", count="exact")
            .eq("profile_id", profile_id)
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        return response.data or [], response.count or 0

    def list_all(self, *, limit: int, offset: int) -> tuple[list[dict], int]:
        """
        Paginated giving history across every profile (finance_admin view of all
        transactions), newest first. Returns (rows, total_count).
        """
        response = (
            self._client.table(TABLE)
            .select("*", count="exact")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        return response.data or [], response.count or 0


def get_giving_repository(client: Client = Depends(get_supabase)) -> GivingRepository:
    """FastAPI dependency that builds a GivingRepository from the shared Supabase client."""
    return GivingRepository(client)
