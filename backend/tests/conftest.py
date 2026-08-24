import pytest
from fastapi.testclient import TestClient

from app.core.deps import get_current_profile
from app.main import app
from app.repositories.attendance import get_attendance_repository
from app.repositories.church_settings import get_church_settings_repository
from app.repositories.congregations import get_congregation_repository
from app.repositories.events import get_event_repository
from app.repositories.giving import get_giving_repository
from app.repositories.households import get_household_repository
from app.repositories.members import get_member_repository
from app.repositories.prayer_requests import get_prayer_request_repository
from app.repositories.reading_plans import get_reading_plan_repository
from app.repositories.sermons import get_sermon_repository
from app.repositories.small_groups import get_small_group_repository
from app.schemas.profile import Profile, Role
from tests.fakes import (
    FakeAttendanceRepository,
    FakeChurchSettingsRepository,
    FakeCongregationRepository,
    FakeEventRepository,
    FakeGivingRepository,
    FakeHouseholdRepository,
    FakeMemberRepository,
    FakePrayerRequestRepository,
    FakeReadingPlanRepository,
    FakeSermonRepository,
    FakeSmallGroupRepository,
)


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
def fake_sermons():
    return FakeSermonRepository()


@pytest.fixture
def fake_church_settings():
    return FakeChurchSettingsRepository()


@pytest.fixture
def fake_reading_plans():
    return FakeReadingPlanRepository()


@pytest.fixture
def fake_small_groups():
    return FakeSmallGroupRepository()


@pytest.fixture
def fake_prayer_requests():
    return FakePrayerRequestRepository()


@pytest.fixture
def fake_events():
    return FakeEventRepository()


@pytest.fixture
def fake_giving():
    return FakeGivingRepository()


@pytest.fixture
def fake_congregations():
    return FakeCongregationRepository()


@pytest.fixture
def client(
    fake_households,
    fake_members,
    fake_attendance,
    fake_sermons,
    fake_church_settings,
    fake_reading_plans,
    fake_small_groups,
    fake_prayer_requests,
    fake_events,
    fake_giving,
    fake_congregations,
):
    app.dependency_overrides[get_household_repository] = lambda: fake_households
    app.dependency_overrides[get_member_repository] = lambda: fake_members
    app.dependency_overrides[get_attendance_repository] = lambda: fake_attendance
    app.dependency_overrides[get_sermon_repository] = lambda: fake_sermons
    app.dependency_overrides[get_church_settings_repository] = lambda: fake_church_settings
    app.dependency_overrides[get_reading_plan_repository] = lambda: fake_reading_plans
    app.dependency_overrides[get_small_group_repository] = lambda: fake_small_groups
    app.dependency_overrides[get_prayer_request_repository] = lambda: fake_prayer_requests
    app.dependency_overrides[get_event_repository] = lambda: fake_events
    app.dependency_overrides[get_giving_repository] = lambda: fake_giving
    app.dependency_overrides[get_congregation_repository] = lambda: fake_congregations
    yield TestClient(app)
    app.dependency_overrides.clear()


def as_profile(profile_id: str, role: Role):
    """Override get_current_profile as a specific (id, role) pair — used
    directly (rather than through as_admin/as_member/...) whenever a test
    needs to distinguish between two different users of the same role,
    e.g. two ordinary members in different small groups."""

    async def _override() -> Profile:
        return Profile(id=profile_id, full_name="Test User", role=role, email="test@example.com")

    return _override


def as_role(role: Role):
    """Override get_current_profile so a test can act as a given role
    without a real Supabase JWT — mirrors the roadmap's "negative test
    with a non-privileged account" pattern, just at the API layer."""
    return as_profile("00000000-0000-0000-0000-000000000001", role)


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
