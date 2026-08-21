"""Generic pagination wrapper shared by list endpoints across the API."""
from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    """
    A generic "one page of results" envelope, e.g. Page[MemberRead]. Callers use
    `limit`/`offset` to page through more than one screen's worth of `items`,
    and `total` to know how many results exist overall (e.g. for a page count).
    """

    items: list[T]
    total: int
    limit: int
    offset: int
