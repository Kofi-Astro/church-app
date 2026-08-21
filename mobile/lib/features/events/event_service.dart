// Talks to the backend's /api/v1/events endpoints: listing church events
// and RSVPing to them. No local caching — every call hits the network.
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import 'models.dart';

/// API wrapper for church events: fetching the event list and setting/
/// clearing the current user's RSVP on an event.
class EventService {
  final ApiClient _client;
  const EventService(this._client);

  /// Fetches all events visible to the current user, most/least recent
  /// order determined by the backend.
  Future<List<ChurchEvent>> listEvents() async {
    final json = await _client.get('/api/v1/events');
    return (json as List).map((e) => ChurchEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Creates a new event (admin-only on the backend). `eventDate` is sent
  /// as a naive local timestamp string (no timezone) — see the DateFormat
  /// pattern below.
  Future<ChurchEvent> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    String? location,
  }) async {
    final json = await _client.post(
      '/api/v1/events',
      body: {
        'title': title,
        'event_date': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(eventDate),
        if (description != null && description.isNotEmpty) 'description': description,
        if (location != null && location.isNotEmpty) 'location': location,
      },
    );
    return ChurchEvent.fromJson(json as Map<String, dynamic>);
  }

  /// Sets (or changes) the current user's RSVP status for an event and
  /// returns the updated event, including refreshed RSVP counts.
  Future<ChurchEvent> setRsvp({required String eventId, required RsvpStatus status}) async {
    final json = await _client.put(
      '/api/v1/events/$eventId/rsvp',
      body: {'status': status.apiValue},
    );
    return ChurchEvent.fromJson(json as Map<String, dynamic>);
  }

  /// Removes the current user's RSVP entirely (back to "no response").
  Future<ChurchEvent> clearRsvp(String eventId) async {
    final json = await _client.delete('/api/v1/events/$eventId/rsvp');
    return ChurchEvent.fromJson(json as Map<String, dynamic>);
  }
}
