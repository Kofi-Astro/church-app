import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import 'models.dart';

class GivingService {
  final ApiClient _client;
  const GivingService(this._client);

  Future<GivingInitializeResult> initialize({
    required String amount,
    required GivingType givingType,
    String? note,
  }) async {
    final json = await _client.post(
      '/api/v1/giving/initialize',
      body: {
        'amount': amount,
        'giving_type': givingType.apiValue,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return GivingInitializeResult.fromJson(json as Map<String, dynamic>);
  }

  Future<PagedResult<GivingTransaction>> myHistory({int limit = 25, int offset = 0}) async {
    final json = await _client.get(
      '/api/v1/giving/history',
      query: {'limit': limit, 'offset': offset},
    ) as Map<String, dynamic>;
    return PagedResult.fromJson(json, GivingTransaction.fromJson);
  }
}
