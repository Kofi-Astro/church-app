def test_admin_can_create_and_read_household(as_admin):
    create = as_admin.post("/api/v1/households", json={"name": "Smith Household"})
    assert create.status_code == 201
    household_id = create.json()["id"]

    read = as_admin.get(f"/api/v1/households/{household_id}")
    assert read.status_code == 200
    assert read.json()["name"] == "Smith Household"


def test_list_is_paginated(as_admin):
    for i in range(3):
        as_admin.post("/api/v1/households", json={"name": f"Household {i}"})

    response = as_admin.get("/api/v1/households", params={"limit": 2, "offset": 0})
    body = response.json()
    assert body["total"] == 3
    assert len(body["items"]) == 2


def test_member_cannot_create_household(as_member):
    """Negative test: a plain member must not be able to create a household
    via the API, mirroring the RLS policy that only admins can write."""
    response = as_member.post("/api/v1/households", json={"name": "Smith Household"})
    assert response.status_code == 403


def test_group_leader_can_read_but_not_write(as_group_leader):
    response = as_group_leader.get("/api/v1/households")
    assert response.status_code == 200

    response = as_group_leader.post("/api/v1/households", json={"name": "Smith Household"})
    assert response.status_code == 403


def test_get_missing_household_is_404(as_admin):
    response = as_admin.get("/api/v1/households/does-not-exist")
    assert response.status_code == 404


def test_no_auth_header_is_401(client):
    response = client.get("/api/v1/households")
    assert response.status_code == 401
