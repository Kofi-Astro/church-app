"""
Routes for the giving/Paystack flow: starting a transaction, and reading back
giving history (a member's own, or — for finance roles — everyone's).
"""
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.deps import get_current_profile, require_role
from app.core.paystack import PaystackNotConfigured, initialize_transaction
from app.repositories.giving import GivingRepository, get_giving_repository
from app.schemas.giving import (
    DEFAULT_CURRENCY,
    GivingInitializeRequest,
    GivingInitializeResponse,
    GivingTransactionRead,
)
from app.schemas.pagination import Page
from app.schemas.profile import Profile

router = APIRouter(prefix="/giving", tags=["giving"])

# Giving history for *everyone's* transactions is finance-sensitive in the
# same way the roadmap already reserves finance_admin for — see
# docs/threat-model.md's "who can access what" table.
require_finance_read = require_role("admin", "finance_admin")


# Starts a Paystack transaction for the caller and records it as "pending".
# Returns the checkout URL the mobile app should open. Any logged-in user.
# Returns 503 (not 500) if Paystack isn't configured yet — see app/core/paystack.py.
@router.post("/initialize", response_model=GivingInitializeResponse)
async def initialize_giving(
    payload: GivingInitializeRequest,
    repo: GivingRepository = Depends(get_giving_repository),
    profile: Profile = Depends(get_current_profile),
):
    # Unique per-transaction reference so Paystack (and our own records) can
    # tie the checkout session back to this specific attempt.
    reference = f"church-app-{uuid.uuid4().hex}"
    try:
        result = initialize_transaction(
            email=profile.email,
            amount=float(payload.amount),
            currency=DEFAULT_CURRENCY,
            reference=reference,
        )
    except PaystackNotConfigured as exc:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, str(exc)) from exc

    transaction = repo.create_pending(
        {
            "profile_id": profile.id,
            "amount": str(payload.amount),
            "currency": DEFAULT_CURRENCY,
            "giving_type": payload.giving_type.value,
            "note": payload.note,
            "paystack_reference": reference,
        }
    )
    return GivingInitializeResponse(
        transaction_id=transaction["id"],
        authorization_url=result["authorization_url"],
        reference=reference,
    )


# Paginated giving history for the caller's own transactions only. Any logged-in user.
@router.get("/history", response_model=Page[GivingTransactionRead])
async def my_giving_history(
    limit: int = Query(default=25, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    repo: GivingRepository = Depends(get_giving_repository),
    profile: Profile = Depends(get_current_profile),
):
    items, total = repo.list_for_profile(profile.id, limit=limit, offset=offset)
    return Page(items=items, total=total, limit=limit, offset=offset)


# Paginated giving history across every member's transactions. admin/finance_admin only.
@router.get("/transactions", response_model=Page[GivingTransactionRead])
async def all_giving_transactions(
    limit: int = Query(default=25, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    repo: GivingRepository = Depends(get_giving_repository),
    _profile: Profile = Depends(require_finance_read),
):
    items, total = repo.list_all(limit=limit, offset=offset)
    return Page(items=items, total=total, limit=limit, offset=offset)
