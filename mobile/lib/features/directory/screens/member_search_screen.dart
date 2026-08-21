import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../directory_service.dart';
import '../models.dart';
import 'member_detail_screen.dart';

/// Full member directory search — like [MemberPickerScreen] but for
/// general Browse/lookup use (not restricted to members with app
/// accounts), and lets admins add new members.
class MemberSearchScreen extends StatefulWidget {
  final DirectoryService directoryService;
  /// Current user's profile — used to decide whether the "add member"
  /// button is shown (admin-only). Null if not signed in.
  final AppProfile? profile;

  const MemberSearchScreen({super.key, required this.directoryService, required this.profile});

  @override
  State<MemberSearchScreen> createState() => _MemberSearchScreenState();
}

/// Manages the search box, debounce timer, result list, and "add member"
/// dialog flow.
class _MemberSearchScreenState extends State<MemberSearchScreen> {
  final _searchController = TextEditingController();
  // Debounce timer so we don't fire a network request on every keystroke.
  Timer? _debounce;
  List<Member> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Called on every keystroke in the search box; restarts the debounce
  /// timer so the actual search only fires after typing pauses.
  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  /// Runs the member search for [query] (empty string returns everyone).
  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.directoryService.listMembers(search: query, limit: 50);
      setState(() => _members = page.items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Shows a dialog to collect a new member's name/email/phone, then
  /// creates them via the API and re-runs the current search on success.
  Future<void> _showAddMemberDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              autofocus: true,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (create != true || nameController.text.trim().isEmpty) return;

    try {
      await widget.directoryService.createMember(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
      );
      await _search(_searchController.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create member: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.profile?.role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'Search members…',
            border: InputBorder.none,
          ),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: _showAddMemberDialog, child: const Icon(Icons.add))
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _members.isEmpty
                  ? const Center(child: Text('No members found.'))
                  : ListView.builder(
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        return ListTile(
                          title: Text(member.fullName),
                          subtitle: Text(
                            [member.email, member.phone].whereType<String>().join(' · '),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MemberDetailScreen(member: member)),
                          ),
                        );
                      },
                    ),
    );
  }
}
