import '../../core/network/api_client.dart';
import 'models.dart';

class PrayerService {
  final ApiClient _client;
  const PrayerService(this._client);

  Future<List<PrayerRequest>> listRequests() async {
    final json = await _client.get('/api/v1/prayer-requests');
    return (json as List).map((e) => PrayerRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PrayerRequest> createRequest({
    required String content,
    required PrayerVisibility visibility,
  }) async {
    final json = await _client.post(
      '/api/v1/prayer-requests',
      body: {'content': content, 'visibility': visibility.apiValue},
    );
    return PrayerRequest.fromJson(json as Map<String, dynamic>);
  }

  Future<PrayerRequest> pray(String requestId) async {
    final json = await _client.post('/api/v1/prayer-requests/$requestId/pray');
    return PrayerRequest.fromJson(json as Map<String, dynamic>);
  }

  Future<PrayerRequest> unpray(String requestId) async {
    final json = await _client.delete('/api/v1/prayer-requests/$requestId/pray');
    return PrayerRequest.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteRequest(String requestId) async {
    await _client.delete('/api/v1/prayer-requests/$requestId');
  }
}
