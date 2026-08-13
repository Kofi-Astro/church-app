from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

TABLE = "giving_transactions"


class GivingRepository:
    def __init__(self, client: Client):
        self._client = client

    def create_pending(self, data: dict) -> dict:
        response = self._client.table(TABLE).insert({**data, "status": "pending"}).execute()
        return response.data[0]

    def list_for_profile(
        self, profile_id: str, *, limit: int, offset: int
    ) -> tuple[list[dict], int]:
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
        response = (
            self._client.table(TABLE)
            .select("*", count="exact")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        return response.data or [], response.count or 0


def get_giving_repository(client: Client = Depends(get_supabase)) -> GivingRepository:
    return GivingRepository(client)
