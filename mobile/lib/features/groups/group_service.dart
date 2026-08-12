import '../../core/network/api_client.dart';
import 'models.dart';

class GroupService {
  final ApiClient _client;
  const GroupService(this._client);

  Future<List<SmallGroup>> listGroups() async {
    final json = await _client.get('/api/v1/small-groups');
    return (json as List).map((e) => SmallGroup.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SmallGroup> createGroup({
    required String name,
    String? description,
    String? leaderId,
  }) async {
    final json = await _client.post(
      '/api/v1/small-groups',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'leader_id': ?leaderId,
      },
    );
    return SmallGroup.fromJson(json as Map<String, dynamic>);
  }

  /// Throws ApiException(statusCode: 403) if the caller isn't a member of
  /// this group (or an admin) — see app/api/v1/small_groups.py.
  Future<List<GroupMember>> listMembers(String groupId) async {
    final json = await _client.get('/api/v1/small-groups/$groupId/members');
    return (json as List).map((e) => GroupMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addMember({required String groupId, required String profileId}) async {
    await _client.post(
      '/api/v1/small-groups/$groupId/members',
      body: {'profile_id': profileId},
    );
  }

  Future<void> removeMember({required String groupId, required String profileId}) async {
    await _client.delete('/api/v1/small-groups/$groupId/members/$profileId');
  }

  Future<List<GroupMaterial>> listMaterials(String groupId) async {
    final json = await _client.get('/api/v1/small-groups/$groupId/materials');
    return (json as List).map((e) => GroupMaterial.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GroupMaterial> addMaterial({
    required String groupId,
    required String title,
    String? url,
    String? description,
  }) async {
    final json = await _client.post(
      '/api/v1/small-groups/$groupId/materials',
      body: {
        'title': title,
        if (url != null && url.isNotEmpty) 'url': url,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    return GroupMaterial.fromJson(json as Map<String, dynamic>);
  }
}
