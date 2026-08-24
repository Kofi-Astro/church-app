import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../../congregations/congregation_service.dart';
import '../../congregations/models.dart';
import '../../directory/directory_service.dart';
import '../attendance_service.dart';
import '../models.dart';
import 'check_in_screen.dart';

/// Lists all church services, letting leaders/admins add new ones and tap
/// into [CheckInScreen] to check members in.
class ServiceListScreen extends StatefulWidget {
  final AttendanceService attendanceService;
  final DirectoryService directoryService;
  final CongregationService congregationService;
  /// Current user's profile — used to decide whether the "add service"
  /// button is shown (admin/group-leader only). Null if not signed in.
  final AppProfile? profile;

  const ServiceListScreen({
    super.key,
    required this.attendanceService,
    required this.directoryService,
    required this.congregationService,
    required this.profile,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

/// Manages the loaded service list and the "add service" dialog flow.
class _ServiceListScreenState extends State<ServiceListScreen> {
  List<ChurchService> _services = [];
  List<Congregation> _congregations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches the full service list and the congregation list (needed for
  /// the "add service" dialog's picker) from the server.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.attendanceService.listServices(),
        widget.congregationService.listCongregations(),
      ]);
      setState(() {
        _services = results[0] as List<ChurchService>;
        _congregations = results[1] as List<Congregation>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Shows a dialog to collect a new service's name, date, and congregation
  /// (with a nested StatefulBuilder so the date picker's selection updates
  /// the dialog without rebuilding the whole screen), then creates it via
  /// the API and refreshes the list on success.
  Future<void> _showAddServiceDialog() async {
    if (_congregations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add a congregation first (Admin > Congregations) before creating a service.'),
      ));
      return;
    }

    final nameController = TextEditingController();
    // Defaults to today; updated in-dialog via the date picker below.
    DateTime selectedDate = DateTime.now();
    // Defaults to the first congregation alphabetically; changed via the
    // dropdown below.
    String selectedCongregationId = _congregations.first.id;

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service name'),
                autofocus: true,
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedCongregationId,
                decoration: const InputDecoration(labelText: 'Congregation'),
                items: [
                  for (final congregation in _congregations)
                    DropdownMenuItem(value: congregation.id, child: Text(congregation.name)),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => selectedCongregationId = value);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat.yMMMd().format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
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
      await widget.attendanceService.createService(
        name: nameController.text.trim(),
        date: selectedDate,
        congregationId: selectedCongregationId,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create service: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.profile?.role == AppRole.admin || widget.profile?.role == AppRole.groupLeader;

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: _showAddServiceDialog, child: const Icon(Icons.add))
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _services.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No services yet.', textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          // Looks up the congregation name for display —
                          // falls back to nothing shown if the service
                          // predates congregations or the link was cleared.
                          final congregationName = _congregations
                              .where((c) => c.id == service.congregationId)
                              .firstOrNull
                              ?.name;
                          return ListTile(
                            title: Text(service.name),
                            subtitle: Text([
                              DateFormat.yMMMd().format(service.serviceDate),
                              ?congregationName,
                            ].join(' · ')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckInScreen(
                                  service: service,
                                  attendanceService: widget.attendanceService,
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
