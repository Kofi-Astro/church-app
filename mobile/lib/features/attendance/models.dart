class ChurchService {
  final String id;
  final String name;
  final DateTime serviceDate;
  final DateTime createdAt;

  const ChurchService({
    required this.id,
    required this.name,
    required this.serviceDate,
    required this.createdAt,
  });

  factory ChurchService.fromJson(Map<String, dynamic> json) => ChurchService(
        id: json['id'] as String,
        name: json['name'] as String,
        serviceDate: DateTime.parse(json['service_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class AttendanceRecord {
  final String id;
  final String serviceId;
  final String memberId;
  final DateTime checkedInAt;
  final String? checkedInBy;

  const AttendanceRecord({
    required this.id,
    required this.serviceId,
    required this.memberId,
    required this.checkedInAt,
    required this.checkedInBy,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        id: json['id'] as String,
        serviceId: json['service_id'] as String,
        memberId: json['member_id'] as String,
        checkedInAt: DateTime.parse(json['checked_in_at'] as String),
        checkedInBy: json['checked_in_by'] as String?,
      );
}

class AttendanceReportRow {
  final String serviceId;
  final String serviceName;
  final DateTime serviceDate;
  final int attendeeCount;

  const AttendanceReportRow({
    required this.serviceId,
    required this.serviceName,
    required this.serviceDate,
    required this.attendeeCount,
  });

  factory AttendanceReportRow.fromJson(Map<String, dynamic> json) => AttendanceReportRow(
        serviceId: json['service_id'] as String,
        serviceName: json['service_name'] as String,
        serviceDate: DateTime.parse(json['service_date'] as String),
        attendeeCount: json['attendee_count'] as int,
      );
}
