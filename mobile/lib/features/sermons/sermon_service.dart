import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import 'models.dart';

/// Calls the /api/v1/sermons and /api/v1/church-settings endpoints.
class SermonService {
  final ApiClient _client;
  const SermonService(this._client);

  /// Lists sermons, optionally filtered by series/speaker/free-text
  /// [search], newest [limit] at a time starting at [offset].
  Future<PagedResult<Sermon>> listSermons({
    int limit = 25,
    int offset = 0,
    String? series,
    String? speaker,
    String? search,
  }) async {
    final json = await _client.get(
      '/api/v1/sermons',
      query: {
        'limit': limit,
        'offset': offset,
        'series': ?series,
        'speaker': ?speaker,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PagedResult.fromJson(json as Map<String, dynamic>, Sermon.fromJson);
  }

  /// Creates a new sermon entry (admin-only server-side).
  Future<Sermon> createSermon({
    required String title,
    String? speaker,
    String? series,
    required DateTime sermonDate,
    String? videoUrl,
    String? description,
  }) async {
    final json = await _client.post(
      '/api/v1/sermons',
      body: {
        'title': title,
        'sermon_date': _dateOnly(sermonDate),
        if (speaker != null && speaker.isNotEmpty) 'speaker': speaker,
        if (series != null && series.isNotEmpty) 'series': series,
        if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    return Sermon.fromJson(json as Map<String, dynamic>);
  }

  /// Fetches church-wide settings (currently just the livestream URL).
  Future<ChurchSettings> getChurchSettings() async {
    final json = await _client.get('/api/v1/church-settings');
    return ChurchSettings.fromJson(json as Map<String, dynamic>);
  }

  /// Updates the livestream URL shown in the "Watch live" banner — pass
  /// null (or empty, per the caller's convention) to clear/hide it.
  Future<ChurchSettings> updateLivestreamUrl(String? url) async {
    final json = await _client.patch('/api/v1/church-settings', body: {'livestream_url': url});
    return ChurchSettings.fromJson(json as Map<String, dynamic>);
  }

  // Formats a DateTime as just the date part (yyyy-MM-dd) for the API.
  static String _dateOnly(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
