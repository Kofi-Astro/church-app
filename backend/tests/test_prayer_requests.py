from app.core.deps import get_current_profile
from app.main import app
from app.schemas.profile import Role
from tests.conftest import as_profile

AUTHOR = "20000000-0000-0000-0000-00000000000a"
LEADER = "20000000-0000-0000-0000-00000000000b"
STRANGER = "20000000-0000-0000-0000-00000000000c"


def _act_as(profile_id: str, role: Role):
    app.dependency_overrides[get_current_profile] = as_profile(profile_id, role)


def test_author_can_read_their_own_private_request(as_admin):
    _act_as(AUTHOR, Role.member)
    created = as_admin.post(
        "/api/v1/prayer-requests",
        json={"content": "Please pray for my mum", "visibility": "private"},
    ).json()

    response = as_admin.get(f"/api/v1/prayer-requests/{created['id']}")
    assert response.status_code == 200
    assert response.json()["content"] == "Please pray for my mum"


def test_stranger_gets_404_not_403_on_a_private_request(as_admin):
    """The Phase 4 DevSecOps task, verbatim: a hostile account querying
    another member's private request directly against the API must not
    see it. 404 rather than 403 so the response doesn't even confirm the
    ID belongs to a real request."""
    _act_as(AUTHOR, Role.member)
    created = as_admin.post(
        "/api/v1/prayer-requests", json={"content": "Private matter", "visibility": "private"}
    ).json()

    _act_as(STRANGER, Role.member)
    response = as_admin.get(f"/api/v1/prayer-requests/{created['id']}")
    assert response.status_code == 404


def test_admin_gets_the_same_404_on_someone_elses_private_request(as_admin):
    """Deliberate design choice, not an oversight: 'private' has no admin
    override. Pin this down so a future change can't quietly add one."""
    _act_as(AUTHOR, Role.member)
    created = as_admin.post(
        "/api/v1/prayer-requests", json={"content": "Private matter", "visibility": "private"}
    ).json()

    _act_as(STRANGER, Role.admin)
    response = as_admin.get(f"/api/v1/prayer-requests/{created['id']}")
    assert response.status_code == 404


def test_private_request_excluded_from_another_users_list(as_admin):
    _act_as(AUTHOR, Role.member)
    as_admin.post(
        "/api/v1/prayer-requests", json={"content": "Private matter", "visibility": "private"}
    )

    _act_as(STRANGER, Role.member)
    response = as_admin.get("/api/v1/prayer-requests")
    assert response.json() == []


def test_public_request_is_visible_to_any_signed_in_user(as_admin):
    _act_as(AUTHOR, Role.member)
    as_admin.post(
        "/api/v1/prayer-requests",
        json={"content": "Pray for the mission trip", "visibility": "public"},
    )

    _act_as(STRANGER, Role.member)
    response = as_admin.get("/api/v1/prayer-requests")
    assert len(response.json()) == 1


def test_leaders_only_request_hidden_from_plain_members(as_admin):
    _act_as(AUTHOR, Role.member)
    as_admin.post(
        "/api/v1/prayer-requests", json={"content": "Leadership matter", "visibility": "leaders"}
    )

    _act_as(STRANGER, Role.member)
    assert as_admin.get("/api/v1/prayer-requests").json() == []

    _act_as(LEADER, Role.group_leader)
    assert len(as_admin.get("/api/v1/prayer-requests").json()) == 1


def test_praying_for_a_request_increments_the_count(as_admin):
    _act_as(AUTHOR, Role.member)
    created = as_admin.post(
        "/api/v1/prayer-requests", json={"content": "Pray for healing", "visibility": "public"}
    ).json()
    assert created["praying_count"] == 0
    assert created["is_praying"] is False

    _act_as(STRANGER, Role.member)
    response = as_admin.post(f"/api/v1/prayer-requests/{created['id']}/pray")
    assert response.status_code == 200
    assert response.json()["praying_count"] == 1
    assert response.json()["is_praying"] is True


def test_cannot_pray_for_a_request_you_cannot_see(as_admin):
    _act_as(AUTHOR, Role.member)
    created = as_admin.post(
        "/api/v1/prayer-requests", json={"content": "Private matter", "visibility": "private"}
    ).json()

    _act_as(STRANGER, Role.member)
    response = as_admin.post(f"/api/v1/prayer-requests/{created['id']}/pray")
    assert response.status_code == 404


def test_only_the_author_can_delete_their_request(as_admin):
    _act_as(AUTHOR, Role.member)
    created = as_admin.post(
        "/api/v1/prayer-requests", json={"content": "Pray for healing", "visibility": "public"}
    ).json()

    _act_as(STRANGER, Role.member)
    forbidden = as_admin.delete(f"/api/v1/prayer-requests/{created['id']}")
    assert forbidden.status_code == 403

    _act_as(AUTHOR, Role.member)
    allowed = as_admin.delete(f"/api/v1/prayer-requests/{created['id']}")
    assert allowed.status_code == 204
