import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import 'models.dart';

class SermonService {
  final ApiClient _client;
  const SermonService(this._client);

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

  Future<ChurchSettings> getChurchSettings() async {
    final json = await _client.get('/api/v1/church-settings');
    return ChurchSettings.fromJson(json as Map<String, dynamic>);
  }

  Future<ChurchSettings> updateLivestreamUrl(String? url) async {
    final json = await _client.patch('/api/v1/church-settings', body: {'livestream_url': url});
    return ChurchSettings.fromJson(json as Map<String, dynamic>);
  }

  static String _dateOnly(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
