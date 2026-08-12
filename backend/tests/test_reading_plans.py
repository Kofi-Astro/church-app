from app.core.deps import get_current_profile
from app.main import app
from app.schemas.profile import Role
from tests.conftest import as_role


def test_any_signed_in_role_can_read_plans(as_admin):
    as_admin.post("/api/v1/reading-plans", json={"title": "Romans in 30 Days"})

    for role in (Role.admin, Role.member, Role.group_leader, Role.finance_admin):
        app.dependency_overrides[get_current_profile] = as_role(role)
        response = as_admin.get("/api/v1/reading-plans")
        assert response.status_code == 200
        assert len(response.json()) == 1


def test_member_cannot_create_plan(as_member):
    response = as_member.post("/api/v1/reading-plans", json={"title": "Romans in 30 Days"})
    assert response.status_code == 403


def test_add_and_list_days(as_admin):
    plan = as_admin.post("/api/v1/reading-plans", json={"title": "Romans in 30 Days"}).json()

    days_url = f"/api/v1/reading-plans/{plan['id']}/days"
    as_admin.post(days_url, json={"day_number": 1, "reference": "Romans 1"})
    as_admin.post(days_url, json={"day_number": 2, "reference": "Romans 2"})

    days = as_admin.get(f"/api/v1/reading-plans/{plan['id']}/days").json()
    assert [d["day_number"] for d in days] == [1, 2]


def test_days_for_missing_plan_is_404(as_admin):
    response = as_admin.get("/api/v1/reading-plans/does-not-exist/days")
    assert response.status_code == 404
