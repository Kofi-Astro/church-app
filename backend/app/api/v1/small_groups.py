"""
Routes for small groups: the groups themselves, their membership rosters, and
study materials shared within a group. Materials are only visible to a
group's own members (or an admin) — see _can_view_group_materials below.
"""
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.deps import get_current_profile, require_role
from app.repositories.small_groups import SmallGroupRepository, get_small_group_repository
from app.schemas.profile import Profile
from app.schemas.small_group import (
    GroupMaterialCreate,
    GroupMaterialRead,
    GroupMemberAdd,
    GroupMemberRead,
    SmallGroupCreate,
    SmallGroupRead,
)

router = APIRouter(prefix="/small-groups", tags=["small-groups"])

require_admin = require_role("admin")


# Whether this profile may manage (add/remove members, add/remove materials) a
# given group: either a site-wide admin, or that specific group's leader.
def _can_manage_group(profile: Profile, group_id: str, repo: SmallGroupRepository) -> bool:
    return profile.role == "admin" or repo.is_leader(group_id, profile.id)


# Whether this profile may view a group's roster/materials: an admin, or
# someone who is actually on that group's member roster.
def _can_view_group_materials(profile: Profile, group_id: str, repo: SmallGroupRepository) -> bool:
    return profile.role == "admin" or repo.is_member(group_id, profile.id)


# Lists all small groups (just the group records, not membership/materials). Any logged-in user.
@router.get("", response_model=list[SmallGroupRead])
async def list_small_groups(
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    _profile=Depends(get_current_profile),
):
    return repo.list_groups()


# Fetches one small group by id. 404 if it doesn't exist. Any logged-in user.
@router.get("/{group_id}", response_model=SmallGroupRead)
async def get_small_group(
    group_id: str,
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    _profile=Depends(get_current_profile),
):
    group = repo.get_group(group_id)
    if group is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Group not found")
    return group


# Creates a new small group. admin only.
@router.post("", response_model=SmallGroupRead, status_code=status.HTTP_201_CREATED)
async def create_small_group(
    payload: SmallGroupCreate,
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    _profile=Depends(require_admin),
):
    return repo.create_group(payload.model_dump())


# Lists a group's member roster. Restricted to that group's own members (or an
# admin) — 403 for anyone else.
@router.get("/{group_id}/members", response_model=list[GroupMemberRead])
async def list_group_members(
    group_id: str,
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    profile: Profile = Depends(get_current_profile),
):
    if not _can_view_group_materials(profile, group_id, repo):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not a member of this group")
    return repo.list_members(group_id)


# Adds a profile to a group's roster. Only that group's leader or an admin.
@router.post(
    "/{group_id}/members", response_model=GroupMemberRead, status_code=status.HTTP_201_CREATED
)
async def add_group_member(
    group_id: str,
    payload: GroupMemberAdd,
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    profile: Profile = Depends(get_current_profile),
):
    if not _can_manage_group(profile, group_id, repo):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Only the group's leader or an admin can add members"
        )
    return repo.add_member(group_id, payload.profile_id)


# Removes a profile from a group's roster. Only that group's leader or an admin.
@router.delete("/{group_id}/members/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_group_member(
    group_id: str,
    profile_id: str,
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    profile: Profile = Depends(get_current_profile),
):
    if not _can_manage_group(profile, group_id, repo):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Only the group's leader or an admin can remove members"
        )
    if not repo.remove_member(group_id, profile_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not a member of this group")


# Lists a group's study materials. Restricted to that group's own members (or an
# admin) — 403 for anyone else.
@router.get("/{group_id}/materials", response_model=list[GroupMaterialRead])
async def list_group_materials(
    group_id: str,
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    profile: Profile = Depends(get_current_profile),
):
    # This is the Phase 3 negative-test surface: a member of a different
    # group must get a 403 here, not another group's materials.
    if not _can_view_group_materials(profile, group_id, repo):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not a member of this group")
    return repo.list_materials(group_id)


# Adds a study material to a group. Only that group's leader or an admin.
@router.post(
    "/{group_id}/materials", response_model=GroupMaterialRead, status_code=status.HTTP_201_CREATED
)
async def create_group_material(
    group_id: str,
    payload: GroupMaterialCreate,
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    profile: Profile = Depends(get_current_profile),
):
    if not _can_manage_group(profile, group_id, repo):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Only the group's leader or an admin can add materials"
        )
    data = payload.model_dump()
    data["group_id"] = group_id
    data["created_by"] = profile.id
    return repo.create_material(data)


# Deletes a study material. Only that group's leader or an admin.
@router.delete("/{group_id}/materials/{material_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_group_material(
    group_id: str,
    material_id: str,
    repo: SmallGroupRepository = Depends(get_small_group_repository),
    profile: Profile = Depends(get_current_profile),
):
    if not _can_manage_group(profile, group_id, repo):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Only the group's leader or an admin can remove materials"
        )
    if not repo.delete_material(material_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Material not found")
