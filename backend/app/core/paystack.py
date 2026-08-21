"""
Paystack client — a thin wrapper around the one REST call Phase 5 needs
("Initialize Transaction"), not a full SDK. Keeping it this small means
the "not configured yet" gap is one explicit exception, not something
hidden behind a dependency that might fail in a confusing way.

Mirrors app/core/supabase.py's pattern: built lazily, raises a clear
error when unconfigured rather than letting a network call fail oddly.
"""
import httpx

from app.core.config import get_settings

PAYSTACK_BASE_URL = "https://api.paystack.co"


class PaystackNotConfigured(RuntimeError):
    """Raised when PAYSTACK_SECRET_KEY is unset; the API layer turns this into a 503."""

    pass


def initialize_transaction(
    *, email: str, amount: float, currency: str, reference: str
) -> dict:
    """
    Starts a Paystack transaction and returns its `data` payload (notably
    `authorization_url`, the page the mobile app opens to complete
    payment, and `access_code`). Raises PaystackNotConfigured if
    PAYSTACK_SECRET_KEY isn't set — the caller turns that into a 503.
    """
    settings = get_settings()
    if not settings.paystack_secret_key:
        raise PaystackNotConfigured(
            "Giving isn't connected to Paystack yet (PAYSTACK_SECRET_KEY is not "
            "set) — see infra/infra.md for how to add it once the church's "
            "Paystack account exists."
        )

    response = httpx.post(
        f"{PAYSTACK_BASE_URL}/transaction/initialize",
        json={
            # Paystack expects amounts in the smallest currency unit
            # (e.g. pesewas for GHS, kobo for NGN), not decimal major units.
            "amount": int(round(amount * 100)),
            "currency": currency,
            "email": email,
            "reference": reference,
        },
        headers={"Authorization": f"Bearer {settings.paystack_secret_key}"},
        timeout=15.0,
    )
    response.raise_for_status()
    return response.json()["data"]
