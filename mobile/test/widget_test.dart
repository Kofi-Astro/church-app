// Smoke test for the app shell's "Supabase not configured" fallback —
// the only path testable without a live Supabase project or network.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Shows a setup message when Supabase env vars are missing', (
    WidgetTester tester,
  ) async {
    const config = EnvConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: 'http://localhost:8000',
      supabaseUrl: '',
      supabaseAnonKey: '',
    );

    await tester.pumpWidget(ChurchApp(config: config));

    expect(find.textContaining('Supabase isn\'t configured'), findsOneWidget);
  });
}
