import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_service.dart';
import 'core/config/env_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/home/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = EnvConfig.fromDartDefines();

  if (config.supabaseUrl.isNotEmpty && config.supabaseAnonKey.isNotEmpty) {
    // supabase_flutter's newer SDK calls this the "publishable key"; we
    // keep calling it the anon key in our own config/docs since that's
    // still the term the Supabase dashboard itself uses.
    await Supabase.initialize(url: config.supabaseUrl, publishableKey: config.supabaseAnonKey);
  }

  runApp(ChurchApp(config: config));
}

/// Root widget. Everything under `lib/features/<feature_name>/` gets its
/// screens, models, and API calls; this file just wires config + auth +
/// the API client together and picks the right theme.
class ChurchApp extends StatefulWidget {
  final EnvConfig config;

  const ChurchApp({super.key, required this.config});

  @override
  State<ChurchApp> createState() => _ChurchAppState();
}

class _ChurchAppState extends State<ChurchApp> {
  late final AuthService _authService;
  late final ApiClient _apiClient;

  bool get _supabaseConfigured =>
      widget.config.supabaseUrl.isNotEmpty && widget.config.supabaseAnonKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiClient = ApiClient(config: widget.config, getAccessToken: _currentAccessToken);
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<String?> _currentAccessToken() async {
    if (!_supabaseConfigured) return null;
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Church App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: _supabaseConfigured
          ? AuthGate(apiClient: _apiClient, authService: _authService)
          : const _SupabaseNotConfiguredScreen(),
    );
  }
}

/// Shown instead of crashing when SUPABASE_URL/SUPABASE_ANON_KEY haven't
/// been passed via --dart-define yet — see README.md for the run command.
class _SupabaseNotConfiguredScreen extends StatelessWidget {
  const _SupabaseNotConfiguredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.settings_outlined, size: 48),
              SizedBox(height: 16),
              Text(
                'Supabase isn\'t configured for this build.\n\n'
                'Run with --dart-define=SUPABASE_URL=... and '
                '--dart-define=SUPABASE_ANON_KEY=... (see README.md).',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
