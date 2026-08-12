import 'package:flutter/material.dart';

import 'core/config/env_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';

void main() {
  final config = EnvConfig.fromDartDefines();
  runApp(ChurchApp(config: config));
}

/// Root widget. This is intentionally a thin shell for Phase 0 — real
/// features (directory, attendance, Bible reader, ...) live under
/// `lib/features/<feature_name>/` starting in Phase 1, each with its own
/// screens, models, and API calls, so the app stays organized as it grows.
class ChurchApp extends StatelessWidget {
  final EnvConfig config;

  const ChurchApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Church App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: HomeShell(config: config),
    );
  }
}

/// Temporary Phase 0 landing screen — proves the app boots and can reach
/// the backend health check. Gets replaced by real navigation (directory,
/// content, community tabs) in Phase 1.
class HomeShell extends StatefulWidget {
  final EnvConfig config;

  const HomeShell({super.key, required this.config});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final ApiClient _apiClient;
  String _status = 'Not checked yet';

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(config: widget.config);
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    setState(() => _status = 'Checking...');
    try {
      final result = await _apiClient.health();
      setState(() => _status = 'Backend says: ${result['status']} '
          '(${result['environment']})');
    } catch (e) {
      setState(() => _status = 'Could not reach backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Church App — Phase 0')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Environment: ${widget.config.environment.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _checkBackend,
                child: const Text('Check backend health'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
