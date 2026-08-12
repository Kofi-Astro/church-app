import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../models.dart';
import '../reading_plan_service.dart';
import 'reading_plan_detail_screen.dart';

class ReadingPlanListScreen extends StatefulWidget {
  final ReadingPlanService planService;
  final AppProfile? profile;

  const ReadingPlanListScreen({super.key, required this.planService, required this.profile});

  @override
  State<ReadingPlanListScreen> createState() => _ReadingPlanListScreenState();
}

class _ReadingPlanListScreenState extends State<ReadingPlanListScreen> {
  List<ReadingPlan> _plans = [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Plans')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _plans.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No reading plans yet.', textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          final plan = _plans[index];
                          return ListTile(
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
                          );
                        },
                      ),
      ),
    );
  }
}
