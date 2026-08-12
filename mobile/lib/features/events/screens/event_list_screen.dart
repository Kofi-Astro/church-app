import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../event_service.dart';
import '../models.dart';
import 'event_form_screen.dart';

class EventListScreen extends StatefulWidget {
  final EventService eventService;
  final AppProfile? profile;

  const EventListScreen({super.key, required this.eventService, required this.profile});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<ChurchEvent> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventFormScreen(eventService: widget.eventService),
                  ),
                );
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
