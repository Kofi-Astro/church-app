import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import 'models.dart';

/// Calls the /api/v1/attendance* endpoints: creating services, checking
/// members in, and pulling attendance reports/exports.
class AttendanceService {
  final ApiClient _client;
  const AttendanceService(this._client);

  // Formats a DateTime as just the date part (yyyy-MM-dd) — the backend
  // stores/expects service dates without a time component.
  static String _dateOnly(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // Builds the {start, end} query params shared by the list/report
  // endpoints, formatting each bound as a date-only string and omitting
  // whichever side wasn't given.
  static Map<String, String?> _range(DateTime? start, DateTime? end) => {
        'start': start != null ? _dateOnly(start) : null,
        'end': end != null ? _dateOnly(end) : null,
      };

  /// Creates a new church service (e.g. "Sunday Service") on [date] for a
  /// specific [congregationId] — every new service must be attributed to
  /// one of the church's congregations.
  Future<ChurchService> createService({
    required String name,
    required DateTime date,
    required String congregationId,
  }) async {
    final json = await _client.post(
      '/api/v1/attendance/services',
      body: {'name': name, 'service_date': _dateOnly(date), 'congregation_id': congregationId},
    );
    return ChurchService.fromJson(json as Map<String, dynamic>);
  }

  /// Lists services, optionally restricted to a date range.
  Future<List<ChurchService>> listServices({DateTime? start, DateTime? end}) async {
    final json = await _client.get('/api/v1/attendance/services', query: _range(start, end));
    return (json as List).map((e) => ChurchService.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Records that [memberId] attended [serviceId] (i.e. checks them in).
  Future<AttendanceRecord> markAttendance({
    required String serviceId,
    required String memberId,
  }) async {
    final json = await _client.post(
      '/api/v1/attendance',
      body: {'service_id': serviceId, 'member_id': memberId},
    );
    return AttendanceRecord.fromJson(json as Map<String, dynamic>);
  }

  /// Lists everyone checked in to a given service.
  Future<List<AttendanceRecord>> listAttendees(String serviceId) async {
    final json = await _client.get('/api/v1/attendance/services/$serviceId/attendees');
    return (json as List)
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches per-service attendance totals for the given date range, used
  /// to build the attendance report screen.
  Future<List<AttendanceReportRow>> report({DateTime? start, DateTime? end}) async {
    final json = await _client.get('/api/v1/attendance/report', query: _range(start, end));
    return (json as List)
        .map((e) => AttendanceReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the attendance report as a raw CSV string (for sharing/export)
  /// rather than as parsed JSON rows.
  Future<String> exportCsv({DateTime? start, DateTime? end}) {
    return _client.getRaw('/api/v1/attendance/report/export', query: _range(start, end));
  }
}
