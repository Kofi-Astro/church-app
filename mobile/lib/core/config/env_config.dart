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

class EnvConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  const EnvConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

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
