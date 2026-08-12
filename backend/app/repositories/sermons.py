from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

TABLE = "sermons"


class SermonRepository:
    def __init__(self, client: Client):
        self._client = client

    def list(
        self,
        *,
        limit: int,
        offset: int,
        series: str | None = None,
        speaker: str | None = None,
        search: str | None = None,
    ) -> tuple[list[dict], int]:
        query = self._client.table(TABLE).select("*", count="exact")
        if series:
            query = query.eq("series", series)
        if speaker:
            query = query.eq("speaker", speaker)
        if search:
            query = query.ilike("title", f"%{search}%")
        response = (
            query.order("sermon_date", desc=True).range(offset, offset + limit - 1).execute()
        )
        return response.data or [], response.count or 0

    def get(self, sermon_id: str) -> dict | None:
        response = (
            self._client.table(TABLE).select("*").eq("id", sermon_id).maybe_single().execute()
        )
        return response.data if response else None

    def create(self, data: dict) -> dict:
        response = self._client.table(TABLE).insert(data).execute()
        return response.data[0]

    def update(self, sermon_id: str, data: dict) -> dict | None:
        response = self._client.table(TABLE).update(data).eq("id", sermon_id).execute()
        return response.data[0] if response.data else None

    def delete(self, sermon_id: str) -> bool:
        response = self._client.table(TABLE).delete().eq("id", sermon_id).execute()
        return bool(response.data)


def get_sermon_repository(client: Client = Depends(get_supabase)) -> SermonRepository:
    return SermonRepository(client)
