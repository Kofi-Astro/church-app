"""
Auth and role-enforcement dependencies shared by every Phase 1+ router.

Role checks happen at two layers on purpose: RLS is the real security
boundary at the database (see infra/migrations and docs/threat-model.md),
and `require_role` here is the API-layer check that turns a denied action
into a clean 403 instead of a query that just silently returns nothing.
Neither layer is trusted to compensate for a gap in the other.
"""
from fastapi import Depends, Header, HTTPException, status

from app.core.supabase import get_supabase
from app.schemas.profile import Profile


async def get_current_profile(authorization: str | None = Header(default=None)) -> Profile:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing bearer token")

    token = authorization.split(" ", 1)[1]
    client = get_supabase()

    try:
        user_response = client.auth.get_user(token)
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token") from exc

    user = getattr(user_response, "user", None)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")

    result = (
        client.table("profiles")
        .select("id, full_name, role")
        .eq("id", user.id)
        .maybe_single()
        .execute()
    )
    if not result.data:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No profile exists for this account")

    return Profile(**result.data)


def require_role(*allowed_roles: str):
    """Returns a dependency that 403s unless the caller's profile has one of `allowed_roles`."""

    async def _check(profile: Profile = Depends(get_current_profile)) -> Profile:
        if profile.role not in allowed_roles:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Insufficient role for this action")
        return profile

    return _check
