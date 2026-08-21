// Data model for the Prayer Requests feature: a prayer request and who
// is allowed to see it.

/// Who can see a prayer request: everyone in the church (`public`), just
/// group/church leaders (`leaders`), or only the author and admins
/// (`private`).
enum PrayerVisibility { public, leaders, private }

/// Parses the backend's visibility string into a [PrayerVisibility];
/// falls back to [PrayerVisibility.public] for unrecognized/missing
/// values.
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
  /// Text shown in the visibility dropdown and on request cards.
  String get label => switch (this) {
        PrayerVisibility.public => 'Public',
        PrayerVisibility.leaders => 'Leaders only',
        PrayerVisibility.private => 'Private',
      };

  /// Wire value sent to the backend in request bodies.
  String get apiValue => switch (this) {
        PrayerVisibility.public => 'public',
        PrayerVisibility.leaders => 'leaders',
        PrayerVisibility.private => 'private',
      };
}

/// A single prayer request posted by a member, with the aggregate count
/// of people praying for it and whether the current user is one of them.
class PrayerRequest {
  final String id;
  /// Id of the profile who posted this request.
  final String profileId;
  final String content;
  final PrayerVisibility visibility;
  final DateTime createdAt;
  /// How many people have marked themselves as praying for this request.
  final int prayingCount;
  /// Whether the current user has marked themselves as praying for this
  /// request (controls the filled/outline heart icon in the UI).
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

  /// Builds a [PrayerRequest] from the JSON object the backend returns.
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
