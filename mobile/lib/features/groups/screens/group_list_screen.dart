// Top-level Small Groups screen: lists all groups and (for admins) lets
// you create a new one.
import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../directory/directory_service.dart';
import '../../directory/screens/member_picker_screen.dart';
import '../group_service.dart';
import '../models.dart';
import 'group_detail_screen.dart';

/// Lists all small groups the current user can see; tapping one opens
/// [GroupDetailScreen]. Shows a "New group" FAB only for admins.
class GroupListScreen extends StatefulWidget {
  final GroupService groupService;
  final DirectoryService directoryService;
  final AppProfile? profile;

  const GroupListScreen({
    super.key,
    required this.groupService,
    required this.directoryService,
    required this.profile,
  });

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

// Holds the fetched group list plus loading/error state.
class _GroupListScreenState extends State<GroupListScreen> {
  List<SmallGroup> _groups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fetches the group list; used on first load and pull-to-refresh.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final groups = await widget.groupService.listGroups();
      setState(() {
        _groups = groups;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Shows a dialog to enter a new group's name/description/category and
  // optionally pick a leader (via MemberPickerScreen), then creates it if
  // confirmed.
  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? leaderId;
    String? leaderName;
    GroupCategory category = GroupCategory.smallGroup;

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Group name'),
                autofocus: true,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              DropdownButtonFormField<GroupCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final option in GroupCategory.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => category = value);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(leaderName ?? 'No leader assigned'),
                trailing: const Icon(Icons.person_search_outlined),
                onTap: () async {
                  final picked = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MemberPickerScreen(directoryService: widget.directoryService),
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      leaderId = picked.profileId;
                      leaderName = picked.fullName;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (create != true || nameController.text.trim().isEmpty) return;

    try {
      await widget.groupService.createGroup(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        leaderId: leaderId,
        category: category,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create group: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.profile?.role == AppRole.admin;
    // Split into two sections so auxiliaries (Men's Auxiliary, Royal
    // Ambassadors, ...) read as distinct from ordinary small/Bible-study
    // groups, even though both are the same SmallGroup under the hood.
    final auxiliaries = _groups.where((g) => g.category == GroupCategory.auxiliary).toList();
    final smallGroups = _groups.where((g) => g.category == GroupCategory.smallGroup).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: _showCreateGroupDialog, child: const Icon(Icons.add))
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _groups.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No groups yet.', textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          if (smallGroups.isNotEmpty) ...[
                            const _GroupSectionHeader('Small Groups'),
                            for (final group in smallGroups) _GroupTile(group: group, widget: widget),
                          ],
                          if (auxiliaries.isNotEmpty) ...[
                            const _GroupSectionHeader('Auxiliaries'),
                            for (final group in auxiliaries) _GroupTile(group: group, widget: widget),
                          ],
                        ],
                      ),
      ),
    );
  }
}

/// Small uppercase label separating "Small Groups" from "Auxiliaries" in
/// the list.
class _GroupSectionHeader extends StatelessWidget {
  final String title;
  const _GroupSectionHeader(this.title);

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

/// One row in the group list; tapping it opens [GroupDetailScreen].
class _GroupTile extends StatelessWidget {
  final SmallGroup group;
  final GroupListScreen widget;
  const _GroupTile({required this.group, required this.widget});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(group.name),
      subtitle: group.description != null ? Text(group.description!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupDetailScreen(
            group: group,
            groupService: widget.groupService,
            directoryService: widget.directoryService,
            profile: widget.profile,
          ),
        ),
      ),
    );
  }
}
