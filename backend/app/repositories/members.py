from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

TABLE = "members"


class MemberRepository:
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
        query = self._client.table(TABLE).select("*", count="exact")
        if search:
            term = f"%{search}%"
            query = query.or_(f"full_name.ilike.{term},email.ilike.{term},phone.ilike.{term}")
        if household_id:
            query = query.eq("household_id", household_id)
        response = query.order("full_name").range(offset, offset + limit - 1).execute()
        return response.data or [], response.count or 0

    def get(self, member_id: str) -> dict | None:
        response = (
            self._client.table(TABLE).select("*").eq("id", member_id).maybe_single().execute()
        )
        return response.data if response else None

    def create(self, data: dict) -> dict:
        response = self._client.table(TABLE).insert(data).execute()
        return response.data[0]

    def update(self, member_id: str, data: dict) -> dict | None:
        response = self._client.table(TABLE).update(data).eq("id", member_id).execute()
        return response.data[0] if response.data else None

    def delete(self, member_id: str) -> bool:
        response = self._client.table(TABLE).delete().eq("id", member_id).execute()
        return bool(response.data)


def get_member_repository(client: Client = Depends(get_supabase)) -> MemberRepository:
    return MemberRepository(client)
