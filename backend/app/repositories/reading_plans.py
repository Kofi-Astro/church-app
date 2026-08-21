"""
Persistence for Bible reading plans and their individual days. See
app/repositories/households.py for why repositories are kept separate from
routers.
"""
from fastapi import Depends
from supabase import Client  # type: ignore[import]

from app.core.supabase import get_supabase

PLANS_TABLE = "reading_plans"
DAYS_TABLE = "reading_plan_days"


class ReadingPlanRepository:
    """Supabase-backed storage for reading_plans and reading_plan_days."""

    def __init__(self, client: Client):
        self._client = client

    def list_plans(self) -> list[dict]:
        """Lists all reading plans, alphabetical by title."""
        response = self._client.table(PLANS_TABLE).select("*").order("title").execute()
        return response.data or []

    def get_plan(self, plan_id: str) -> dict | None:
        """Fetches one reading plan by id, or None if it doesn't exist."""
        response = (
            self._client.table(PLANS_TABLE).select("*").eq("id", plan_id).maybe_single().execute()
        )
        return response.data if response else None

    def create_plan(self, data: dict) -> dict:
        """Inserts a new reading plan row and returns it."""
        response = self._client.table(PLANS_TABLE).insert(data).execute()
        return response.data[0]

    def list_days(self, plan_id: str) -> list[dict]:
        """Lists a plan's days in order (day 1, day 2, ...)."""
        response = (
            self._client.table(DAYS_TABLE)
            .select("*")
            .eq("plan_id", plan_id)
            .order("day_number")
            .execute()
        )
        return response.data or []

    def create_day(self, data: dict) -> dict:
        """Inserts a new reading-plan-day row and returns it."""
        response = self._client.table(DAYS_TABLE).insert(data).execute()
        return response.data[0]


def get_reading_plan_repository(client: Client = Depends(get_supabase)) -> ReadingPlanRepository:
    """FastAPI dependency that builds a ReadingPlanRepository from the shared Supabase client."""
    return ReadingPlanRepository(client)
