import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../admin/admin_dashboard_screen.dart';
import '../attendance/attendance_service.dart';
import '../bible/bible_api_service.dart';
import '../bible/bible_cache.dart';
import '../bible/bible_sync_service.dart';
import '../bible/screens/bible_reader_screen.dart';
import '../directory/directory_service.dart';
import '../events/event_service.dart';
import '../giving/giving_service.dart';
import '../giving/screens/giving_screen.dart';
import '../groups/group_service.dart';
import '../prayer/prayer_service.dart';
import '../reading_plans/reading_plan_service.dart';
import '../sermons/sermon_service.dart';
import 'community_tab.dart';
import 'grow_tab.dart';

/// The signed-in app shell: bottom-nav tabs gated by role. "Admin" only
/// shows for roles that can act on it. "Giving" is the real form/flow
/// (see GivingScreen) — the only thing not real yet is Paystack itself,
/// which the backend reports via a clean 503 until it's connected.
class AppShell extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;
  final AppProfile profile;

  const AppShell({
    super.key,
    required this.apiClient,
    required this.authService,
    required this.profile,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

// Owns every per-feature service (one instance each, created once and
// reused across tab switches) and which bottom-nav tab is selected.
class _AppShellState extends State<AppShell> {
  // Index into the `tabs` list built in build() below — which bottom-nav
  // destination is currently showing.
  int _selectedIndex = 0;
  late final DirectoryService _directoryService;
  late final AttendanceService _attendanceService;
  late final SermonService _sermonService;
  late final ReadingPlanService _readingPlanService;
  late final GroupService _groupService;
  late final PrayerService _prayerService;
  late final EventService _eventService;
  late final GivingService _givingService;
  late final BibleApiService _bibleApiService;
  late final BibleCache _bibleCache;
  late final BibleSyncService _bibleSyncService;

  @override
  void initState() {
    super.initState();
    _directoryService = DirectoryService(widget.apiClient);
    _attendanceService = AttendanceService(widget.apiClient);
    _sermonService = SermonService(widget.apiClient);
    _readingPlanService = ReadingPlanService(widget.apiClient);
    _groupService = GroupService(widget.apiClient);
    _prayerService = PrayerService(widget.apiClient);
    _eventService = EventService(widget.apiClient);
    _givingService = GivingService(widget.apiClient);
    _bibleApiService = BibleApiService();
    _bibleCache = BibleCache();
    _bibleSyncService = BibleSyncService();
  }

  @override
  void dispose() {
    _bibleApiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Admin tab is only added to the list below when the signed-in
    // profile's role allows it (see AppProfile.canAccessAdmin).
    final showAdminTab = widget.profile.canAccessAdmin;

    // The list of bottom-nav tabs and what each one builds. Built fresh
    // every call to build() so it always reflects the latest services/
    // profile, but the services themselves (above) are long-lived.
    final tabs = <_Tab>[
      _Tab(
        label: 'Home',
        icon: Icons.home_outlined,
        builder: (context) => _HomeTab(apiClient: widget.apiClient, profile: widget.profile),
      ),
      _Tab(
        label: 'Bible',
        icon: Icons.menu_book_outlined,
        builder: (context) => BibleReaderScreen(
          apiService: _bibleApiService,
          cache: _bibleCache,
          syncService: _bibleSyncService,
        ),
      ),
      _Tab(
        label: 'Grow',
        icon: Icons.church_outlined,
        builder: (context) => GrowTab(
          sermonService: _sermonService,
          readingPlanService: _readingPlanService,
          groupService: _groupService,
          directoryService: _directoryService,
          profile: widget.profile,
        ),
      ),
      _Tab(
        label: 'Community',
        icon: Icons.people_alt_outlined,
        builder: (context) => CommunityTab(
          prayerService: _prayerService,
          eventService: _eventService,
          profile: widget.profile,
        ),
      ),
      if (showAdminTab)
        _Tab(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          builder: (context) => AdminDashboardScreen(
            profile: widget.profile,
            directoryService: _directoryService,
            attendanceService: _attendanceService,
            sermonService: _sermonService,
          ),
        ),
      _Tab(
        label: 'Giving',
        icon: Icons.volunteer_activism_outlined,
        builder: (context) => GivingScreen(givingService: _givingService),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Church App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: widget.authService.signOut,
          ),
        ],
      ),
      body: tabs[_selectedIndex].builder(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

/// Describes one bottom-nav destination: its label, icon, and the widget
/// builder used to build its body when selected.
class _Tab {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;

  const _Tab({required this.label, required this.icon, required this.builder});
}

/// The "Home" tab's content: a welcome message plus a manual backend
/// health-check button. Mostly a developer/debug convenience.
class _HomeTab extends StatefulWidget {
  final ApiClient apiClient;
  final AppProfile profile;

  const _HomeTab({required this.apiClient, required this.profile});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

// Tracks the text describing the outcome of the last backend health check.
class _HomeTabState extends State<_HomeTab> {
  String _status = 'Not checked yet';

  // Calls the backend's health endpoint and shows the result (or error)
  // as status text.
  Future<void> _checkBackend() async {
    setState(() => _status = 'Checking...');
    try {
      final result = await widget.apiClient.health();
      setState(() => _status = 'Backend says: ${result['status']} (${result['environment']})');
    } catch (e) {
      setState(() => _status = 'Could not reach backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome, ${widget.profile.fullName}', style: Theme.of(context).textTheme.titleLarge),
            Text(widget.profile.role.name, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _checkBackend, child: const Text('Check backend health')),
          ],
        ),
      ),
    );
  }
}
