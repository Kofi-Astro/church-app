// Data models for the Small Groups feature: a group itself, its
// members, and materials (links/resources) shared within it.

/// A small group (e.g. a home fellowship or Bible study group).
class SmallGroup {
  final String id;
  final String name;
  /// Optional description of the group; null if none was set.
  final String? description;
  /// Profile id of the group's leader, or null if no leader is assigned.
  final String? leaderId;
  final DateTime createdAt;

  const SmallGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.createdAt,
  });

  /// Builds a [SmallGroup] from the JSON object the backend returns.
  factory SmallGroup.fromJson(Map<String, dynamic> json) => SmallGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        leaderId: json['leader_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Membership record linking a profile to a group.
class GroupMember {
  final String groupId;
  final String profileId;
  final DateTime joinedAt;

  const GroupMember({required this.groupId, required this.profileId, required this.joinedAt});

  /// Builds a [GroupMember] from the JSON object the backend returns.
  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        groupId: json['group_id'] as String,
        profileId: json['profile_id'] as String,
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );
}

/// A resource (e.g. a study guide link) shared within a group.
class GroupMaterial {
  final String id;
  final String groupId;
  final String title;
  /// Optional link to the resource; null if this material has no URL.
  final String? url;
  /// Optional longer description; null if none was set.
  final String? description;
  final DateTime createdAt;

  const GroupMaterial({
    required this.id,
    required this.groupId,
    required this.title,
    required this.url,
    required this.description,
    required this.createdAt,
  });

  /// Builds a [GroupMaterial] from the JSON object the backend returns.
  factory GroupMaterial.fromJson(Map<String, dynamic> json) => GroupMaterial(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        title: json['title'] as String,
        url: json['url'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
