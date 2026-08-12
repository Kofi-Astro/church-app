from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

PLANS_TABLE = "reading_plans"
DAYS_TABLE = "reading_plan_days"


class ReadingPlanRepository:
    def __init__(self, client: Client):
        self._client = client

    def list_plans(self) -> list[dict]:
        response = self._client.table(PLANS_TABLE).select("*").order("title").execute()
        return response.data or []

    def get_plan(self, plan_id: str) -> dict | None:
        response = (
            self._client.table(PLANS_TABLE).select("*").eq("id", plan_id).maybe_single().execute()
        )
        return response.data if response else None

    def create_plan(self, data: dict) -> dict:
        response = self._client.table(PLANS_TABLE).insert(data).execute()
        return response.data[0]

    def list_days(self, plan_id: str) -> list[dict]:
        response = (
            self._client.table(DAYS_TABLE)
            .select("*")
            .eq("plan_id", plan_id)
            .order("day_number")
            .execute()
        )
        return response.data or []

    def create_day(self, data: dict) -> dict:
        response = self._client.table(DAYS_TABLE).insert(data).execute()
        return response.data[0]


def get_reading_plan_repository(client: Client = Depends(get_supabase)) -> ReadingPlanRepository:
    return ReadingPlanRepository(client)
