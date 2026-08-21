// Data models for the Reading Plans feature: a plan itself and its
// individual days. Per-user completion state is NOT here — see
// ReadingPlanProgressService for that (it comes from Supabase directly,
// separate from these FastAPI-backed models).

/// Whether a plan runs across the whole year (`annual`, e.g. a
/// read-the-Bible-in-a-year plan) or is a shorter themed plan (`topical`).
enum PlanType { annual, topical }

/// Parses the backend's plan-type string; anything other than 'annual'
/// is treated as [PlanType.topical].
PlanType planTypeFromString(String value) => value == 'annual' ? PlanType.annual : PlanType.topical;

/// A reading plan (e.g. "Bible in a Year"), made up of individual
/// [ReadingPlanDay]s.
class ReadingPlan {
  final String id;
  final String title;
  /// Optional description of the plan; null if none was set.
  final String? description;
  final PlanType planType;
  final DateTime createdAt;

  const ReadingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.planType,
    required this.createdAt,
  });

  /// Builds a [ReadingPlan] from the JSON object the backend returns.
  factory ReadingPlan.fromJson(Map<String, dynamic> json) => ReadingPlan(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        planType: planTypeFromString(json['plan_type'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// One day's reading assignment within a plan (e.g. day 3: "Genesis 4-6").
class ReadingPlanDay {
  final String id;
  final String planId;
  final int dayNumber;
  /// The Scripture reference to read (e.g. "Genesis 4-6").
  final String reference;
  /// Optional short title/theme for the day; null if none was set.
  final String? title;

  const ReadingPlanDay({
    required this.id,
    required this.planId,
    required this.dayNumber,
    required this.reference,
    required this.title,
  });

  /// Builds a [ReadingPlanDay] from the JSON object the backend returns.
  factory ReadingPlanDay.fromJson(Map<String, dynamic> json) => ReadingPlanDay(
        id: json['id'] as String,
        planId: json['plan_id'] as String,
        dayNumber: json['day_number'] as int,
        reference: json['reference'] as String,
        title: json['title'] as String?,
      );
}
