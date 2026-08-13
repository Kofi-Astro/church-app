"""
initialize_transaction isn't a repository behind app.dependency_overrides
(it's a plain function that calls out to Paystack) — tests monkeypatch it
directly on app.api.v1.giving, the same idea test_supabase.py uses to
force get_settings into a known state rather than relying on whatever's
in the local .env.
"""
from app.core.deps import get_current_profile
from app.core.paystack import PaystackNotConfigured
from app.main import app
from app.schemas.profile import Role
from tests.conftest import as_profile

MEMBER_A = "30000000-0000-0000-0000-00000000000a"
MEMBER_B = "30000000-0000-0000-0000-00000000000b"


def _act_as(profile_id: str, role: Role):
    app.dependency_overrides[get_current_profile] = as_profile(profile_id, role)


def _fake_paystack_success(**kwargs):
    return {"authorization_url": "https://paystack.test/pay/abc123", "access_code": "abc123"}


def test_initialize_returns_503_when_paystack_is_not_configured(as_admin, monkeypatch):
    def _raise(**kwargs):
        raise PaystackNotConfigured("Giving isn't connected to Paystack yet")

    monkeypatch.setattr("app.api.v1.giving.initialize_transaction", _raise)
    _act_as(MEMBER_A, Role.member)

    response = as_admin.post(
        "/api/v1/giving/initialize", json={"amount": "50.00", "giving_type": "tithe"}
    )
    assert response.status_code == 503
    assert "Paystack" in response.json()["detail"]


def test_initialize_creates_a_pending_transaction_when_paystack_succeeds(as_admin, monkeypatch):
    monkeypatch.setattr("app.api.v1.giving.initialize_transaction", _fake_paystack_success)
    _act_as(MEMBER_A, Role.member)

    response = as_admin.post(
        "/api/v1/giving/initialize",
        json={"amount": "100.50", "giving_type": "offering", "note": "For the building fund"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["authorization_url"] == "https://paystack.test/pay/abc123"
    assert body["transaction_id"]
    assert body["reference"]

    history = as_admin.get("/api/v1/giving/history")
    items = history.json()["items"]
    assert len(items) == 1
    assert items[0]["amount"] == "100.50"
    assert items[0]["status"] == "pending"
    assert items[0]["giving_type"] == "offering"


def test_a_member_only_sees_their_own_giving_history(as_admin, monkeypatch):
    monkeypatch.setattr("app.api.v1.giving.initialize_transaction", _fake_paystack_success)

    _act_as(MEMBER_A, Role.member)
    as_admin.post("/api/v1/giving/initialize", json={"amount": "10.00", "giving_type": "tithe"})

    _act_as(MEMBER_B, Role.member)
    response = as_admin.get("/api/v1/giving/history")
    assert response.json()["items"] == []


def test_only_admin_and_finance_admin_can_read_all_transactions(as_admin, monkeypatch):
    monkeypatch.setattr("app.api.v1.giving.initialize_transaction", _fake_paystack_success)

    _act_as(MEMBER_A, Role.member)
    as_admin.post("/api/v1/giving/initialize", json={"amount": "25.00", "giving_type": "tithe"})

    _act_as(MEMBER_B, Role.member)
    forbidden = as_admin.get("/api/v1/giving/transactions")
    assert forbidden.status_code == 403

    _act_as(MEMBER_B, Role.finance_admin)
    allowed = as_admin.get("/api/v1/giving/transactions")
    assert allowed.status_code == 200
    assert len(allowed.json()["items"]) == 1
