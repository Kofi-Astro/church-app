class Household {
  final String id;
  final String name;
  final String? address;
  final DateTime createdAt;

  const Household({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) => Household(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Member {
  final String id;
  final String? profileId;
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
