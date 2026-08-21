import 'package:flutter/material.dart';

/// Central place for app-wide theming. Real brand colors/typography can
/// replace these placeholders once the church has a visual identity to
/// work from — the point of centralizing it now is so that update is a
/// one-file change later, not a find-and-replace across every screen.
class AppTheme {
  // Private constructor — this class is never instantiated, it's just a
  // namespace for the static theme getters/constants below.
  AppTheme._();

  // Base color Material 3 derives the whole light/dark color scheme from.
  static const Color seedColor = Color(0xFF2E5A87);

  /// Light theme used when the device/app is in light mode.
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

  /// Dark theme used when the device/app is in dark mode.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}
