from fastapi import APIRouter, Depends

from app.core.deps import get_current_profile, require_role
from app.repositories.church_settings import (
    ChurchSettingsRepository,
    get_church_settings_repository,
)
from app.schemas.church_settings import ChurchSettingsRead, ChurchSettingsUpdate

router = APIRouter(prefix="/church-settings", tags=["church-settings"])

require_write = require_role("admin")


@router.get("", response_model=ChurchSettingsRead)
async def get_church_settings(
    repo: ChurchSettingsRepository = Depends(get_church_settings_repository),
    _profile=Depends(get_current_profile),
):
    return repo.get()


@router.patch("", response_model=ChurchSettingsRead)
async def update_church_settings(
    payload: ChurchSettingsUpdate,
    repo: ChurchSettingsRepository = Depends(get_church_settings_repository),
    _profile=Depends(require_write),
):
    return repo.update(payload.model_dump(exclude_unset=True))
