import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/reading_plans/models.dart';

void main() {
  test('ReadingPlan.fromJson parses plan_type correctly', () {
    final plan = ReadingPlan.fromJson({
      'id': '1',
      'title': 'Romans in 30 Days',
      'description': null,
      'plan_type': 'annual',
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(plan.planType, PlanType.annual);
    expect(plan.title, 'Romans in 30 Days');
  });

  test('planTypeFromString falls back to topical for unknown values', () {
    expect(planTypeFromString('topical'), PlanType.topical);
    expect(planTypeFromString('something-else'), PlanType.topical);
  });

  test('ReadingPlanDay.fromJson parses fields', () {
    final day = ReadingPlanDay.fromJson({
      'id': '1',
      'plan_id': 'p1',
      'day_number': 3,
      'reference': 'Romans 3',
      'title': null,
    });

    expect(day.dayNumber, 3);
    expect(day.reference, 'Romans 3');
  });
}
