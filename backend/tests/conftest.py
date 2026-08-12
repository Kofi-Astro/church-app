import pytest
from fastapi.testclient import TestClient

from app.core.deps import get_current_profile
from app.main import app
from app.repositories.attendance import get_attendance_repository
from app.repositories.households import get_household_repository
from app.repositories.members import get_member_repository
from app.schemas.profile import Profile, Role
from tests.fakes import FakeAttendanceRepository, FakeHouseholdRepository, FakeMemberRepository


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.fixture
def fake_households():
    return FakeHouseholdRepository()


@pytest.fixture
def fake_members():
    return FakeMemberRepository()


@pytest.fixture
def fake_attendance():
    return FakeAttendanceRepository()


@pytest.fixture
def client(fake_households, fake_members, fake_attendance):
    app.dependency_overrides[get_household_repository] = lambda: fake_households
    app.dependency_overrides[get_member_repository] = lambda: fake_members
    app.dependency_overrides[get_attendance_repository] = lambda: fake_attendance
    yield TestClient(app)
    app.dependency_overrides.clear()


def as_role(role: Role):
    """Override get_current_profile so a test can act as a given role
    without a real Supabase JWT — mirrors the roadmap's "negative test
    with a non-privileged account" pattern, just at the API layer."""

    async def _override() -> Profile:
        return Profile(id="00000000-0000-0000-0000-000000000001", full_name="Test User", role=role)

    return _override


@pytest.fixture
def as_admin(client):
    app.dependency_overrides[get_current_profile] = as_role(Role.admin)
    return client


@pytest.fixture
def as_group_leader(client):
    app.dependency_overrides[get_current_profile] = as_role(Role.group_leader)
    return client


@pytest.fixture
def as_finance_admin(client):
    app.dependency_overrides[get_current_profile] = as_role(Role.finance_admin)
    return client


@pytest.fixture
def as_member(client):
    app.dependency_overrides[get_current_profile] = as_role(Role.member)
    return client
