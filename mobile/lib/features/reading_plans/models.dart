enum PlanType { annual, topical }

PlanType planTypeFromString(String value) => value == 'annual' ? PlanType.annual : PlanType.topical;

class ReadingPlan {
  final String id;
  final String title;
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

  factory ReadingPlan.fromJson(Map<String, dynamic> json) => ReadingPlan(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        planType: planTypeFromString(json['plan_type'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ReadingPlanDay {
  final String id;
  final String planId;
  final int dayNumber;
  final String reference;
  final String? title;

  const ReadingPlanDay({
    required this.id,
    required this.planId,
    required this.dayNumber,
    required this.reference,
    required this.title,
  });

  factory ReadingPlanDay.fromJson(Map<String, dynamic> json) => ReadingPlanDay(
        id: json['id'] as String,
        planId: json['plan_id'] as String,
        dayNumber: json['day_number'] as int,
        reference: json['reference'] as String,
        title: json['title'] as String?,
      );
}
