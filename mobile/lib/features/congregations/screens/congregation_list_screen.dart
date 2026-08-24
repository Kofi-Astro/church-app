// Admin-only screen for managing the church's congregations (English,
// Akan, Youth Chapel, ...) — a short, non-paginated list since there are
// only ever a handful of these, unlike the member directory.
import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../congregation_service.dart';
import '../models.dart';

/// Lists all congregations and (for admins) lets you add or remove one.
class CongregationListScreen extends StatefulWidget {
  final CongregationService congregationService;
  final AppProfile? profile;

  const CongregationListScreen({
    super.key,
    required this.congregationService,
    required this.profile,
  });

  @override
  State<CongregationListScreen> createState() => _CongregationListScreenState();
}

// Holds the loaded congregation list plus loading/error state.
class _CongregationListScreenState extends State<CongregationListScreen> {
  List<Congregation> _congregations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fetches the full congregation list; used on first load, pull-to-refresh,
  // and after creating/deleting one.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final congregations = await widget.congregationService.listCongregations();
      setState(() => _congregations = congregations);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Shows a dialog to collect a new congregation's name/description, then
  // creates it via the API and refreshes the list on success.
  Future<void> _showAddCongregationDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New congregation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
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
      await widget.congregationService.createCongregation(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not create congregation: $e')));
    }
  }

  // Confirms, then deletes a congregation and refreshes the list.
  Future<void> _confirmDelete(Congregation congregation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${congregation.name}?'),
        content: const Text(
          'Members and services already linked to this congregation keep '
          'their link cleared, not deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.congregationService.deleteCongregation(congregation.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not delete congregation: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.profile?.role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Congregations')),
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: _showAddCongregationDialog, child: const Icon(Icons.add))
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _congregations.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No congregations yet.', textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _congregations.length,
                        itemBuilder: (context, index) {
                          final congregation = _congregations[index];
                          return ListTile(
                            title: Text(congregation.name),
                            subtitle: congregation.description != null
                                ? Text(congregation.description!)
                                : null,
                            trailing: canManage
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmDelete(congregation),
                                  )
                                : null,
                          );
                        },
                      ),
      ),
    );
  }
}
