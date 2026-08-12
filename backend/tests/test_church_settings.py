def test_any_signed_in_role_can_read_settings(as_member):
    response = as_member.get("/api/v1/church-settings")
    assert response.status_code == 200
    assert response.json()["livestream_url"] is None


def test_member_cannot_update_settings(as_member):
    response = as_member.patch(
        "/api/v1/church-settings", json={"livestream_url": "https://youtube.com/live/abc"}
    )
    assert response.status_code == 403


def test_admin_can_update_livestream_url(as_admin):
    response = as_admin.patch(
        "/api/v1/church-settings", json={"livestream_url": "https://youtube.com/live/abc"}
    )
    assert response.status_code == 200
    assert response.json()["livestream_url"] == "https://youtube.com/live/abc"

    read_back = as_admin.get("/api/v1/church-settings")
    assert read_back.json()["livestream_url"] == "https://youtube.com/live/abc"
