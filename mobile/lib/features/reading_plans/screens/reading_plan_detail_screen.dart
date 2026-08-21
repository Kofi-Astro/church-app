// Detail screen for a single reading plan: shows each day and lets the
// user check off days as they complete them.
import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../models.dart';
import '../reading_plan_progress_service.dart';
import '../reading_plan_service.dart';

/// Shows [plan]'s days with a progress bar and checkboxes for marking
/// each day complete. Combines plan content (from [planService], the
/// FastAPI backend) with per-user progress (from a local
/// [ReadingPlanProgressService], talking to Supabase directly).
class ReadingPlanDetailScreen extends StatefulWidget {
  final ReadingPlan plan;
  final ReadingPlanService planService;
  final AppProfile? profile;

  const ReadingPlanDetailScreen({
    super.key,
    required this.plan,
    required this.planService,
    required this.profile,
  });

  @override
  State<ReadingPlanDetailScreen> createState() => _ReadingPlanDetailScreenState();
}

// Holds this plan's days plus which day numbers the current user has
// completed.
class _ReadingPlanDetailScreenState extends State<ReadingPlanDetailScreen> {
  final _progressService = ReadingPlanProgressService();
  List<ReadingPlanDay> _days = [];
  // Set of day numbers the current user has marked complete.
  Set<int> _completed = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Loads the plan's days (required — failure shows the error state) and
  // the user's completion progress (best-effort — failure just leaves
  // progress empty, see the inner try/catch).
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final days = await widget.planService.listDays(widget.plan.id);
      Set<int> completed = {};
      try {
        completed = await _progressService.completedDays(widget.plan.id);
      } catch (_) {
        // Progress is a per-user overlay — a failed fetch (e.g. signed
        // out of Supabase) shouldn't block seeing the plan's days.
      }
      setState(() {
        _days = days;
        _completed = completed;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Toggles a day's completion state. Updates the UI immediately
  // (optimistic update) then persists the change; if saving fails, the
  // UI change is rolled back and an error is shown.
  Future<void> _toggleDay(int dayNumber) async {
    final wasComplete = _completed.contains(dayNumber);
    setState(() {
      _completed = wasComplete
          ? _completed.difference({dayNumber})
          : {..._completed, dayNumber};
    });
    try {
      if (wasComplete) {
        await _progressService.markIncomplete(planId: widget.plan.id, dayNumber: dayNumber);
      } else {
        await _progressService.markComplete(planId: widget.plan.id, dayNumber: dayNumber);
      }
    } catch (e) {
      // Roll back the optimistic update since the save failed.
      setState(() {
        _completed = wasComplete ? {..._completed, dayNumber} : _completed.difference({dayNumber});
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save progress: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _days.isEmpty ? 0.0 : _completed.length / _days.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.plan.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    if (widget.plan.description != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(widget.plan.description!),
                      ),
                    // Progress bar + "X of Y days complete" summary.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 4),
                          Text('${_completed.length} of ${_days.length} days complete'),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    // Checklist of days.
                    Expanded(
                      child: _days.isEmpty
                          ? const Center(child: Text('No days added to this plan yet.'))
                          : ListView.builder(
                              itemCount: _days.length,
                              itemBuilder: (context, index) {
                                final day = _days[index];
                                final done = _completed.contains(day.dayNumber);
                                return CheckboxListTile(
                                  value: done,
                                  onChanged: (_) => _toggleDay(day.dayNumber),
                                  title: Text('Day ${day.dayNumber}: ${day.reference}'),
                                  subtitle: day.title != null ? Text(day.title!) : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
