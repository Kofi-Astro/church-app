from fastapi import APIRouter, Depends, HTTPException, status

from app.core.deps import get_current_profile
from app.repositories.prayer_requests import (
    PrayerRequestRepository,
    can_view_prayer_request,
    get_prayer_request_repository,
)
from app.schemas.prayer_request import PrayerRequestCreate, PrayerRequestRead
from app.schemas.profile import Profile

router = APIRouter(prefix="/prayer-requests", tags=["prayer-requests"])


def _to_read_model(
    request: dict, profile: Profile, repo: PrayerRequestRepository
) -> PrayerRequestRead:
    return PrayerRequestRead(
        **request,
        praying_count=repo.praying_count(request["id"]),
        is_praying=repo.is_praying(request["id"], profile.id),
    )


@router.get("", response_model=list[PrayerRequestRead])
async def list_prayer_requests(
    repo: PrayerRequestRepository = Depends(get_prayer_request_repository),
    profile: Profile = Depends(get_current_profile),
):
    visible = [r for r in repo.list_all() if can_view_prayer_request(profile, r)]
    return [_to_read_model(r, profile, repo) for r in visible]


@router.get("/{request_id}", response_model=PrayerRequestRead)
async def get_prayer_request(
    request_id: str,
    repo: PrayerRequestRepository = Depends(get_prayer_request_repository),
    profile: Profile = Depends(get_current_profile),
):
    request = repo.get(request_id)
    # 404, not 403, when the request exists but isn't visible — a 403
    # would confirm to a hostile caller that the ID is real. This is the
    # exact endpoint the roadmap's Phase 4 negative test targets.
    if request is None or not can_view_prayer_request(profile, request):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Prayer request not found")
    return _to_read_model(request, profile, repo)


@router.post("", response_model=PrayerRequestRead, status_code=status.HTTP_201_CREATED)
async def create_prayer_request(
    payload: PrayerRequestCreate,
    repo: PrayerRequestRepository = Depends(get_prayer_request_repository),
    profile: Profile = Depends(get_current_profile),
):
    data = payload.model_dump()
    data["profile_id"] = profile.id
    request = repo.create(data)
    return _to_read_model(request, profile, repo)


@router.delete("/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_prayer_request(
    request_id: str,
    repo: PrayerRequestRepository = Depends(get_prayer_request_repository),
    profile: Profile = Depends(get_current_profile),
):
    request = repo.get(request_id)
    if request is None or not can_view_prayer_request(profile, request):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Prayer request not found")
    if request["profile_id"] != profile.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only the author can delete this request")
    repo.delete(request_id)


@router.post("/{request_id}/pray", response_model=PrayerRequestRead)
async def pray_for_request(
    request_id: str,
    repo: PrayerRequestRepository = Depends(get_prayer_request_repository),
    profile: Profile = Depends(get_current_profile),
):
    request = repo.get(request_id)
    if request is None or not can_view_prayer_request(profile, request):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Prayer request not found")
    repo.add_interaction(request_id, profile.id)
    return _to_read_model(request, profile, repo)


@router.delete("/{request_id}/pray", response_model=PrayerRequestRead)
async def unpray_for_request(
    request_id: str,
    repo: PrayerRequestRepository = Depends(get_prayer_request_repository),
    profile: Profile = Depends(get_current_profile),
):
    request = repo.get(request_id)
    if request is None or not can_view_prayer_request(profile, request):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Prayer request not found")
    repo.remove_interaction(request_id, profile.id)
    return _to_read_model(request, profile, repo)
