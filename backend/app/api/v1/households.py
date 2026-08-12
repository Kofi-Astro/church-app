from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.deps import require_role
from app.repositories.households import HouseholdRepository, get_household_repository
from app.schemas.household import HouseholdCreate, HouseholdRead, HouseholdUpdate
from app.schemas.pagination import Page

router = APIRouter(prefix="/households", tags=["households"])

# Matches households RLS in 0001_init.sql: admin/finance_admin/group_leader read,
# admin-only write. Enforced here too so a denied call gets a clean 403.
# Defined as module-level singletons (rather than calling require_role(...)
# inline in each signature) so FastAPI's dependency-injection default isn't
# also flagged as a fresh-call-per-request default (ruff B008).
require_read = require_role("admin", "finance_admin", "group_leader")
require_write = require_role("admin")


@router.get("", response_model=Page[HouseholdRead])
async def list_households(
    limit: int = Query(default=25, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    repo: HouseholdRepository = Depends(get_household_repository),
    _profile=Depends(require_read),
):
    items, total = repo.list(limit=limit, offset=offset)
    return Page(items=items, total=total, limit=limit, offset=offset)


@router.get("/{household_id}", response_model=HouseholdRead)
async def get_household(
    household_id: str,
    repo: HouseholdRepository = Depends(get_household_repository),
    _profile=Depends(require_read),
):
    household = repo.get(household_id)
    if household is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Household not found")
    return household


@router.post("", response_model=HouseholdRead, status_code=status.HTTP_201_CREATED)
async def create_household(
    payload: HouseholdCreate,
    repo: HouseholdRepository = Depends(get_household_repository),
    _profile=Depends(require_write),
):
    return repo.create(payload.model_dump())


@router.patch("/{household_id}", response_model=HouseholdRead)
async def update_household(
    household_id: str,
    payload: HouseholdUpdate,
    repo: HouseholdRepository = Depends(get_household_repository),
    _profile=Depends(require_write),
):
    updated = repo.update(household_id, payload.model_dump(exclude_unset=True))
    if updated is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Household not found")
    return updated


@router.delete("/{household_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_household(
    household_id: str,
    repo: HouseholdRepository = Depends(get_household_repository),
    _profile=Depends(require_write),
):
    if not repo.delete(household_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Household not found")
