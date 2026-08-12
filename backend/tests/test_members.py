def test_admin_can_create_and_search_members(as_admin):
    as_admin.post("/api/v1/members", json={"full_name": "Ama Owusu", "email": "ama@example.com"})
    as_admin.post(
        "/api/v1/members", json={"full_name": "Kwame Mensah", "email": "kwame@example.com"}
    )

    response = as_admin.get("/api/v1/members", params={"search": "ama"})
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["full_name"] == "Ama Owusu"


def test_member_cannot_write(as_member):
    response = as_member.post("/api/v1/members", json={"full_name": "Ama Owusu"})
    assert response.status_code == 403


def test_finance_admin_can_read_directory(as_finance_admin):
    response = as_finance_admin.get("/api/v1/members")
    assert response.status_code == 200


def test_invalid_email_is_rejected(as_admin):
    response = as_admin.post(
        "/api/v1/members", json={"full_name": "Ama Owusu", "email": "not-an-email"}
    )
    assert response.status_code == 422


def test_update_member(as_admin):
    created = as_admin.post("/api/v1/members", json={"full_name": "Ama Owusu"}).json()

    updated = as_admin.patch(f"/api/v1/members/{created['id']}", json={"phone": "0551234567"})
    assert updated.status_code == 200
    assert updated.json()["phone"] == "0551234567"
    assert updated.json()["full_name"] == "Ama Owusu"
