// Data models for the attendance feature (services, check-ins, and
// report rows), matching the shapes returned by /api/v1/attendance*.

/// A single church service/gathering (e.g. "Sunday Service, Aug 24") that
/// members can be checked in to.
class ChurchService {
  final String id;
  final String name;
  final DateTime serviceDate;
  /// Which congregation (English, Akan, Youth Chapel, ...) this dated
  /// gathering is for. Nullable in the read model only because rows from
  /// before congregations existed may not have one — new services always
  /// require one (see AttendanceService.createService).
  final String? congregationId;
  final DateTime createdAt;

  const ChurchService({
    required this.id,
    required this.name,
    required this.serviceDate,
    required this.congregationId,
    required this.createdAt,
  });

  /// Builds a [ChurchService] from the raw JSON map returned by the API.
  factory ChurchService.fromJson(Map<String, dynamic> json) => ChurchService(
        id: json['id'] as String,
        name: json['name'] as String,
        serviceDate: DateTime.parse(json['service_date'] as String),
        congregationId: json['congregation_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// One member's check-in to one service.
class AttendanceRecord {
  final String id;
  final String serviceId;
  final String memberId;
  final DateTime checkedInAt;
  /// Who performed the check-in (e.g. the leader running the door), if
  /// recorded.
  final String? checkedInBy;

  const AttendanceRecord({
    required this.id,
    required this.serviceId,
    required this.memberId,
    required this.checkedInAt,
    required this.checkedInBy,
  });

  /// Builds an [AttendanceRecord] from the raw JSON map returned by the API.
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        id: json['id'] as String,
        serviceId: json['service_id'] as String,
        memberId: json['member_id'] as String,
        checkedInAt: DateTime.parse(json['checked_in_at'] as String),
        checkedInBy: json['checked_in_by'] as String?,
      );
}

/// One row in the attendance report: a service and how many people showed
/// up to it. Used to render the report list and CSV export.
class AttendanceReportRow {
  final String serviceId;
  final String serviceName;
  final DateTime serviceDate;
  final String? congregationId;
  final int attendeeCount;

  const AttendanceReportRow({
    required this.serviceId,
    required this.serviceName,
    required this.serviceDate,
    required this.congregationId,
    required this.attendeeCount,
  });

  /// Builds an [AttendanceReportRow] from the raw JSON map returned by the API.
  factory AttendanceReportRow.fromJson(Map<String, dynamic> json) => AttendanceReportRow(
        serviceId: json['service_id'] as String,
        serviceName: json['service_name'] as String,
        serviceDate: DateTime.parse(json['service_date'] as String),
        congregationId: json['congregation_id'] as String?,
        attendeeCount: json['attendee_count'] as int,
      );
}
