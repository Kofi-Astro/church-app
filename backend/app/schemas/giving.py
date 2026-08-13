from datetime import datetime
from decimal import Decimal
from enum import Enum

from pydantic import BaseModel, Field

# Matches the church's Paystack account currency — not user-selectable
# today since a single church has one settlement currency. Revisit if
# this app ever serves congregations settling in different currencies.
DEFAULT_CURRENCY = "GHS"


class GivingType(str, Enum):
    tithe = "tithe"
    offering = "offering"
    special = "special"
    other = "other"


class GivingStatus(str, Enum):
    pending = "pending"
    success = "success"
    failed = "failed"


class GivingInitializeRequest(BaseModel):
    amount: Decimal = Field(gt=0, le=Decimal("1000000"), decimal_places=2)
    giving_type: GivingType = GivingType.tithe
    note: str | None = Field(default=None, max_length=500)


class GivingInitializeResponse(BaseModel):
    transaction_id: str
    authorization_url: str
    reference: str


class GivingTransactionRead(BaseModel):
    id: str
    profile_id: str
    amount: Decimal
    currency: str
    giving_type: GivingType
    note: str | None
    status: GivingStatus
    paystack_reference: str | None
    created_at: datetime
