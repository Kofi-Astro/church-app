import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../attendance_service.dart';
import '../models.dart';

class AttendanceReportScreen extends StatefulWidget {
  final AttendanceService attendanceService;

  const AttendanceReportScreen({super.key, required this.attendanceService});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<AttendanceReportRow> _rows = [];
  DateTimeRange? _range;
  bool _loading = true;
  bool _exporting = false;
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
      final rows = await widget.attendanceService.report(
        start: _range?.start,
        end: _range?.end,
      );
      setState(() => _rows = rows);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
    await _load();
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final csv = await widget.attendanceService.exportCsv(
        start: _range?.start,
        end: _range?.end,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/attendance_report.csv');
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Attendance report'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAttendance = _rows.fold<int>(0, (sum, row) => sum + row.attendeeCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance report'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            onPressed: (_exporting || _rows.isEmpty) ? null : _exportCsv,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    children: [
                      ListTile(
                        title: const Text('Total attendance in range'),
                        trailing: Text(
                          '$totalAttendance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Divider(height: 1),
                      if (_rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No services in this range.', textAlign: TextAlign.center),
                        ),
                      for (final row in _rows)
                        ListTile(
                          title: Text(row.serviceName),
                          subtitle: Text(DateFormat.yMMMd().format(row.serviceDate)),
                          trailing: Text('${row.attendeeCount}'),
                        ),
                    ],
                  ),
      ),
    );
  }
}
