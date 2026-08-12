import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import 'models.dart';

class EventService {
  final ApiClient _client;
  const EventService(this._client);

  Future<List<ChurchEvent>> listEvents() async {
    final json = await _client.get('/api/v1/events');
    return (json as List).map((e) => ChurchEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

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

  Future<ChurchEvent> setRsvp({required String eventId, required RsvpStatus status}) async {
    final json = await _client.put(
      '/api/v1/events/$eventId/rsvp',
      body: {'status': status.apiValue},
    );
    return ChurchEvent.fromJson(json as Map<String, dynamic>);
  }

  Future<ChurchEvent> clearRsvp(String eventId) async {
    final json = await _client.delete('/api/v1/events/$eventId/rsvp');
    return ChurchEvent.fromJson(json as Map<String, dynamic>);
  }
}
