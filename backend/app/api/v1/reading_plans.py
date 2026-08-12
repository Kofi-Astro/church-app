from fastapi import APIRouter, Depends, HTTPException, status

from app.core.deps import get_current_profile, require_role
from app.repositories.reading_plans import ReadingPlanRepository, get_reading_plan_repository
from app.schemas.reading_plan import (
    ReadingPlanCreate,
    ReadingPlanDayCreate,
    ReadingPlanDayRead,
    ReadingPlanRead,
)

router = APIRouter(prefix="/reading-plans", tags=["reading-plans"])

# Plan content (not progress — see reading_plan_progress in
# infra/migrations/0004_reading_plans_and_groups.sql, which the mobile
# app writes directly to Supabase) is congregation-readable, admin-managed.
require_write = require_role("admin")


@router.get("", response_model=list[ReadingPlanRead])
async def list_reading_plans(
    repo: ReadingPlanRepository = Depends(get_reading_plan_repository),
    _profile=Depends(get_current_profile),
):
    return repo.list_plans()


@router.get("/{plan_id}", response_model=ReadingPlanRead)
async def get_reading_plan(
    plan_id: str,
    repo: ReadingPlanRepository = Depends(get_reading_plan_repository),
    _profile=Depends(get_current_profile),
):
    plan = repo.get_plan(plan_id)
    if plan is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reading plan not found")
    return plan


@router.post("", response_model=ReadingPlanRead, status_code=status.HTTP_201_CREATED)
async def create_reading_plan(
    payload: ReadingPlanCreate,
    repo: ReadingPlanRepository = Depends(get_reading_plan_repository),
    profile=Depends(require_write),
):
    data = payload.model_dump()
    data["created_by"] = profile.id
    return repo.create_plan(data)


@router.get("/{plan_id}/days", response_model=list[ReadingPlanDayRead])
async def list_reading_plan_days(
    plan_id: str,
    repo: ReadingPlanRepository = Depends(get_reading_plan_repository),
    _profile=Depends(get_current_profile),
):
    if repo.get_plan(plan_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reading plan not found")
    return repo.list_days(plan_id)


@router.post(
    "/{plan_id}/days", response_model=ReadingPlanDayRead, status_code=status.HTTP_201_CREATED
)
async def create_reading_plan_day(
    plan_id: str,
    payload: ReadingPlanDayCreate,
    repo: ReadingPlanRepository = Depends(get_reading_plan_repository),
    _profile=Depends(require_write),
):
    if repo.get_plan(plan_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reading plan not found")
    data = payload.model_dump()
    data["plan_id"] = plan_id
    return repo.create_day(data)
