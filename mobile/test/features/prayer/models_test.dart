import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/prayer/models.dart';

void main() {
  test('PrayerRequest.fromJson parses visibility and counts', () {
    final request = PrayerRequest.fromJson({
      'id': '1',
      'profile_id': 'p1',
      'content': 'Please pray for healing',
      'visibility': 'leaders',
      'created_at': '2026-01-01T00:00:00Z',
      'praying_count': 3,
      'is_praying': true,
    });

    expect(request.visibility, PrayerVisibility.leaders);
    expect(request.prayingCount, 3);
    expect(request.isPraying, isTrue);
  });

  test('prayerVisibilityFromString defaults to public for unknown values', () {
    expect(prayerVisibilityFromString('private'), PrayerVisibility.private);
    expect(prayerVisibilityFromString('nonsense'), PrayerVisibility.public);
  });
}
