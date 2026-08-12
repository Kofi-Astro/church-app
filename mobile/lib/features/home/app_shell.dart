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
import '../groups/group_service.dart';
import '../prayer/prayer_service.dart';
import '../reading_plans/reading_plan_service.dart';
import '../sermons/sermon_service.dart';
import 'community_tab.dart';
import 'grow_tab.dart';

/// The signed-in app shell: bottom-nav tabs gated by role. "Admin" only
/// shows for roles that can act on it; "Giving" is visible to everyone
/// but disabled — see roadmap Phase 1 Week 5 ("visually-present but
/// disabled Giving tab" — demoes the full information architecture
/// without wiring real payments, which is deliberately deferred to
/// Phase 5).
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

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late final DirectoryService _directoryService;
  late final AttendanceService _attendanceService;
  late final SermonService _sermonService;
  late final ReadingPlanService _readingPlanService;
  late final GroupService _groupService;
  late final PrayerService _prayerService;
  late final EventService _eventService;
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
    final showAdminTab = widget.profile.canAccessAdmin;

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
        builder: (context) => const _GivingComingSoonTab(),
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

class _Tab {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;

  const _Tab({required this.label, required this.icon, required this.builder});
}

class _HomeTab extends StatefulWidget {
  final ApiClient apiClient;
  final AppProfile profile;

  const _HomeTab({required this.apiClient, required this.profile});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _status = 'Not checked yet';

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

class _GivingComingSoonTab extends StatelessWidget {
  const _GivingComingSoonTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Giving is coming soon', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Online giving launches once the church\'s Paystack account is '
              'verified (Phase 5). Everything else in the app is ready today.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
