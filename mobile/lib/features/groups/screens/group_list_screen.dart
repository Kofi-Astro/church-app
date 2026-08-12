import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../directory/directory_service.dart';
import '../../directory/screens/member_picker_screen.dart';
import '../group_service.dart';
import '../models.dart';
import 'group_detail_screen.dart';

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

class _GroupListScreenState extends State<GroupListScreen> {
  List<SmallGroup> _groups = [];
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

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? leaderId;
    String? leaderName;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Small Groups')),
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
                    : ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
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
                        },
                      ),
      ),
    );
  }
}
