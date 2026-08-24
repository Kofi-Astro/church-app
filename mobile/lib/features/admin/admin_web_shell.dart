import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../attendance/attendance_service.dart';
import '../attendance/screens/attendance_report_screen.dart';
import '../attendance/screens/service_list_screen.dart';
import '../congregations/congregation_service.dart';
import '../congregations/screens/congregation_list_screen.dart';
import '../directory/directory_service.dart';
import '../directory/screens/household_list_screen.dart';
import '../directory/screens/member_search_screen.dart';
import '../giving/giving_service.dart';
import '../giving/screens/giving_report_screen.dart';
import '../groups/group_service.dart';
import '../groups/screens/group_list_screen.dart';
import '../sermons/screens/livestream_settings_screen.dart';
import '../sermons/screens/sermon_list_screen.dart';
import '../sermons/sermon_service.dart';

/// Desktop-oriented admin dashboard shown when the app runs on the web
/// platform (see lib/main.dart, which picks this over [AppShell] there).
/// Deliberately a different *shell* around the same features the mobile
/// admin menu already has — a persistent side rail instead of a pushed
/// menu screen — not a second implementation of them. Every destination
/// below is the exact same screen/service class the phone app uses.
class AdminWebShell extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;
  final AppProfile profile;

  const AdminWebShell({
    super.key,
    required this.apiClient,
    required this.authService,
    required this.profile,
  });

  @override
  State<AdminWebShell> createState() => _AdminWebShellState();
}

// Owns the per-feature services (built once, same as AppShell does for
// the phone app) and which side-rail destination is selected.
class _AdminWebShellState extends State<AdminWebShell> {
  int _selectedIndex = 0;
  late final DirectoryService _directoryService;
  late final AttendanceService _attendanceService;
  late final SermonService _sermonService;
  late final GroupService _groupService;
  late final CongregationService _congregationService;
  late final GivingService _givingService;

  @override
  void initState() {
    super.initState();
    _directoryService = DirectoryService(widget.apiClient);
    _attendanceService = AttendanceService(widget.apiClient);
    _sermonService = SermonService(widget.apiClient);
    _groupService = GroupService(widget.apiClient);
    _congregationService = CongregationService(widget.apiClient);
    _givingService = GivingService(widget.apiClient);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isAdminOrLeader = profile.role == AppRole.admin || profile.role == AppRole.groupLeader;
    final isAdmin = profile.role == AppRole.admin;
    final canSeeGiving = profile.role == AppRole.admin || profile.role == AppRole.financeAdmin;

    // Same destination list an admin/leader sees on the mobile admin menu
    // (see admin_dashboard_screen.dart), just rendered as rail entries
    // instead of a scrolling ListView.
    final destinations = <_WebDestination>[
      if (isAdminOrLeader) ...[
        _WebDestination(
          'Households',
          Icons.home_work_outlined,
          (context) => HouseholdListScreen(directoryService: _directoryService, profile: profile),
        ),
        _WebDestination(
          'Members',
          Icons.people_outline,
          (context) => MemberSearchScreen(
            directoryService: _directoryService,
            congregationService: _congregationService,
            profile: profile,
          ),
        ),
        _WebDestination(
          'Congregations',
          Icons.church_outlined,
          (context) =>
              CongregationListScreen(congregationService: _congregationService, profile: profile),
        ),
        _WebDestination(
          'Services & Check-in',
          Icons.event_available_outlined,
          (context) => ServiceListScreen(
            attendanceService: _attendanceService,
            directoryService: _directoryService,
            congregationService: _congregationService,
            profile: profile,
          ),
        ),
      ],
      _WebDestination(
        'Attendance Report',
        Icons.bar_chart_outlined,
        (context) => AttendanceReportScreen(attendanceService: _attendanceService),
      ),
      _WebDestination(
        'Groups & Auxiliaries',
        Icons.groups_outlined,
        (context) => GroupListScreen(
          groupService: _groupService,
          directoryService: _directoryService,
          profile: profile,
        ),
      ),
      if (isAdmin) ...[
        _WebDestination(
          'Sermons',
          Icons.play_circle_outline,
          (context) => SermonListScreen(sermonService: _sermonService, profile: profile),
        ),
        _WebDestination(
          'Livestream',
          Icons.live_tv_outlined,
          (context) => LivestreamSettingsScreen(sermonService: _sermonService),
        ),
      ],
      if (canSeeGiving)
        _WebDestination(
          'Giving Report',
          Icons.volunteer_activism_outlined,
          (context) => GivingReportScreen(givingService: _givingService),
        ),
    ];

    // Defends against the selected index becoming stale if the
    // destination list shrinks (e.g. role somehow changes mid-session).
    final safeIndex = _selectedIndex.clamp(0, destinations.length - 1);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            // Wide enough windows show text labels alongside icons.
            extended: MediaQuery.of(context).size.width > 900,
            selectedIndex: safeIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.church, size: 32),
                  const SizedBox(height: 12),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign out',
                    onPressed: widget.authService.signOut,
                  ),
                ],
              ),
            ),
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: destinations[safeIndex].builder(context)),
        ],
      ),
    );
  }
}

/// One side-rail destination: its label, icon, and the widget builder
/// used to build its content pane when selected.
class _WebDestination {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _WebDestination(this.label, this.icon, this.builder);
}
