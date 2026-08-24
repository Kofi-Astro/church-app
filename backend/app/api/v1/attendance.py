"""
Routes for services (gatherings) and attendance check-ins, plus an attendance
report and a CSV export of that report.
"""
import csv
import io
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse

from app.core.deps import require_role
from app.repositories.attendance import AttendanceRepository, get_attendance_repository
from app.schemas.attendance import (
    AttendanceCreate,
    AttendanceRead,
    AttendanceReportRow,
    ServiceCreate,
    ServiceRead,
)

router = APIRouter(prefix="/attendance", tags=["attendance"])

# Matches attendance/services RLS in infra/migrations: admin + group_leader
# can mark attendance and manage services; finance_admin can read reports
# but not mark attendance (no reason for that role to touch check-in).
require_mark = require_role("admin", "group_leader")
require_read = require_role("admin", "finance_admin", "group_leader")


# Creates a new service (e.g. "Sunday 9am"). admin/group_leader only.
@router.post("/services", response_model=ServiceRead, status_code=status.HTTP_201_CREATED)
async def create_service(
    payload: ServiceCreate,
    repo: AttendanceRepository = Depends(get_attendance_repository),
    _profile=Depends(require_mark),
):
    data = payload.model_dump()
    data["service_date"] = data["service_date"].isoformat()
    return repo.create_service(data)


# Lists services, optionally filtered to a date range. admin/finance_admin/group_leader.
@router.get("/services", response_model=list[ServiceRead])
async def list_services(
    start: date | None = Query(default=None),
    end: date | None = Query(default=None),
    repo: AttendanceRepository = Depends(get_attendance_repository),
    _profile=Depends(require_read),
):
    return repo.list_services(start=start, end=end)


# Checks a member in to a service; records who performed the check-in. admin/group_leader.
@router.post("", response_model=AttendanceRead, status_code=status.HTTP_201_CREATED)
async def mark_attendance(
    payload: AttendanceCreate,
    repo: AttendanceRepository = Depends(get_attendance_repository),
    profile=Depends(require_mark),
):
    data = payload.model_dump()
    data["checked_in_by"] = profile.id
    return repo.mark_attendance(data)


# Lists everyone checked in to a given service. admin/finance_admin/group_leader.
@router.get("/services/{service_id}/attendees", response_model=list[AttendanceRead])
async def list_attendees(
    service_id: str,
    repo: AttendanceRepository = Depends(get_attendance_repository),
    _profile=Depends(require_read),
):
    return repo.list_for_service(service_id)


# Attendee counts per service over a date range, as JSON. admin/finance_admin/group_leader.
@router.get("/report", response_model=list[AttendanceReportRow])
async def attendance_report(
    start: date | None = Query(default=None),
    end: date | None = Query(default=None),
    repo: AttendanceRepository = Depends(get_attendance_repository),
    _profile=Depends(require_read),
):
    return repo.report(start=start, end=end)


# Same report as above, but returned as a downloadable CSV file (for spreadsheets).
@router.get("/report/export")
async def attendance_report_csv(
    start: date | None = Query(default=None),
    end: date | None = Query(default=None),
    repo: AttendanceRepository = Depends(get_attendance_repository),
    _profile=Depends(require_read),
):
    rows = repo.report(start=start, end=end)
    if not rows:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No services in that date range")

    # Build the CSV in memory (no temp file needed) then stream it back as an
    # attachment so the browser/app downloads it instead of displaying it.
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(
        ["service_id", "service_name", "service_date", "congregation_id", "attendee_count"]
    )
    for row in rows:
        writer.writerow(
            [
                row["service_id"],
                row["service_name"],
                row["service_date"],
                row["congregation_id"],
                row["attendee_count"],
            ]
        )
    buffer.seek(0)

    return StreamingResponse(
        iter([buffer.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=attendance_report.csv"},
    )
