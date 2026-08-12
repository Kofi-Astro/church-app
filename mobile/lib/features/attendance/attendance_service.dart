import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import 'models.dart';

class AttendanceService {
  final ApiClient _client;
  const AttendanceService(this._client);

  static String _dateOnly(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static Map<String, String?> _range(DateTime? start, DateTime? end) => {
        'start': start != null ? _dateOnly(start) : null,
        'end': end != null ? _dateOnly(end) : null,
      };

  Future<ChurchService> createService({required String name, required DateTime date}) async {
    final json = await _client.post(
      '/api/v1/attendance/services',
      body: {'name': name, 'service_date': _dateOnly(date)},
    );
    return ChurchService.fromJson(json as Map<String, dynamic>);
  }

  Future<List<ChurchService>> listServices({DateTime? start, DateTime? end}) async {
    final json = await _client.get('/api/v1/attendance/services', query: _range(start, end));
    return (json as List).map((e) => ChurchService.fromJson(e as Map<String, dynamic>)).toList();
  }

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

  Future<List<AttendanceRecord>> listAttendees(String serviceId) async {
    final json = await _client.get('/api/v1/attendance/services/$serviceId/attendees');
    return (json as List)
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceReportRow>> report({DateTime? start, DateTime? end}) async {
    final json = await _client.get('/api/v1/attendance/report', query: _range(start, end));
    return (json as List)
        .map((e) => AttendanceReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> exportCsv({DateTime? start, DateTime? end}) {
    return _client.getRaw('/api/v1/attendance/report/export', query: _range(start, end));
  }
}
