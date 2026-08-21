import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import 'models.dart';

/// Calls the /api/v1/households and /api/v1/members endpoints. Role
/// enforcement happens server-side (see backend/app/core/deps.py) — this
/// class doesn't duplicate that logic, it just surfaces whatever error
/// the API returns (e.g. a 403 from ApiClient) to the calling screen.
class DirectoryService {
  final ApiClient _client;
  const DirectoryService(this._client);

  /// Fetches a page of households, newest/whatever order the API defaults
  /// to, [limit] at a time starting at [offset].
  Future<PagedResult<Household>> listHouseholds({int limit = 25, int offset = 0}) async {
    final json = await _client.get(
      '/api/v1/households',
      query: {'limit': limit, 'offset': offset},
    );
    return PagedResult.fromJson(json as Map<String, dynamic>, Household.fromJson);
  }

  /// Creates a new household with the given [name] and optional [address].
  Future<Household> createHousehold({required String name, String? address}) async {
    final json = await _client.post(
      '/api/v1/households',
      body: {'name': name, if (address != null && address.isNotEmpty) 'address': address},
    );
    return Household.fromJson(json as Map<String, dynamic>);
  }

  /// Fetches a page of members, optionally filtered by a [search] term
  /// (name/email/phone match, server-side) and/or restricted to one
  /// [householdId].
  Future<PagedResult<Member>> listMembers({
    int limit = 25,
    int offset = 0,
    String? search,
    String? householdId,
  }) async {
    final json = await _client.get(
      '/api/v1/members',
      query: {
        'limit': limit,
        'offset': offset,
        if (search != null && search.isNotEmpty) 'search': search,
        'household_id': ?householdId,
      },
    );
    return PagedResult.fromJson(json as Map<String, dynamic>, Member.fromJson);
  }

  /// Creates a new member, optionally attaching them to a household and
  /// recording contact info.
  Future<Member> createMember({
    required String fullName,
    String? email,
    String? phone,
    String? householdId,
  }) async {
    final json = await _client.post(
      '/api/v1/members',
      body: {
        'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'household_id': ?householdId,
      },
    );
    return Member.fromJson(json as Map<String, dynamic>);
  }
}
