enum RsvpStatus { going, maybe, notGoing }

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

extension RsvpStatusLabel on RsvpStatus {
  String get label => switch (this) {
        RsvpStatus.going => 'Going',
        RsvpStatus.maybe => 'Maybe',
        RsvpStatus.notGoing => 'Not going',
      };

  String get apiValue => switch (this) {
        RsvpStatus.going => 'going',
        RsvpStatus.maybe => 'maybe',
        RsvpStatus.notGoing => 'not_going',
      };
}

class ChurchEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? location;
  final Map<String, int> rsvpCounts;
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
