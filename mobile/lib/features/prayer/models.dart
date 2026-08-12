enum PrayerVisibility { public, leaders, private }

PrayerVisibility prayerVisibilityFromString(String value) {
  switch (value) {
    case 'leaders':
      return PrayerVisibility.leaders;
    case 'private':
      return PrayerVisibility.private;
    default:
      return PrayerVisibility.public;
  }
}

extension PrayerVisibilityLabel on PrayerVisibility {
  String get label => switch (this) {
        PrayerVisibility.public => 'Public',
        PrayerVisibility.leaders => 'Leaders only',
        PrayerVisibility.private => 'Private',
      };

  String get apiValue => switch (this) {
        PrayerVisibility.public => 'public',
        PrayerVisibility.leaders => 'leaders',
        PrayerVisibility.private => 'private',
      };
}

class PrayerRequest {
  final String id;
  final String profileId;
  final String content;
  final PrayerVisibility visibility;
  final DateTime createdAt;
  final int prayingCount;
  final bool isPraying;

  const PrayerRequest({
    required this.id,
    required this.profileId,
    required this.content,
    required this.visibility,
    required this.createdAt,
    required this.prayingCount,
    required this.isPraying,
  });

  factory PrayerRequest.fromJson(Map<String, dynamic> json) => PrayerRequest(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        content: json['content'] as String,
        visibility: prayerVisibilityFromString(json['visibility'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        prayingCount: json['praying_count'] as int,
        isPraying: json['is_praying'] as bool,
      );
}
