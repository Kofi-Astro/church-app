// Main Events screen: lists upcoming church events, lets members RSVP,
// and (for admins) links to the create-event form.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../event_service.dart';
import '../models.dart';
import 'event_form_screen.dart';

/// Lists all events the current user can see, with inline RSVP controls.
/// Shows a "New event" FAB only when [profile] is an admin.
class EventListScreen extends StatefulWidget {
  final EventService eventService;
  final AppProfile? profile;

  const EventListScreen({super.key, required this.eventService, required this.profile});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

// Holds the fetched event list plus loading/error state for the initial
// load and pull-to-refresh.
class _EventListScreenState extends State<EventListScreen> {
  List<ChurchEvent> _events = [];
  bool _loading = true;
  // Error message from the last failed load, or null if the last load
  // succeeded (or hasn't finished yet).
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fetches the event list from the backend; used both on first load and
  // on pull-to-refresh.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await widget.eventService.listEvents();
      setState(() {
        _events = events;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Sets the RSVP for `event` to `status`, or clears it if the user tapped
  // the same status they already had selected (toggle behavior).
  Future<void> _rsvp(ChurchEvent event, RsvpStatus status) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    try {
      final updated = event.myRsvp == status
          ? await widget.eventService.clearRsvp(event.id)
          : await widget.eventService.setRsvp(eventId: event.id, status: status);
      setState(() => _events[index] = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not RSVP: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.profile?.role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      // Only admins get the "create event" FAB.
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventFormScreen(eventService: widget.eventService),
                  ),
                );
                // EventFormScreen pops with `true` when it successfully
                // created an event, so reload the list to show it.
                if (created == true) _load();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _events.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No upcoming events.', textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    // One card per event, with title/date/location/
                    // description and RSVP choice chips.
                    : ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final going = event.rsvpCounts['going'] ?? 0;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                                  Text(DateFormat.yMMMEd().add_jm().format(event.eventDate)),
                                  if (event.location != null) Text(event.location!),
                                  if (event.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(event.description!),
                                  ],
                                  const SizedBox(height: 8),
                                  Text('$going going'),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      for (final status in RsvpStatus.values)
                                        ChoiceChip(
                                          label: Text(status.label),
                                          selected: event.myRsvp == status,
                                          onSelected: (_) => _rsvp(event, status),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
