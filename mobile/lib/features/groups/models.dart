class SmallGroup {
  final String id;
  final String name;
  final String? description;
  final String? leaderId;
  final DateTime createdAt;

  const SmallGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.createdAt,
  });

  factory SmallGroup.fromJson(Map<String, dynamic> json) => SmallGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        leaderId: json['leader_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class GroupMember {
  final String groupId;
  final String profileId;
  final DateTime joinedAt;

  const GroupMember({required this.groupId, required this.profileId, required this.joinedAt});

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        groupId: json['group_id'] as String,
        profileId: json['profile_id'] as String,
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );
}

class GroupMaterial {
  final String id;
  final String groupId;
  final String title;
  final String? url;
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

  factory GroupMaterial.fromJson(Map<String, dynamic> json) => GroupMaterial(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        title: json['title'] as String,
        url: json['url'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
