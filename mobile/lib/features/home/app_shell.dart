import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../admin/admin_dashboard_screen.dart';
import '../attendance/attendance_service.dart';
import '../directory/directory_service.dart';

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

  @override
  void initState() {
    super.initState();
    _directoryService = DirectoryService(widget.apiClient);
    _attendanceService = AttendanceService(widget.apiClient);
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
      if (showAdminTab)
        _Tab(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          builder: (context) => AdminDashboardScreen(
            profile: widget.profile,
            directoryService: _directoryService,
            attendanceService: _attendanceService,
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
