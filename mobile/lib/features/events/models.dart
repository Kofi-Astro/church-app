// Data models for the Events feature: an event, and a user's RSVP status
// to it. Mirrors the shape returned by /api/v1/events on the backend.

/// A member's RSVP response to an event. `notGoing` maps to the API's
/// 'not_going' (snake_case); a null [RsvpStatus] (see [myRsvp]) means the
/// user hasn't responded at all yet.
enum RsvpStatus { going, maybe, notGoing }

/// Parses the backend's RSVP status string into an [RsvpStatus].
/// Returns null for null/unrecognized input, meaning "no RSVP yet"
/// rather than defaulting to some status.
RsvpStatus? rsvpStatusFromString(String? value) {
  switch (value) {
    case 'going':
      return RsvpStatus.going;
    case 'maybe':
      return RsvpStatus.maybe;
    case 'not_going':
      return RsvpStatus.notGoing;
    default:
      return null;
  }
}

/// Human-readable label and API wire-value for each [RsvpStatus].
extension RsvpStatusLabel on RsvpStatus {
  /// Text shown in the UI (e.g. on RSVP chips).
  String get label => switch (this) {
        RsvpStatus.going => 'Going',
        RsvpStatus.maybe => 'Maybe',
        RsvpStatus.notGoing => 'Not going',
      };

  /// snake_case value the backend expects in request bodies.
  String get apiValue => switch (this) {
        RsvpStatus.going => 'going',
        RsvpStatus.maybe => 'maybe',
        RsvpStatus.notGoing => 'not_going',
      };
}

/// A single church event (e.g. a service, retreat, or meeting) along with
/// aggregate RSVP counts and the current user's own RSVP, if any.
class ChurchEvent {
  final String id;
  final String title;
  /// Optional longer description of the event; null if none was set.
  final String? description;
  final DateTime eventDate;
  /// Optional location text (e.g. room or address); null if none was set.
  final String? location;
  /// Counts of RSVPs by status string (e.g. {'going': 12, 'maybe': 3}),
  /// as returned by the backend.
  final Map<String, int> rsvpCounts;
  /// The current user's own RSVP for this event, or null if they haven't
  /// responded.
  final RsvpStatus? myRsvp;

  const ChurchEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.rsvpCounts,
    required this.myRsvp,
  });

  /// Builds a [ChurchEvent] from the JSON object the backend returns.
  factory ChurchEvent.fromJson(Map<String, dynamic> json) => ChurchEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        eventDate: DateTime.parse(json['event_date'] as String),
        location: json['location'] as String?,
        rsvpCounts: Map<String, int>.from(json['rsvp_counts'] as Map),
        myRsvp: rsvpStatusFromString(json['my_rsvp'] as String?),
      );
}
