import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../directory/directory_service.dart';
import '../groups/group_service.dart';
import '../groups/screens/group_list_screen.dart';
import '../reading_plans/reading_plan_service.dart';
import '../reading_plans/screens/reading_plan_list_screen.dart';
import '../sermons/screens/sermon_list_screen.dart';
import '../sermons/sermon_service.dart';

/// A menu tab rather than three separate bottom-nav destinations — keeps
/// the nav bar from growing every phase. Sermons, reading plans, and
/// small groups all live here since they're all "grow in faith" content,
/// distinct from the Bible reader (its own tab, used far more often) and
/// from Community (Phase 4: prayer, events).
class GrowTab extends StatelessWidget {
  final SermonService sermonService;
  final ReadingPlanService readingPlanService;
  final GroupService groupService;
  final DirectoryService directoryService;
  final AppProfile? profile;

  const GrowTab({
    super.key,
    required this.sermonService,
    required this.readingPlanService,
    required this.groupService,
    required this.directoryService,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grow')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.church_outlined),
            title: const Text('Sermons'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SermonListScreen(sermonService: sermonService, profile: profile),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.checklist_outlined),
            title: const Text('Reading Plans'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReadingPlanListScreen(planService: readingPlanService, profile: profile),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Small Groups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupListScreen(
                  groupService: groupService,
                  directoryService: directoryService,
                  profile: profile,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
