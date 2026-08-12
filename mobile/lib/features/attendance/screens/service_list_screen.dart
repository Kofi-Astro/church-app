import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../../directory/directory_service.dart';
import '../attendance_service.dart';
import '../models.dart';
import 'check_in_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final AttendanceService attendanceService;
  final DirectoryService directoryService;
  final AppProfile? profile;

  const ServiceListScreen({
    super.key,
    required this.attendanceService,
    required this.directoryService,
    required this.profile,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  List<ChurchService> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final services = await widget.attendanceService.listServices();
      setState(() => _services = services);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddServiceDialog() async {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                          return ListTile(
                            title: Text(service.name),
                            subtitle: Text(DateFormat.yMMMd().format(service.serviceDate)),
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
