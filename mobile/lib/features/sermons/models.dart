class Sermon {
  final String id;
  final String title;
  final String? speaker;
  final String? series;
  final DateTime sermonDate;
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

class ChurchSettings {
  final String? livestreamUrl;

  const ChurchSettings({required this.livestreamUrl});

  factory ChurchSettings.fromJson(Map<String, dynamic> json) =>
      ChurchSettings(livestreamUrl: json['livestream_url'] as String?);
}
