"""
Supabase client factory.

This client always authenticates with the service_role key, which bypasses
RLS by design (see docs/threat-model.md) — it must only ever be used
server-side, never returned to a caller or exposed to the mobile app.

The client is built lazily (only when a route actually needs the database)
rather than at import time, so the app still boots and /health still works
before a Supabase project is configured — the same "boot without real
credentials" property app/core/config.py already relies on.
"""
from functools import lru_cache

from supabase import Client, create_client  # type: ignore[import]

from app.core.config import get_settings


@lru_cache
def get_supabase() -> Client:
    """
    Builds (once — @lru_cache means every subsequent call returns the same
    instance) and returns the shared Supabase client used by every repository.
    Raises a RuntimeError with setup instructions if the required env vars
    aren't set yet, instead of letting the `supabase` library fail confusingly.
    """
    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise RuntimeError(
            "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are not set. Copy "
            ".env.example to backend/.env and fill in values from the "
            "Supabase dashboard (Project Settings -> API) before calling "
            "any endpoint that touches the database."
        )
    return create_client(settings.supabase_url, settings.supabase_service_role_key)
