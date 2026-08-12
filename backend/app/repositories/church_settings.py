from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

TABLE = "church_settings"
# Singleton row — see the `id boolean primary key` trick in
# infra/migrations/0003_content.sql.
ROW_ID = True


class ChurchSettingsRepository:
    def __init__(self, client: Client):
        self._client = client

    def get(self) -> dict:
        response = (
            self._client.table(TABLE).select("*").eq("id", ROW_ID).single().execute()
        )
        return response.data

    def update(self, data: dict) -> dict:
        response = self._client.table(TABLE).update(data).eq("id", ROW_ID).execute()
        return response.data[0]


def get_church_settings_repository(
    client: Client = Depends(get_supabase),
) -> ChurchSettingsRepository:
    return ChurchSettingsRepository(client)
