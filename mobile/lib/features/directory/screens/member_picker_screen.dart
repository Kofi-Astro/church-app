import 'dart:async';

import 'package:flutter/material.dart';

import '../directory_service.dart';
import '../models.dart';

/// Picks a member who has an app account (profile_id set) — used
/// wherever a feature needs to reference a Supabase auth user (e.g.
/// assigning a small-group leader) rather than just a directory entry.
/// Members without an account (profileId == null, e.g. children added by
/// an admin) aren't selectable here since they have nothing to sign in
/// and hold group-leader/member rows as.
class MemberPickerScreen extends StatefulWidget {
  final DirectoryService directoryService;

  const MemberPickerScreen({super.key, required this.directoryService});

  @override
  State<MemberPickerScreen> createState() => _MemberPickerScreenState();
}

/// Manages the search box, debounce timer, and result list for picking a
/// member with an app account. Returns the picked [Member] via
/// `Navigator.pop(context, member)`.
class _MemberPickerScreenState extends State<MemberPickerScreen> {
  final _searchController = TextEditingController();
  // Debounce timer so we don't fire a network request on every keystroke.
  Timer? _debounce;
  List<Member> _members = [];
  bool _loading = true;

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

  /// Runs the member search and filters out members with no app account
  /// (profileId == null), since those can't be picked here.
  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final page = await widget.directoryService.listMembers(search: query, limit: 50);
      setState(() => _members = page.items.where((m) => m.profileId != null).toList());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onQueryChanged,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search members…', border: InputBorder.none),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(child: Text('No members with an app account found.'))
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return ListTile(
                      title: Text(member.fullName),
                      onTap: () => Navigator.pop(context, member),
                    );
                  },
                ),
    );
  }
}
