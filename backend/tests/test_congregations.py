def test_any_signed_in_role_can_read_congregations(as_admin, fake_congregations):
    fake_congregations.create({"name": "English Service"})

    response = as_admin.get("/api/v1/congregations")
    assert response.status_code == 200
    assert len(response.json()) == 1


def test_member_cannot_create_congregation(as_member):
    response = as_member.post("/api/v1/congregations", json={"name": "Youth Chapel"})
    assert response.status_code == 403


def test_admin_can_create_update_and_delete_congregation(as_admin):
    created = as_admin.post("/api/v1/congregations", json={"name": "Youth Chapel"}).json()
    assert created["name"] == "Youth Chapel"

    updated = as_admin.patch(
        f"/api/v1/congregations/{created['id']}", json={"description": "Ages 13-18"}
    )
    assert updated.status_code == 200
    assert updated.json()["description"] == "Ages 13-18"

    deleted = as_admin.delete(f"/api/v1/congregations/{created['id']}")
    assert deleted.status_code == 204
    assert as_admin.get(f"/api/v1/congregations/{created['id']}").status_code == 404


def test_get_missing_congregation_is_404(as_admin):
    response = as_admin.get("/api/v1/congregations/00000000-0000-0000-0000-000000000099")
    assert response.status_code == 404
