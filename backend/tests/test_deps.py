import pytest
from fastapi import HTTPException

from app.core.deps import get_current_profile


@pytest.mark.anyio
async def test_missing_authorization_header_is_401():
    with pytest.raises(HTTPException) as exc_info:
        await get_current_profile(authorization=None)
    assert exc_info.value.status_code == 401


@pytest.mark.anyio
async def test_non_bearer_authorization_header_is_401():
    with pytest.raises(HTTPException) as exc_info:
        await get_current_profile(authorization="Basic somevalue")
    assert exc_info.value.status_code == 401
