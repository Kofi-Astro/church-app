// Talks to the backend's /api/v1/prayer-requests endpoints: listing
// requests visible to the current user, posting new ones, and the
// "I'm praying for this" toggle.
import '../../core/network/api_client.dart';
import 'models.dart';

/// API wrapper for prayer requests.
class PrayerService {
  final ApiClient _client;
  const PrayerService(this._client);

  /// Fetches prayer requests visible to the current user (visibility
  /// filtering is enforced by the backend based on the caller's role).
  Future<List<PrayerRequest>> listRequests() async {
    final json = await _client.get('/api/v1/prayer-requests');
    return (json as List).map((e) => PrayerRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Posts a new prayer request with the given visibility.
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

  /// Marks the current user as praying for `requestId`, returning the
  /// updated request (with incremented `prayingCount`).
  Future<PrayerRequest> pray(String requestId) async {
    final json = await _client.post('/api/v1/prayer-requests/$requestId/pray');
    return PrayerRequest.fromJson(json as Map<String, dynamic>);
  }

  /// Undoes [pray] — removes the current user from the "praying" list.
  Future<PrayerRequest> unpray(String requestId) async {
    final json = await _client.delete('/api/v1/prayer-requests/$requestId/pray');
    return PrayerRequest.fromJson(json as Map<String, dynamic>);
  }

  /// Deletes a prayer request (author or admin only, enforced by the
  /// backend).
  Future<void> deleteRequest(String requestId) async {
    await _client.delete('/api/v1/prayer-requests/$requestId');
  }
}
