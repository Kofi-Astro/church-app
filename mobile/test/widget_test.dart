// Smoke test for the Phase 0 shell. Replaces the default counter-app test
// that shipped with `flutter create` — that widget no longer exists.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App boots and shows the Phase 0 home shell',
      (WidgetTester tester) async {
    const config = EnvConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: 'http://localhost:8000',
      supabaseUrl: '',
      supabaseAnonKey: '',
    );

    await tester.pumpWidget(ChurchApp(config: config));

    expect(find.text('Church App — Phase 0'), findsOneWidget);
    expect(find.text('Check backend health'), findsOneWidget);
  });
}
