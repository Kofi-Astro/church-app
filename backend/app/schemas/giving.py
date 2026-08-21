"""
Pydantic schemas for the giving/Paystack flow: a member initializes a
transaction (which hands back a Paystack checkout URL), and the resulting
transaction rows can later be read back as history.
"""
from datetime import datetime
from decimal import Decimal
from enum import Enum

from pydantic import BaseModel, Field

# Matches the church's Paystack account currency — not user-selectable
# today since a single church has one settlement currency. Revisit if
# this app ever serves congregations settling in different currencies.
DEFAULT_CURRENCY = "GHS"


class GivingType(str, Enum):
    """What category of giving a transaction is for."""

    tithe = "tithe"
    offering = "offering"
    special = "special"
    other = "other"


class GivingStatus(str, Enum):
    """Lifecycle state of a giving transaction, mirroring Paystack's transaction status."""

    pending = "pending"
    success = "success"
    failed = "failed"


class GivingInitializeRequest(BaseModel):
    """Payload to start a new Paystack transaction."""

    # Capped at 1,000,000 as a sanity guard against fat-fingered amounts, not
    # a real business limit.
    amount: Decimal = Field(gt=0, le=Decimal("1000000"), decimal_places=2)
    giving_type: GivingType = GivingType.tithe
    note: str | None = Field(default=None, max_length=500)


class GivingInitializeResponse(BaseModel):
    """What the API returns after starting a transaction with Paystack."""

    transaction_id: str
    # The Paystack-hosted checkout page the mobile app should open next.
    authorization_url: str
    # Unique reference tying this transaction back to Paystack's records.
    reference: str


class GivingTransactionRead(BaseModel):
    """A giving transaction record as returned by the API (e.g. in giving history)."""

    id: str
    profile_id: str
    amount: Decimal
    currency: str
    giving_type: GivingType
    note: str | None
    status: GivingStatus
    # None until Paystack assigns/confirms a reference for this transaction.
    paystack_reference: str | None
    created_at: datetime
