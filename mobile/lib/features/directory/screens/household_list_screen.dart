import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../directory_service.dart';
import '../models.dart';
import 'household_detail_screen.dart';

/// Paginated, infinite-scrolling list of all households, with a way for
/// admins to add new ones. Tapping a household opens
/// [HouseholdDetailScreen] to see its members.
class HouseholdListScreen extends StatefulWidget {
  final DirectoryService directoryService;
  /// Current user's profile — used to decide whether the "add household"
  /// button is shown (admin-only). Null if not signed in.
  final AppProfile? profile;

  const HouseholdListScreen({super.key, required this.directoryService, required this.profile});

  @override
  State<HouseholdListScreen> createState() => _HouseholdListScreenState();
}

/// Manages the loaded household list, pagination state, and the "add
/// household" dialog flow.
class _HouseholdListScreenState extends State<HouseholdListScreen> {
  // Households loaded so far, accumulated across pages as the user scrolls.
  final List<Household> _households = [];
  // True while a page fetch is in flight (prevents duplicate/overlapping
  // fetches from scroll + retry firing at once).
  bool _loading = false;
  // Whether there are more pages left to fetch from the server.
  bool _hasMore = true;
  // Last error message, shown in place of the list when present.
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  /// Fetches the next page of households (starting after what's already
  /// loaded) and appends it to [_households]. No-ops if already loading or
  /// there's nothing more to fetch.
  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.directoryService.listHouseholds(offset: _households.length);
      setState(() {
        _households.addAll(page.items);
        _hasMore = page.hasMore;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Clears the loaded list and re-fetches from the start — used for
  /// pull-to-refresh and after creating a new household.
  Future<void> _refresh() async {
    setState(() {
      _households.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

  /// Shows a dialog to collect a new household's name/address, then
  /// creates it via the API and refreshes the list on success.
  Future<void> _showAddHouseholdDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Household name'),
              autofocus: true,
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != true || nameController.text.trim().isEmpty) return;

    try {
      await widget.directoryService.createHousehold(
        name: nameController.text.trim(),
        address: addressController.text.trim(),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create household: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.profile?.role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Households')),
      // Add button, admins only.
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: _showAddHouseholdDialog, child: const Icon(Icons.add))
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        // Empty/error state vs. the actual list.
        child: _households.isEmpty && !_loading
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _error ?? 'No households yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : ListView.builder(
                // +1 slot at the end for the "load more" spinner/sentinel.
                itemCount: _households.length + 1,
                itemBuilder: (context, index) {
                  if (index == _households.length) {
                    // Reaching the last slot triggers loading the next
                    // page (classic scroll-to-load-more pattern).
                    if (_hasMore) {
                      _loadMore();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  final household = _households[index];
                  return ListTile(
                    title: Text(household.name),
                    subtitle: household.address != null ? Text(household.address!) : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HouseholdDetailScreen(
                          household: household,
                          directoryService: widget.directoryService,
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
