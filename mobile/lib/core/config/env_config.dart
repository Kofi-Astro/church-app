/// Environment configuration.
///
/// Values are supplied at build time via --dart-define, never hard-coded
/// and never committed as real values. Example:
///
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000 \
///                --dart-define=ENV=dev
///
/// This keeps the same pattern as the backend's .env approach: nothing
/// sensitive lives in source control, and dev/staging/prod point at
/// different backends without code changes.
enum AppEnvironment { dev, staging, prod }

/// Bundles all the environment-specific settings the app needs at runtime
/// (which backend to call, which Supabase project to use, which
/// environment this build is). Build one with [fromDartDefines].
class EnvConfig {
  /// Which environment this build was compiled for (dev/staging/prod).
  final AppEnvironment environment;
  /// Base URL of our own FastAPI backend, e.g. http://localhost:8000.
  final String apiBaseUrl;
  /// URL of the Supabase project this build talks to for auth/direct data.
  final String supabaseUrl;
  /// Public (anon) Supabase API key — safe to ship in the app; never the
  /// service_role key.
  final String supabaseAnonKey;

  const EnvConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  /// Reads all config values from the --dart-define flags passed at build
  /// time (see file-level comment above) and falls back to sane dev
  /// defaults where possible. This is the normal way to construct
  /// [EnvConfig] — call it once at app startup.
  static EnvConfig fromDartDefines() {
    const envName = String.fromEnvironment('ENV', defaultValue: 'dev');
    final environment = AppEnvironment.values.firstWhere(
      (e) => e.name == envName,
      orElse: () => AppEnvironment.dev,
    );

    return EnvConfig(
      environment: environment,
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      ),
      // Only the anon key belongs here — the service_role key must never
      // ship inside the mobile app.
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }
}
