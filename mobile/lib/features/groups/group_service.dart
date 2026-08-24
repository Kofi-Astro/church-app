// Talks to the backend's /api/v1/small-groups endpoints: listing groups,
// managing membership, and sharing materials within a group.
import '../../core/network/api_client.dart';
import 'models.dart';

/// API wrapper for small groups: the group list itself, member management,
/// and shared materials (links/resources) within a group.
class GroupService {
  final ApiClient _client;
  const GroupService(this._client);

  /// Fetches all small groups visible to the current user.
  Future<List<SmallGroup>> listGroups() async {
    final json = await _client.get('/api/v1/small-groups');
    return (json as List).map((e) => SmallGroup.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Creates a new small group or auxiliary (admin-only on the backend).
  /// `leaderId` is sent only if provided, using the `?` null-aware
  /// map-entry spread. Defaults to [GroupCategory.smallGroup] when
  /// [category] isn't given.
  Future<SmallGroup> createGroup({
    required String name,
    String? description,
    String? leaderId,
    GroupCategory category = GroupCategory.smallGroup,
  }) async {
    final json = await _client.post(
      '/api/v1/small-groups',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'leader_id': ?leaderId,
        'category': category.apiValue,
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

  /// Adds `profileId` as a member of `groupId` (admin/leader-only on the
  /// backend).
  Future<void> addMember({required String groupId, required String profileId}) async {
    await _client.post(
      '/api/v1/small-groups/$groupId/members',
      body: {'profile_id': profileId},
    );
  }

  /// Removes `profileId` from `groupId`'s membership.
  Future<void> removeMember({required String groupId, required String profileId}) async {
    await _client.delete('/api/v1/small-groups/$groupId/members/$profileId');
  }

  /// Fetches shared materials (links/resources) for a group. Like
  /// [listMembers], this throws a 403 if the caller isn't a member/admin.
  Future<List<GroupMaterial>> listMaterials(String groupId) async {
    final json = await _client.get('/api/v1/small-groups/$groupId/materials');
    return (json as List).map((e) => GroupMaterial.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Adds a new shared material (title + optional link/description) to a
  /// group.
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
