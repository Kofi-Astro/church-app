"""Routes for the sermon library (CRUD, with filtering/search)."""
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.deps import get_current_profile, require_role
from app.repositories.sermons import SermonRepository, get_sermon_repository
from app.schemas.pagination import Page
from app.schemas.sermon import SermonCreate, SermonRead, SermonUpdate

router = APIRouter(prefix="/sermons", tags=["sermons"])

# Sermons are congregation-facing content: any signed-in profile can read
# (unlike the directory/attendance routers, which are staff-only), but
# only admins manage the library.
require_write = require_role("admin")


# Paginated, filterable list of sermons (by series/speaker/title search). Any logged-in user.
@router.get("", response_model=Page[SermonRead])
async def list_sermons(
    limit: int = Query(default=25, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    series: str | None = Query(default=None),
    speaker: str | None = Query(default=None),
    search: str | None = Query(default=None, max_length=200),
    repo: SermonRepository = Depends(get_sermon_repository),
    _profile=Depends(get_current_profile),
):
    items, total = repo.list(
        limit=limit, offset=offset, series=series, speaker=speaker, search=search
    )
    return Page(items=items, total=total, limit=limit, offset=offset)


# Fetches one sermon by id. 404 if it doesn't exist. Any logged-in user.
@router.get("/{sermon_id}", response_model=SermonRead)
async def get_sermon(
    sermon_id: str,
    repo: SermonRepository = Depends(get_sermon_repository),
    _profile=Depends(get_current_profile),
):
    sermon = repo.get(sermon_id)
    if sermon is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sermon not found")
    return sermon


# Adds a new sermon to the library. admin only.
@router.post("", response_model=SermonRead, status_code=status.HTTP_201_CREATED)
async def create_sermon(
    payload: SermonCreate,
    repo: SermonRepository = Depends(get_sermon_repository),
    profile=Depends(require_write),
):
    data = payload.model_dump()
    data["sermon_date"] = data["sermon_date"].isoformat()
    data["created_by"] = profile.id
    return repo.create(data)


# Partially updates a sermon (only fields sent are changed). 404 if it doesn't
# exist. admin only.
@router.patch("/{sermon_id}", response_model=SermonRead)
async def update_sermon(
    sermon_id: str,
    payload: SermonUpdate,
    repo: SermonRepository = Depends(get_sermon_repository),
    _profile=Depends(require_write),
):
    data = payload.model_dump(exclude_unset=True)
    if "sermon_date" in data and data["sermon_date"] is not None:
        data["sermon_date"] = data["sermon_date"].isoformat()
    updated = repo.update(sermon_id, data)
    if updated is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sermon not found")
    return updated


# Deletes a sermon. 404 if it doesn't exist. admin only.
@router.delete("/{sermon_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_sermon(
    sermon_id: str,
    repo: SermonRepository = Depends(get_sermon_repository),
    _profile=Depends(require_write),
):
    if not repo.delete(sermon_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sermon not found")
