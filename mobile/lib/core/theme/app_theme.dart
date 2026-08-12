import 'package:flutter/material.dart';

/// Central place for app-wide theming. Real brand colors/typography can
/// replace these placeholders once the church has a visual identity to
/// work from — the point of centralizing it now is so that update is a
/// one-file change later, not a find-and-replace across every screen.
class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF2E5A87);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        // Comfortable default text scaling headroom for accessibility —
        // see proposal Section 3.4 (Accessibility & Offline Use).
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}
