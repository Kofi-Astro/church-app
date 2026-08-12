import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/features/auth/login_screen.dart';

void main() {
  testWidgets('Shows validation errors instead of submitting an empty form', (
    WidgetTester tester,
  ) async {
    // AuthService() is safe to construct without Supabase.initialize() —
    // it only touches Supabase.instance lazily inside its methods, and
    // validation failure here means signInWithPassword is never called.
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authService: AuthService())),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
