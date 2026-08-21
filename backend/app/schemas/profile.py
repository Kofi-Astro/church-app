"""
Profile/role schema — mirrors the `app_role` enum and `profiles` table
defined in infra/migrations/0001_init.sql. Kept in sync manually since
Supabase is the source of truth for the schema itself.

`email` is the one exception: it isn't a `profiles` column (Supabase Auth
already owns it on `auth.users`) — get_current_profile fills it in from
the authenticated user response. It exists on this model because Phase 5
giving needs an email to hand to Paystack's transaction-initialize call.
"""
from enum import Enum

from pydantic import BaseModel


class Role(str, Enum):
    """The set of app-level roles a profile can have, used by require_role checks."""

    member = "member"
    group_leader = "group_leader"
    admin = "admin"
    finance_admin = "finance_admin"


class Profile(BaseModel):
    """The logged-in caller's identity + role, as resolved by get_current_profile."""

    id: str
    full_name: str
    role: Role
    email: str
