// Detail screen for a single small group: shows its description,
// members, and shared materials, with management actions for leaders/
// admins.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../../directory/directory_service.dart';
import '../../directory/screens/member_picker_screen.dart';
import '../group_service.dart';
import '../models.dart';

/// Shows one [group]'s details: description, member list, and shared
/// materials. Add-member/add-material actions are shown only when
/// [profile] is the group's leader or an admin (see [_canManage]).
class GroupDetailScreen extends StatefulWidget {
  final SmallGroup group;
  final GroupService groupService;
  final DirectoryService directoryService;
  final AppProfile? profile;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.groupService,
    required this.directoryService,
    required this.profile,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

// Loads and holds this group's members and materials. Both lists are
// nullable to distinguish "not loaded / not visible to this user" (null)
// from "loaded and empty" ([]) — see _load below.
class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<GroupMember>? _members;
  // Null means materials couldn't be loaded (usually because the current
  // user isn't a member of this group and the backend returned 403).
  List<GroupMaterial>? _materials;
  // Whether the current user is a member of this group, inferred from
  // whether the materials request succeeded (see _load).
  bool _isMember = false;
  bool _loading = true;

  // Group leaders and admins get member/material management controls.
  bool get _canManage =>
      widget.profile?.role == AppRole.admin || widget.profile?.id == widget.group.leaderId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Loads members and materials independently so a failure on one
  // doesn't block the other. Materials are backend-gated to members/
  // admins only, so a 403 there is used to infer _isMember rather than
  // treated as a hard error.
  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      _materials = await widget.groupService.listMaterials(widget.group.id);
      _isMember = true;
    } on ApiException catch (e) {
      _isMember = e.statusCode != 403;
      _materials = null;
    } catch (_) {
      _materials = null;
    }

    try {
      _members = await widget.groupService.listMembers(widget.group.id);
    } catch (_) {
      _members = null;
    }

    if (mounted) setState(() => _loading = false);
  }

  // Opens the member picker and, if a member was picked, adds them to
  // this group.
  Future<void> _addMember() async {
    final picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberPickerScreen(directoryService: widget.directoryService),
      ),
    );
    if (picked == null) return;
    try {
      await widget.groupService.addMember(groupId: widget.group.id, profileId: picked.profileId!);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add member: $e')));
    }
  }

  // Shows a dialog to enter a new material's title/link, then adds it if
  // confirmed with a non-empty title.
  Future<void> _addMaterial() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    final add = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Link (optional)'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );

    if (add != true || titleController.text.trim().isEmpty) return;

    try {
      await widget.groupService.addMaterial(
        groupId: widget.group.id,
        title: titleController.text.trim(),
        url: urlController.text.trim(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add material: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.group.description != null) ...[
                    Text(widget.group.description!),
                    const SizedBox(height: 16),
                  ],
                  // Members section.
                  Text('Members', style: Theme.of(context).textTheme.titleMedium),
                  if (_members == null)
                    const Text('Members are visible to group members and admins only.')
                  else if (_members!.isEmpty)
                    const Text('No members yet.')
                  else
                    for (final member in _members!) Text('• ${member.profileId}'),
                  if (_canManage)
                    TextButton.icon(
                      onPressed: _addMember,
                      icon: const Icon(Icons.person_add_alt_outlined),
                      label: const Text('Add member'),
                    ),
                  const Divider(height: 32),
                  // Shared materials section.
                  Text('Shared materials', style: Theme.of(context).textTheme.titleMedium),
                  if (!_isMember)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Materials are visible to group members and admins only.'),
                    )
                  else if (_materials == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Could not load materials.'),
                    )
                  else if (_materials!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No materials shared yet.'),
                    )
                  else
                    for (final material in _materials!)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(material.title),
                        subtitle: material.description != null ? Text(material.description!) : null,
                        trailing: material.url != null
                            ? IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => launchUrl(
                                  Uri.parse(material.url!),
                                  mode: LaunchMode.externalApplication,
                                ),
                              )
                            : null,
                      ),
                  if (_canManage)
                    TextButton.icon(
                      onPressed: _addMaterial,
                      icon: const Icon(Icons.add_link),
                      label: const Text('Add material'),
                    ),
                ],
              ),
            ),
    );
  }
}
