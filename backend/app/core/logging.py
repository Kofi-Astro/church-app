"""
Structured logging setup.

Uses the standard library logging module with a JSON-ish formatter so logs
are easy to parse in hosting dashboards (Render/Railway/Fly.io all show raw
stdout). Kept deliberately simple for Phase 0 — swap in structlog later if
richer structured logging is needed.

Security note: never log request/response bodies wholesale once payment or
member-record endpoints exist (Phase 1+) — log identifiers, not payloads.
"""
import logging
import sys

from app.core.config import get_settings


def configure_logging() -> None:
    settings = get_settings()

    handler = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter(
        fmt='{"time": "%(asctime)s", "level": "%(levelname)s", '
        '"logger": "%(name)s", "message": "%(message)s"}',
        datefmt="%Y-%m-%dT%H:%M:%S%z",
    )
    handler.setFormatter(formatter)

    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(settings.log_level.upper())

    # Quiet down noisy third-party loggers by default.
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
