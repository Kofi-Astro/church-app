import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
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
  final CongregationService congregationService;
  final GivingService givingService;

  const AdminDashboardScreen({
    super.key,
    required this.profile,
    required this.directoryService,
    required this.attendanceService,
    required this.sermonService,
    required this.congregationService,
    required this.givingService,
  });

  @override
  Widget build(BuildContext context) {
    // Role checks gating each section below.
    final isAdminOrLeader = profile.role == AppRole.admin || profile.role == AppRole.groupLeader;
    final canSeeReports = profile.canAccessAdmin;
    // Cross-member giving data stays behind a hard wall — see
    // docs/threat-model.md on why finance_admin is scoped this narrowly.
    final canSeeGivingReport = profile.role == AppRole.admin || profile.role == AppRole.financeAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Directory + attendance section — admins and group leaders.
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
                  builder: (context) => MemberSearchScreen(
                    directoryService: directoryService,
                    congregationService: congregationService,
                    profile: profile,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.church_outlined),
              title: const Text('Congregations'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CongregationListScreen(
                    congregationService: congregationService,
                    profile: profile,
                  ),
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
                    congregationService: congregationService,
                    profile: profile,
                  ),
                ),
              ),
            ),
          ],
          // Attendance report — anyone with admin access (admin,
          // finance_admin, or group leader).
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
          // Content management — admin only.
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
          // Giving report — every member's transactions, not just the
          // signed-in admin's own (that's GivingScreen, on the Giving tab).
          // admin/finance_admin only.
          if (canSeeGivingReport) ...[
            const _SectionHeader('Giving'),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: const Text('Giving report'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GivingReportScreen(givingService: givingService),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small uppercase label used to separate sections in the admin menu list
/// (e.g. "DIRECTORY", "ATTENDANCE").
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
