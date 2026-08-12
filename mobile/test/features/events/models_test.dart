import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/events/models.dart';

void main() {
  test('ChurchEvent.fromJson parses rsvp_counts and a null my_rsvp', () {
    final event = ChurchEvent.fromJson({
      'id': '1',
      'title': 'Youth Camp',
      'description': null,
      'event_date': '2026-09-01T09:00:00Z',
      'location': null,
      'rsvp_counts': {'going': 2, 'maybe': 1, 'not_going': 0},
      'my_rsvp': null,
    });

    expect(event.rsvpCounts['going'], 2);
    expect(event.myRsvp, isNull);
  });

  test('rsvpStatusFromString round-trips apiValue', () {
    for (final status in RsvpStatus.values) {
      expect(rsvpStatusFromString(status.apiValue), status);
    }
  });
}
