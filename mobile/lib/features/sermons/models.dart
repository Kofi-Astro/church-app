// Data models for the sermons feature, matching the shapes returned by
// /api/v1/sermons and /api/v1/church-settings.

/// A single recorded/streamed sermon entry (title, speaker, video link,
/// etc.) shown in the Sermons tab.
class Sermon {
  final String id;
  final String title;
  final String? speaker;
  final String? series;
  final DateTime sermonDate;
  /// Link to the video (YouTube/Vimeo/etc.), if one has been added — null
  /// means no video is attached yet.
  final String? videoUrl;
  final String? description;
  final DateTime createdAt;

  const Sermon({
    required this.id,
    required this.title,
    required this.speaker,
    required this.series,
    required this.sermonDate,
    required this.videoUrl,
    required this.description,
    required this.createdAt,
  });

  /// Builds a [Sermon] from the raw JSON map returned by the API.
  factory Sermon.fromJson(Map<String, dynamic> json) => Sermon(
        id: json['id'] as String,
        title: json['title'] as String,
        speaker: json['speaker'] as String?,
        series: json['series'] as String?,
        sermonDate: DateTime.parse(json['sermon_date'] as String),
        videoUrl: json['video_url'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Church-wide settings relevant to the Sermons tab — currently just the
/// livestream URL shown as a "Watch live" banner when set.
class ChurchSettings {
  /// URL of the current/next live stream, or null if there isn't one (in
  /// which case the "Watch live" banner is hidden).
  final String? livestreamUrl;

  const ChurchSettings({required this.livestreamUrl});

  /// Builds a [ChurchSettings] from the raw JSON map returned by the API.
  factory ChurchSettings.fromJson(Map<String, dynamic> json) =>
      ChurchSettings(livestreamUrl: json['livestream_url'] as String?);
}
