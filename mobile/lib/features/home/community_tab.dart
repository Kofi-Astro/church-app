import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../events/event_service.dart';
import '../events/screens/event_list_screen.dart';
import '../prayer/prayer_service.dart';
import '../prayer/screens/prayer_feed_screen.dart';

/// Prayer requests and events under one tab, same "menu, not a nav item
/// per feature" approach as GrowTab.
class CommunityTab extends StatelessWidget {
  final PrayerService prayerService;
  final EventService eventService;
  final AppProfile? profile;

  const CommunityTab({
    super.key,
    required this.prayerService,
    required this.eventService,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Prayer Requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PrayerFeedScreen(prayerService: prayerService, profile: profile),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: const Text('Events'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventListScreen(eventService: eventService, profile: profile),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
