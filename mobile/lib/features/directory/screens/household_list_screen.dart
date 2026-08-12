import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../directory_service.dart';
import '../models.dart';
import 'household_detail_screen.dart';

class HouseholdListScreen extends StatefulWidget {
  final DirectoryService directoryService;
  final AppProfile? profile;

  const HouseholdListScreen({super.key, required this.directoryService, required this.profile});

  @override
  State<HouseholdListScreen> createState() => _HouseholdListScreenState();
}

class _HouseholdListScreenState extends State<HouseholdListScreen> {
  final List<Household> _households = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

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

  Future<void> _refresh() async {
    setState(() {
      _households.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

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
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: _showAddHouseholdDialog, child: const Icon(Icons.add))
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                itemCount: _households.length + 1,
                itemBuilder: (context, index) {
                  if (index == _households.length) {
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
