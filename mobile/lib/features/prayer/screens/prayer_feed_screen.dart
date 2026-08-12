import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../models.dart';
import '../prayer_service.dart';

class PrayerFeedScreen extends StatefulWidget {
  final PrayerService prayerService;
  final AppProfile? profile;

  const PrayerFeedScreen({super.key, required this.prayerService, required this.profile});

  @override
  State<PrayerFeedScreen> createState() => _PrayerFeedScreenState();
}

class _PrayerFeedScreenState extends State<PrayerFeedScreen> {
  List<PrayerRequest> _requests = [];
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
      final requests = await widget.prayerService.listRequests();
      setState(() {
        _requests = requests;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _togglePray(PrayerRequest request) async {
    final index = _requests.indexWhere((r) => r.id == request.id);
    try {
      final updated =
          request.isPraying ? await widget.prayerService.unpray(request.id) : await widget.prayerService.pray(request.id);
      setState(() => _requests[index] = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }

  Future<void> _deleteRequest(PrayerRequest request) async {
    try {
      await widget.prayerService.deleteRequest(request.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  Future<void> _showNewRequestDialog() async {
    final contentController = TextEditingController();
    PrayerVisibility visibility = PrayerVisibility.public;

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New prayer request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Request'),
                maxLines: 4,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<PrayerVisibility>(
                initialValue: visibility,
                decoration: const InputDecoration(labelText: 'Visibility'),
                items: [
                  for (final v in PrayerVisibility.values)
                    DropdownMenuItem(value: v, child: Text(v.label)),
                ],
                onChanged: (value) => setDialogState(() => visibility = value ?? visibility),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Post')),
          ],
        ),
      ),
    );

    if (create != true || contentController.text.trim().isEmpty) return;

    try {
      await widget.prayerService.createRequest(
        content: contentController.text.trim(),
        visibility: visibility,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not post: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Requests')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewRequestDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _requests.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No prayer requests yet.', textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          final isMine = request.profileId == widget.profile?.id;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(request.visibility.label),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Spacer(),
                                      if (isMine)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () => _deleteRequest(request),
                                        ),
                                    ],
                                  ),
                                  Text(request.content),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          request.isPraying
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: request.isPraying ? Colors.red : null,
                                        ),
                                        onPressed: () => _togglePray(request),
                                      ),
                                      Text('${request.prayingCount} praying'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
