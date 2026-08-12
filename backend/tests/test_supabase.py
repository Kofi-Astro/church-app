import pytest

from app.core.supabase import get_supabase


def test_get_supabase_raises_clearly_when_unconfigured():
    """
    No Supabase project exists yet for local/CI runs, so the client must
    fail fast with a clear message rather than a confusing connection
    error deep inside the supabase-py library.
    """
    get_supabase.cache_clear()
    with pytest.raises(RuntimeError, match="SUPABASE_URL"):
        get_supabase()
