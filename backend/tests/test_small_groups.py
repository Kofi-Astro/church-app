from app.core.deps import get_current_profile
from app.main import app
from app.schemas.profile import Role
from tests.conftest import as_profile

MEMBER_A = "10000000-0000-0000-0000-00000000000a"
MEMBER_B = "10000000-0000-0000-0000-00000000000b"
OUTSIDER = "10000000-0000-0000-0000-0000000000c0"


def _act_as(profile_id: str, role: Role):
    app.dependency_overrides[get_current_profile] = as_profile(profile_id, role)


def test_any_signed_in_role_can_browse_group_directory(as_admin):
    as_admin.post("/api/v1/small-groups", json={"name": "Young Adults"})

    for role in (Role.admin, Role.member):
        app.dependency_overrides[get_current_profile] = as_profile(
            "00000000-0000-0000-0000-000000000001", role
        )
        response = as_admin.get("/api/v1/small-groups")
        assert response.status_code == 200
        assert len(response.json()) == 1


def test_group_materials_are_scoped_to_members_only(as_admin):
    """The Phase 3 DevSecOps negative test: a member of one group must not
    be able to read another group's materials, and a non-member gets the
    same 403 — RLS enforces this for real in Postgres, this test proves
    the API-layer mirror does too."""
    group_a = as_admin.post("/api/v1/small-groups", json={"name": "Young Adults"}).json()
    group_b = as_admin.post("/api/v1/small-groups", json={"name": "Marrieds"}).json()

    as_admin.post(f"/api/v1/small-groups/{group_a['id']}/members", json={"profile_id": MEMBER_A})
    as_admin.post(f"/api/v1/small-groups/{group_b['id']}/members", json={"profile_id": MEMBER_B})
    as_admin.post(
        f"/api/v1/small-groups/{group_a['id']}/materials",
        json={"title": "Week 1 study guide"},
    )

    _act_as(MEMBER_A, Role.member)
    own_group = as_admin.get(f"/api/v1/small-groups/{group_a['id']}/materials")
    assert own_group.status_code == 200
    assert len(own_group.json()) == 1

    other_group = as_admin.get(f"/api/v1/small-groups/{group_b['id']}/materials")
    assert other_group.status_code == 403

    _act_as(OUTSIDER, Role.member)
    outsider_response = as_admin.get(f"/api/v1/small-groups/{group_a['id']}/materials")
    assert outsider_response.status_code == 403


def test_group_leader_can_add_materials_without_being_admin(as_admin):
    group = as_admin.post(
        "/api/v1/small-groups", json={"name": "Young Adults", "leader_id": MEMBER_A}
    ).json()
    as_admin.post(f"/api/v1/small-groups/{group['id']}/members", json={"profile_id": MEMBER_A})

    _act_as(MEMBER_A, Role.group_leader)
    response = as_admin.post(
        f"/api/v1/small-groups/{group['id']}/materials", json={"title": "Week 1 study guide"}
    )
    assert response.status_code == 201


def test_non_leader_member_cannot_add_materials(as_admin):
    group = as_admin.post("/api/v1/small-groups", json={"name": "Young Adults"}).json()
    as_admin.post(f"/api/v1/small-groups/{group['id']}/members", json={"profile_id": MEMBER_A})

    _act_as(MEMBER_A, Role.member)
    response = as_admin.post(
        f"/api/v1/small-groups/{group['id']}/materials", json={"title": "Week 1 study guide"}
    )
    assert response.status_code == 403
