// Talks to the backend's /api/v1/giving endpoints: starting a Paystack
// giving transaction and fetching the current user's giving history.
import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import 'models.dart';

/// API wrapper for online giving. Note: `initialize` will return a 503
/// (surfaced as ApiException) until the church's Paystack account is
/// configured on the backend — see GivingScreen for how that's handled.
class GivingService {
  final ApiClient _client;
  const GivingService(this._client);

  /// Starts a giving transaction for `amount`/`givingType` and returns the
  /// Paystack authorization URL to open so the user can complete payment.
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

  /// Fetches a page of the current user's past giving transactions,
  /// newest first, `limit`/`offset` pages through the full history.
  Future<PagedResult<GivingTransaction>> myHistory({int limit = 25, int offset = 0}) async {
    final json = await _client.get(
      '/api/v1/giving/history',
      query: {'limit': limit, 'offset': offset},
    ) as Map<String, dynamic>;
    return PagedResult.fromJson(json, GivingTransaction.fromJson);
  }
}
