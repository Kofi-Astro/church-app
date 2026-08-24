// Data model for congregations — the church's distinct standing service
// tracks (English, Akan, Youth Chapel, ...), matching /api/v1/congregations.

/// One of the church's congregations/service tracks. Members and
/// [ChurchService]s (see features/attendance/models.dart) can each be
/// linked to one of these.
class Congregation {
  final String id;
  final String name;
  /// Optional longer description; null if none was set.
  final String? description;
  final DateTime createdAt;

  const Congregation({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  /// Builds a [Congregation] from the JSON object the backend returns.
  factory Congregation.fromJson(Map<String, dynamic> json) => Congregation(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
