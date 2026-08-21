import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../directory/directory_service.dart';
import '../../directory/models.dart';
import '../attendance_service.dart';
import '../models.dart';

/// Lets a leader search the member directory and tap to check members in
/// to a specific [service]. Already-checked-in members show a checkmark
/// instead of a "Check in" button.
class CheckInScreen extends StatefulWidget {
  final ChurchService service;
  final AttendanceService attendanceService;
  final DirectoryService directoryService;

  const CheckInScreen({
    super.key,
    required this.service,
    required this.attendanceService,
    required this.directoryService,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

/// Manages the member search results plus the set of members already
/// checked in to this service, so the UI can show who's present at a
/// glance and optimistically update as leaders tap "Check in".
class _CheckInScreenState extends State<CheckInScreen> {
  final _searchController = TextEditingController();
  // Debounce timer so we don't fire a network request on every keystroke.
  Timer? _debounce;
  List<Member> _members = [];
  // IDs of members already checked in to this service — drives the
  // checkmark vs. "Check in" button in the list.
  Set<String> _checkedInMemberIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttendeesThenSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Loads who's already checked in (to seed the checkmarks), then runs an
  /// initial empty search to populate the member list.
  Future<void> _loadAttendeesThenSearch() async {
    try {
      final attendees = await widget.attendanceService.listAttendees(widget.service.id);
      setState(() => _checkedInMemberIds = attendees.map((a) => a.memberId).toSet());
    } catch (_) {
      // Attendee list is a convenience for showing checkmarks — if it fails
      // we still let the leader search and mark attendance below.
    }
    await _search('');
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

  /// Marks [member] present immediately in the UI (optimistic update),
  /// then confirms it with the server — rolling the UI change back if the
  /// request fails.
  Future<void> _markPresent(Member member) async {
    setState(() => _checkedInMemberIds = {..._checkedInMemberIds, member.id});
    try {
      await widget.attendanceService.markAttendance(
        serviceId: widget.service.id,
        memberId: member.id,
      );
    } catch (e) {
      // Roll back the optimistic update since the server call failed.
      setState(() => _checkedInMemberIds = _checkedInMemberIds.difference({member.id}));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not mark ${member.fullName} present: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '${DateFormat.yMMMd().format(widget.service.serviceDate)} · '
              '${_checkedInMemberIds.length} checked in',
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              decoration: const InputDecoration(
                labelText: 'Search members to check in',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final present = _checkedInMemberIds.contains(member.id);
                          return ListTile(
                            title: Text(member.fullName),
                            trailing: present
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : OutlinedButton(
                                    onPressed: () => _markPresent(member),
                                    child: const Text('Check in'),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
