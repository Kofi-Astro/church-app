"""Routes for congregations (CRUD) — the church's distinct service tracks."""
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.deps import get_current_profile, require_role
from app.repositories.congregations import CongregationRepository, get_congregation_repository
from app.schemas.congregation import CongregationCreate, CongregationRead, CongregationUpdate

router = APIRouter(prefix="/congregations", tags=["congregations"])

# Congregation-facing content: any signed-in profile can read (needed to
# populate pickers like "which congregation is this member/service for"),
# only admins manage the list itself — same shape as sermons/reading_plans.
require_write = require_role("admin")


# Lists every congregation. Any logged-in user.
@router.get("", response_model=list[CongregationRead])
async def list_congregations(
    repo: CongregationRepository = Depends(get_congregation_repository),
    _profile=Depends(get_current_profile),
):
    return repo.list()


# Fetches one congregation by id. 404 if it doesn't exist. Any logged-in user.
@router.get("/{congregation_id}", response_model=CongregationRead)
async def get_congregation(
    congregation_id: str,
    repo: CongregationRepository = Depends(get_congregation_repository),
    _profile=Depends(get_current_profile),
):
    congregation = repo.get(congregation_id)
    if congregation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Congregation not found")
    return congregation


# Adds a new congregation. admin only.
@router.post("", response_model=CongregationRead, status_code=status.HTTP_201_CREATED)
async def create_congregation(
    payload: CongregationCreate,
    repo: CongregationRepository = Depends(get_congregation_repository),
    _profile=Depends(require_write),
):
    return repo.create(payload.model_dump())


# Partially updates a congregation. 404 if it doesn't exist. admin only.
@router.patch("/{congregation_id}", response_model=CongregationRead)
async def update_congregation(
    congregation_id: str,
    payload: CongregationUpdate,
    repo: CongregationRepository = Depends(get_congregation_repository),
    _profile=Depends(require_write),
):
    updated = repo.update(congregation_id, payload.model_dump(exclude_unset=True))
    if updated is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Congregation not found")
    return updated


# Deletes a congregation. 404 if it doesn't exist. admin only.
@router.delete("/{congregation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_congregation(
    congregation_id: str,
    repo: CongregationRepository = Depends(get_congregation_repository),
    _profile=Depends(require_write),
):
    if not repo.delete(congregation_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Congregation not found")
