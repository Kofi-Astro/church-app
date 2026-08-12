import pytest

from app.core.config import Settings
from app.core.supabase import get_supabase


def test_get_supabase_raises_clearly_when_unconfigured(monkeypatch):
    """
    An unconfigured client must fail fast with a clear message rather than
    a confusing connection error deep inside the supabase-py library. This
    is forced via monkeypatch rather than relying on the ambient absence of
    backend/.env, since a real dev project is configured there once
    infra/infra.md's setup is done.
    """
    get_supabase.cache_clear()
    monkeypatch.setattr(
        "app.core.supabase.get_settings",
        lambda: Settings(supabase_url="", supabase_service_role_key=""),
    )
    with pytest.raises(RuntimeError, match="SUPABASE_URL"):
        get_supabase()
    get_supabase.cache_clear()
