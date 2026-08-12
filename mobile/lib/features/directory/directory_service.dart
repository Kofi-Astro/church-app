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

  Future<PagedResult<Household>> listHouseholds({int limit = 25, int offset = 0}) async {
    final json = await _client.get(
      '/api/v1/households',
      query: {'limit': limit, 'offset': offset},
    );
    return PagedResult.fromJson(json as Map<String, dynamic>, Household.fromJson);
  }

  Future<Household> createHousehold({required String name, String? address}) async {
    final json = await _client.post(
      '/api/v1/households',
      body: {'name': name, if (address != null && address.isNotEmpty) 'address': address},
    );
    return Household.fromJson(json as Map<String, dynamic>);
  }

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
