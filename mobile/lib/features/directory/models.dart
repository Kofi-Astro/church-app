// Data models for the directory feature (households + members), matching
// the shapes returned by /api/v1/households and /api/v1/members.

/// A family/home unit that members can belong to (e.g. "The Smith Family").
class Household {
  final String id;
  final String name;
  /// Optional home address — may be null if not recorded.
  final String? address;
  final DateTime createdAt;

  const Household({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
  });

  /// Builds a [Household] from the raw JSON map returned by the API.
  factory Household.fromJson(Map<String, dynamic> json) => Household(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// A single congregation member/person in the directory.
class Member {
  final String id;
  /// Links to this member's Supabase auth profile, if they have an app
  /// login — null for members who are tracked in the directory but don't
  /// (yet) have their own account.
  final String? profileId;
  /// Household this member belongs to, if any.
  final String? householdId;
  final String fullName;
  final String? email;
  final String? phone;
  final DateTime createdAt;

  const Member({
    required this.id,
    required this.profileId,
    required this.householdId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  /// Builds a [Member] from the raw JSON map returned by the API.
  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        profileId: json['profile_id'] as String?,
        householdId: json['household_id'] as String?,
        fullName: json['full_name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
