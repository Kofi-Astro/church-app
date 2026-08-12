from app.core.deps import get_current_profile
from app.main import app
from app.schemas.profile import Role
from tests.conftest import as_role


def test_member_cannot_create_event(as_member):
    response = as_member.post(
        "/api/v1/events",
        json={"title": "Youth Camp", "event_date": "2026-09-01T09:00:00Z"},
    )
    assert response.status_code == 403


def test_admin_can_create_and_any_signed_in_role_can_read(as_admin):
    as_admin.post(
        "/api/v1/events",
        json={"title": "Youth Camp", "event_date": "2026-09-01T09:00:00Z"},
    )

    app.dependency_overrides[get_current_profile] = as_role(Role.member)
    response = as_admin.get("/api/v1/events")
    assert response.status_code == 200
    assert len(response.json()) == 1


def test_rsvp_counts_and_my_rsvp(as_admin):
    event = as_admin.post(
        "/api/v1/events",
        json={"title": "Youth Camp", "event_date": "2026-09-01T09:00:00Z"},
    ).json()
    assert event["rsvp_counts"] == {"going": 0, "maybe": 0, "not_going": 0}
    assert event["my_rsvp"] is None

    rsvp = as_admin.put(f"/api/v1/events/{event['id']}/rsvp", json={"status": "going"})
    assert rsvp.status_code == 200
    assert rsvp.json()["rsvp_counts"]["going"] == 1
    assert rsvp.json()["my_rsvp"] == "going"

    changed = as_admin.put(f"/api/v1/events/{event['id']}/rsvp", json={"status": "maybe"})
    assert changed.json()["rsvp_counts"] == {"going": 0, "maybe": 1, "not_going": 0}

    cleared = as_admin.delete(f"/api/v1/events/{event['id']}/rsvp")
    assert cleared.json()["rsvp_counts"] == {"going": 0, "maybe": 0, "not_going": 0}
    assert cleared.json()["my_rsvp"] is None


def test_get_missing_event_is_404(as_admin):
    response = as_admin.get("/api/v1/events/does-not-exist")
    assert response.status_code == 404
