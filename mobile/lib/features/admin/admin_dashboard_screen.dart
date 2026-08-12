import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../attendance/attendance_service.dart';
import '../attendance/screens/attendance_report_screen.dart';
import '../attendance/screens/service_list_screen.dart';
import '../directory/directory_service.dart';
import '../directory/screens/household_list_screen.dart';
import '../directory/screens/member_search_screen.dart';
import '../sermons/screens/livestream_settings_screen.dart';
import '../sermons/sermon_service.dart';

/// Combines directory and attendance into one admin view with role-gated
/// sections, per the Phase 1 roadmap. Each section links out to the
/// existing full-screen flows rather than re-implementing them — this
/// screen is a menu, not a new data view.
class AdminDashboardScreen extends StatelessWidget {
  final AppProfile profile;
  final DirectoryService directoryService;
  final AttendanceService attendanceService;
  final SermonService sermonService;

  const AdminDashboardScreen({
    super.key,
    required this.profile,
    required this.directoryService,
    required this.attendanceService,
    required this.sermonService,
  });

  @override
  Widget build(BuildContext context) {
    final isAdminOrLeader = profile.role == AppRole.admin || profile.role == AppRole.groupLeader;
    final canSeeReports = profile.canAccessAdmin;
    // Finance data stays behind a hard wall until Phase 5 — see
    // docs/threat-model.md on why finance_admin is scoped this narrowly.
    final canSeeGivingPreview = profile.role == AppRole.admin || profile.role == AppRole.financeAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (isAdminOrLeader) ...[
            const _SectionHeader('Directory'),
            ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: const Text('Households'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HouseholdListScreen(directoryService: directoryService, profile: profile),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Members'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MemberSearchScreen(directoryService: directoryService, profile: profile),
                ),
              ),
            ),
            const _SectionHeader('Attendance'),
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Services & check-in'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceListScreen(
                    attendanceService: attendanceService,
                    directoryService: directoryService,
                    profile: profile,
                  ),
                ),
              ),
            ),
          ],
          if (canSeeReports)
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Attendance report'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AttendanceReportScreen(attendanceService: attendanceService),
                ),
              ),
            ),
          if (profile.role == AppRole.admin) ...[
            const _SectionHeader('Content'),
            ListTile(
              leading: const Icon(Icons.live_tv_outlined),
              title: const Text('Livestream URL'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LivestreamSettingsScreen(sermonService: sermonService),
                ),
              ),
            ),
          ],
          if (canSeeGivingPreview) ...[
            const _SectionHeader('Giving'),
            const ListTile(
              leading: Icon(Icons.volunteer_activism_outlined),
              title: Text('Giving & transactions'),
              subtitle: Text('Coming in Phase 5 — Paystack integration'),
              enabled: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
