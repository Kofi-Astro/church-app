from app.core.deps import get_current_profile
from app.main import app
from app.schemas.profile import Role
from tests.conftest import as_role


def test_any_signed_in_role_can_read_sermons(as_admin):
    as_admin.post(
        "/api/v1/sermons",
        json={"title": "Grace Abounds", "series": "Romans", "sermon_date": "2026-08-09"},
    )

    # Switch the profile override on the same client between requests —
    # requesting multiple as_<role> fixtures at once would just overwrite
    # each other's app.dependency_overrides entry.
    for role in (Role.admin, Role.member, Role.group_leader, Role.finance_admin):
        app.dependency_overrides[get_current_profile] = as_role(role)
        response = as_admin.get("/api/v1/sermons")
        assert response.status_code == 200
        assert response.json()["total"] == 1


def test_member_cannot_create_sermon(as_member):
    response = as_member.post(
        "/api/v1/sermons", json={"title": "Grace Abounds", "sermon_date": "2026-08-09"}
    )
    assert response.status_code == 403


def test_filter_by_series(as_admin):
    as_admin.post(
        "/api/v1/sermons",
        json={"title": "Grace Abounds", "series": "Romans", "sermon_date": "2026-08-09"},
    )
    as_admin.post(
        "/api/v1/sermons",
        json={"title": "In The Beginning", "series": "Genesis", "sermon_date": "2026-08-02"},
    )

    response = as_admin.get("/api/v1/sermons", params={"series": "Romans"})
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["title"] == "Grace Abounds"


def test_update_and_delete_sermon(as_admin):
    created = as_admin.post(
        "/api/v1/sermons", json={"title": "Grace Abounds", "sermon_date": "2026-08-09"}
    ).json()

    updated = as_admin.patch(
        f"/api/v1/sermons/{created['id']}", json={"video_url": "https://youtu.be/example"}
    )
    assert updated.status_code == 200
    assert updated.json()["video_url"] == "https://youtu.be/example"

    deleted = as_admin.delete(f"/api/v1/sermons/{created['id']}")
    assert deleted.status_code == 204
    assert as_admin.get(f"/api/v1/sermons/{created['id']}").status_code == 404
