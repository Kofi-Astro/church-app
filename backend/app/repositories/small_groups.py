from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

GROUPS_TABLE = "small_groups"
MEMBERS_TABLE = "group_members"
MATERIALS_TABLE = "group_materials"


class SmallGroupRepository:
    def __init__(self, client: Client):
        self._client = client

    def list_groups(self) -> list[dict]:
        response = self._client.table(GROUPS_TABLE).select("*").order("name").execute()
        return response.data or []

    def get_group(self, group_id: str) -> dict | None:
        response = (
            self._client.table(GROUPS_TABLE).select("*").eq("id", group_id).maybe_single().execute()
        )
        return response.data if response else None

    def create_group(self, data: dict) -> dict:
        response = self._client.table(GROUPS_TABLE).insert(data).execute()
        return response.data[0]

    def is_leader(self, group_id: str, profile_id: str) -> bool:
        group = self.get_group(group_id)
        return group is not None and group.get("leader_id") == profile_id

    def list_members(self, group_id: str) -> list[dict]:
        response = (
            self._client.table(MEMBERS_TABLE).select("*").eq("group_id", group_id).execute()
        )
        return response.data or []

    def is_member(self, group_id: str, profile_id: str) -> bool:
        response = (
            self._client.table(MEMBERS_TABLE)
            .select("group_id")
            .eq("group_id", group_id)
            .eq("profile_id", profile_id)
            .maybe_single()
            .execute()
        )
        return bool(response and response.data)

    def add_member(self, group_id: str, profile_id: str) -> dict:
        response = (
            self._client.table(MEMBERS_TABLE)
            .insert({"group_id": group_id, "profile_id": profile_id})
            .execute()
        )
        return response.data[0]

    def remove_member(self, group_id: str, profile_id: str) -> bool:
        response = (
            self._client.table(MEMBERS_TABLE)
            .delete()
            .eq("group_id", group_id)
            .eq("profile_id", profile_id)
            .execute()
        )
        return bool(response.data)

    def list_materials(self, group_id: str) -> list[dict]:
        response = (
            self._client.table(MATERIALS_TABLE)
            .select("*")
            .eq("group_id", group_id)
            .order("created_at", desc=True)
            .execute()
        )
        return response.data or []

    def create_material(self, data: dict) -> dict:
        response = self._client.table(MATERIALS_TABLE).insert(data).execute()
        return response.data[0]

    def delete_material(self, material_id: str) -> bool:
        response = self._client.table(MATERIALS_TABLE).delete().eq("id", material_id).execute()
        return bool(response.data)


def get_small_group_repository(client: Client = Depends(get_supabase)) -> SmallGroupRepository:
    return SmallGroupRepository(client)
