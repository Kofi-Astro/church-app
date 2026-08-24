def test_group_leader_can_create_service_and_mark_attendance(
    as_group_leader, fake_members, fake_congregations
):
    member = fake_members.create({"full_name": "Ama Owusu"})
    congregation = fake_congregations.create({"name": "English Service"})

    service = as_group_leader.post(
        "/api/v1/attendance/services",
        json={
            "name": "Sunday Service",
            "service_date": "2026-08-09",
            "congregation_id": congregation["id"],
        },
    ).json()

    marked = as_group_leader.post(
        "/api/v1/attendance", json={"service_id": service["id"], "member_id": member["id"]}
    )
    assert marked.status_code == 201
    assert marked.json()["checked_in_by"] == "00000000-0000-0000-0000-000000000001"

    attendees = as_group_leader.get(f"/api/v1/attendance/services/{service['id']}/attendees")
    assert attendees.status_code == 200
    assert len(attendees.json()) == 1


def test_finance_admin_cannot_mark_attendance(as_finance_admin, fake_congregations):
    congregation = fake_congregations.create({"name": "English Service"})
    service_response = as_finance_admin.post(
        "/api/v1/attendance/services",
        json={
            "name": "Sunday Service",
            "service_date": "2026-08-09",
            "congregation_id": congregation["id"],
        },
    )
    # finance_admin isn't in MARK_ROLES, so it can't even create the service.
    assert service_response.status_code == 403


def test_report_counts_attendees_per_service(as_admin, fake_members, fake_congregations):
    member_a = fake_members.create({"full_name": "Ama Owusu"})
    member_b = fake_members.create({"full_name": "Kwame Mensah"})
    congregation = fake_congregations.create({"name": "English Service"})

    service = as_admin.post(
        "/api/v1/attendance/services",
        json={
            "name": "Sunday Service",
            "service_date": "2026-08-09",
            "congregation_id": congregation["id"],
        },
    ).json()
    for member in (member_a, member_b):
        as_admin.post(
            "/api/v1/attendance", json={"service_id": service["id"], "member_id": member["id"]}
        )

    report = as_admin.get("/api/v1/attendance/report").json()
    assert report == [
        {
            "service_id": service["id"],
            "service_name": "Sunday Service",
            "service_date": "2026-08-09",
            "congregation_id": congregation["id"],
            "attendee_count": 2,
        }
    ]


def test_report_export_returns_csv(as_admin, fake_members, fake_congregations):
    member = fake_members.create({"full_name": "Ama Owusu"})
    congregation = fake_congregations.create({"name": "English Service"})
    service = as_admin.post(
        "/api/v1/attendance/services",
        json={
            "name": "Sunday Service",
            "service_date": "2026-08-09",
            "congregation_id": congregation["id"],
        },
    ).json()
    as_admin.post(
        "/api/v1/attendance", json={"service_id": service["id"], "member_id": member["id"]}
    )

    response = as_admin.get("/api/v1/attendance/report/export")
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/csv")
    assert "Sunday Service" in response.text


def test_report_export_404_when_no_services(as_admin):
    response = as_admin.get("/api/v1/attendance/report/export")
    assert response.status_code == 404
