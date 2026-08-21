// App entry point. This file is intentionally small: it reads config,
// (maybe) sets up Supabase, and hands off to ChurchApp/AuthGate — actual
// feature code lives under lib/features/<feature_name>/.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_service.dart';
import 'core/config/env_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/home/auth_gate.dart';

/// App entry point, called by Flutter when the app launches.
void main() async {
  // Required before doing anything that touches platform channels (like
  // Supabase.initialize below) before runApp() is called.
  WidgetsFlutterBinding.ensureInitialized();
  // Reads SUPABASE_URL / SUPABASE_ANON_KEY (etc.) that were passed in at
  // build time via --dart-define; see EnvConfig for the full list.
  final config = EnvConfig.fromDartDefines();

  if (config.supabaseUrl.isNotEmpty && config.supabaseAnonKey.isNotEmpty) {
    // supabase_flutter's newer SDK calls this the "publishable key"; we
    // keep calling it the anon key in our own config/docs since that's
    // still the term the Supabase dashboard itself uses.
    await Supabase.initialize(url: config.supabaseUrl, publishableKey: config.supabaseAnonKey);
  }
  // If Supabase wasn't configured, config is still passed through so
  // ChurchApp can show a friendly "not configured" screen instead of a
  // crash further down the line.

  runApp(ChurchApp(config: config));
}

/// Root widget. Everything under `lib/features/<feature_name>/` gets its
/// screens, models, and API calls; this file just wires config + auth +
/// the API client together and picks the right theme.
class ChurchApp extends StatefulWidget {
  // Config parsed from --dart-define values (Supabase URL/key, API base
  // URL, etc.) — passed down so both the auth service and the API client
  // can be built from it.
  final EnvConfig config;

  const ChurchApp({super.key, required this.config});

  @override
  State<ChurchApp> createState() => _ChurchAppState();
}

// Owns the two long-lived, app-wide services (AuthService for
// Supabase auth, ApiClient for talking to our FastAPI backend) so they're
// created once and reused everywhere, instead of every screen creating
// its own.
class _ChurchAppState extends State<ChurchApp> {
  late final AuthService _authService;
  late final ApiClient _apiClient;

  // Whether Supabase credentials were actually provided. When false we
  // show _SupabaseNotConfiguredScreen instead of the real app.
  bool get _supabaseConfigured =>
      widget.config.supabaseUrl.isNotEmpty && widget.config.supabaseAnonKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    // ApiClient needs a way to fetch the current Supabase access token on
    // every request (for auth headers), so we pass it a callback rather
    // than a fixed token.
    _apiClient = ApiClient(config: widget.config, getAccessToken: _currentAccessToken);
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  // Callback handed to ApiClient — returns the current Supabase session's
  // access token (or null if signed out / Supabase isn't configured) so
  // ApiClient can attach it as a bearer token on outgoing requests.
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
      // If Supabase isn't configured there's nothing useful the app can
      // do (no auth, no data), so we short-circuit straight to a
      // "here's how to fix this" screen instead of the normal auth flow.
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
