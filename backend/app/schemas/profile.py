"""
Profile/role schema — mirrors the `app_role` enum and `profiles` table
defined in infra/migrations/0001_init.sql. Kept in sync manually since
Supabase is the source of truth for the schema itself.
"""
from enum import Enum

from pydantic import BaseModel


class Role(str, Enum):
    member = "member"
    group_leader = "group_leader"
    admin = "admin"
    finance_admin = "finance_admin"


class Profile(BaseModel):
    id: str
    full_name: str
    role: Role
