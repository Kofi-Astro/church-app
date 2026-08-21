"""Routes for church events and member RSVPs to them."""
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.deps import get_current_profile, require_role
from app.repositories.events import EventRepository, get_event_repository
from app.schemas.event import EventCreate, EventRead, RsvpCreate
from app.schemas.profile import Profile

router = APIRouter(prefix="/events", tags=["events"])

require_write = require_role("admin")


# Shared helper: turns a raw event row into the EventRead shape the API returns,
# filling in the RSVP tally and this caller's own RSVP status along the way.
def _to_read_model(event: dict, profile: Profile, repo: EventRepository) -> EventRead:
    return EventRead(
        **event,
        rsvp_counts=repo.rsvp_counts(event["id"]),
        my_rsvp=repo.my_rsvp(event["id"], profile.id),
    )


# Lists all events with RSVP counts and the caller's own RSVP. Any logged-in user.
@router.get("", response_model=list[EventRead])
async def list_events(
    repo: EventRepository = Depends(get_event_repository),
    profile: Profile = Depends(get_current_profile),
):
    return [_to_read_model(e, profile, repo) for e in repo.list()]


# Fetches one event by id. 404 if it doesn't exist. Any logged-in user.
@router.get("/{event_id}", response_model=EventRead)
async def get_event(
    event_id: str,
    repo: EventRepository = Depends(get_event_repository),
    profile: Profile = Depends(get_current_profile),
):
    event = repo.get(event_id)
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    return _to_read_model(event, profile, repo)


# Creates a new event. admin only.
@router.post("", response_model=EventRead, status_code=status.HTTP_201_CREATED)
async def create_event(
    payload: EventCreate,
    repo: EventRepository = Depends(get_event_repository),
    profile: Profile = Depends(require_write),
):
    data = payload.model_dump()
    data["event_date"] = data["event_date"].isoformat()
    data["created_by"] = profile.id
    event = repo.create(data)
    return _to_read_model(event, profile, repo)


# Deletes an event. 404 if it doesn't exist. admin only.
@router.delete("/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_event(
    event_id: str,
    repo: EventRepository = Depends(get_event_repository),
    _profile=Depends(require_write),
):
    if not repo.delete(event_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")


# Sets (creates or updates) the caller's own RSVP for an event. Any logged-in user.
@router.put("/{event_id}/rsvp", response_model=EventRead)
async def set_rsvp(
    event_id: str,
    payload: RsvpCreate,
    repo: EventRepository = Depends(get_event_repository),
    profile: Profile = Depends(get_current_profile),
):
    event = repo.get(event_id)
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    repo.upsert_rsvp(event_id, profile.id, payload.status.value)
    return _to_read_model(event, profile, repo)


# Clears (removes) the caller's own RSVP for an event. Any logged-in user.
@router.delete("/{event_id}/rsvp", response_model=EventRead)
async def clear_rsvp(
    event_id: str,
    repo: EventRepository = Depends(get_event_repository),
    profile: Profile = Depends(get_current_profile),
):
    event = repo.get(event_id)
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    repo.remove_rsvp(event_id, profile.id)
    return _to_read_model(event, profile, repo)
