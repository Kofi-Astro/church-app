"""Routes for the member directory (CRUD), with search and household filtering."""
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.deps import require_role
from app.repositories.members import MemberRepository, get_member_repository
from app.schemas.member import MemberCreate, MemberRead, MemberUpdate
from app.schemas.pagination import Page

router = APIRouter(prefix="/members", tags=["members"])

# Same read/write role split as households — see app/api/v1/households.py.
require_read = require_role("admin", "finance_admin", "group_leader")
require_write = require_role("admin")


# Paginated, searchable list of members, optionally filtered to one household.
# admin/finance_admin/group_leader only.
@router.get("", response_model=Page[MemberRead])
async def list_members(
    limit: int = Query(default=25, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    search: str | None = Query(default=None, max_length=200),
    household_id: str | None = Query(default=None),
    repo: MemberRepository = Depends(get_member_repository),
    _profile=Depends(require_read),
):
    items, total = repo.list(limit=limit, offset=offset, search=search, household_id=household_id)
    return Page(items=items, total=total, limit=limit, offset=offset)


# Fetches one member by id. 404 if they don't exist. admin/finance_admin/group_leader.
@router.get("/{member_id}", response_model=MemberRead)
async def get_member(
    member_id: str,
    repo: MemberRepository = Depends(get_member_repository),
    _profile=Depends(require_read),
):
    member = repo.get(member_id)
    if member is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Member not found")
    return member


# Adds a new member to the directory. admin only.
@router.post("", response_model=MemberRead, status_code=status.HTTP_201_CREATED)
async def create_member(
    payload: MemberCreate,
    repo: MemberRepository = Depends(get_member_repository),
    _profile=Depends(require_write),
):
    return repo.create(payload.model_dump())


# Partially updates a member (only fields sent are changed). 404 if they don't
# exist. admin only.
@router.patch("/{member_id}", response_model=MemberRead)
async def update_member(
    member_id: str,
    payload: MemberUpdate,
    repo: MemberRepository = Depends(get_member_repository),
    _profile=Depends(require_write),
):
    updated = repo.update(member_id, payload.model_dump(exclude_unset=True))
    if updated is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Member not found")
    return updated


# Deletes a member. 404 if they don't exist. admin only.
@router.delete("/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_member(
    member_id: str,
    repo: MemberRepository = Depends(get_member_repository),
    _profile=Depends(require_write),
):
    if not repo.delete(member_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Member not found")
