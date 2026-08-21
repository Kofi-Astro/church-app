// Top-level Reading Plans screen: lists available plans and lets the
// user turn on a daily reading reminder notification.
import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/notifications/reminder_service.dart';
import '../models.dart';
import '../reading_plan_service.dart';
import 'reading_plan_detail_screen.dart';

/// Lists all reading plans; tapping one opens [ReadingPlanDetailScreen].
/// Also hosts the daily reading reminder toggle (local device
/// notification, unrelated to the backend).
class ReadingPlanListScreen extends StatefulWidget {
  final ReadingPlanService planService;
  final AppProfile? profile;

  const ReadingPlanListScreen({super.key, required this.planService, required this.profile});

  @override
  State<ReadingPlanListScreen> createState() => _ReadingPlanListScreenState();
}

// Holds the fetched plan list plus the local daily-reminder settings
// (whether it's on, and what time it fires).
class _ReadingPlanListScreenState extends State<ReadingPlanListScreen> {
  final _reminderService = ReminderService();
  List<ReadingPlan> _plans = [];
  bool _loading = true;
  String? _error;
  // Whether the daily reading reminder notification is currently
  // scheduled on this device.
  bool _reminderEnabled = false;
  // Time of day the reminder fires; defaults to 7:00 AM until changed.
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
    _loadReminderState();
  }

  // Fetches the reading plan list; used on first load and
  // pull-to-refresh.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final plans = await widget.planService.listPlans();
      setState(() {
        _plans = plans;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Reads whether a reminder is currently scheduled (e.g. after
  // reopening the app) so the switch reflects actual device state.
  Future<void> _loadReminderState() async {
    final scheduled = await _reminderService.isScheduled();
    if (mounted) setState(() => _reminderEnabled = scheduled);
  }

  // Turns the reminder on (requesting notification permission first) or
  // off, in response to the switch being toggled.
  Future<void> _toggleReminder(bool enabled) async {
    if (enabled) {
      final granted = await _reminderService.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Notification permission was denied.')));
        return;
      }
      await _reminderService.scheduleDailyReminder(_reminderTime);
    } else {
      await _reminderService.cancelReminder();
    }
    setState(() => _reminderEnabled = enabled);
  }

  // Opens a time picker for the reminder and reschedules it immediately
  // if the reminder is already enabled.
  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked == null) return;
    setState(() => _reminderTime = picked);
    if (_reminderEnabled) {
      await _reminderService.scheduleDailyReminder(_reminderTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Plans')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            // Daily reminder toggle + time picker.
            SwitchListTile(
              title: const Text('Daily reading reminder'),
              subtitle: Text('Every day at ${_reminderTime.format(context)}'),
              value: _reminderEnabled,
              onChanged: _toggleReminder,
              secondary: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: _pickReminderTime,
              ),
            ),
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(padding: const EdgeInsets.all(16), child: Text(_error!))
            else if (_plans.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No reading plans yet.', textAlign: TextAlign.center),
              )
            else
              for (final plan in _plans)
                ListTile(
                  title: Text(plan.title),
                  subtitle: Text(plan.planType.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReadingPlanDetailScreen(
                        plan: plan,
                        planService: widget.planService,
                        profile: widget.profile,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
