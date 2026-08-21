import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../auth/login_screen.dart';
import 'app_shell.dart';

/// Root of the signed-in/signed-out split. Listens to Supabase auth state
/// and swaps between the login screen and the main app shell — nothing
/// else in the app needs to know about session state directly.
class AuthGate extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const AuthGate({super.key, required this.apiClient, required this.authService});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

// Tracks the current signed-in profile (if any) and reacts to Supabase
// auth state changes so the UI updates automatically on sign-in/sign-out.
class _AuthGateState extends State<AuthGate> {
  AppProfile? _profile;
  bool _loading = true;
  // True when there's a valid Supabase session but no matching row in
  // `profiles` yet — an edge case handled with its own screen below
  // rather than silently treating the user as signed out.
  bool _sessionMissingProfile = false;
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    // Re-check auth state on every Supabase auth event (sign-in, sign-out,
    // token refresh, etc.) so this widget always reflects reality.
    _subscription = widget.authService.onAuthStateChange.listen((_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // Re-fetches the current session's profile (or clears it if signed
  // out) and updates state accordingly.
  Future<void> _refresh() async {
    setState(() => _loading = true);
    final hasSession = widget.authService.currentSession != null;
    final profile = hasSession ? await widget.authService.fetchCurrentProfile() : null;
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _sessionMissingProfile = hasSession && profile == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_sessionMissingProfile) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This account is signed in but has no profile yet. '
                  'Ask an admin to create one, or sign in as a different account.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: widget.authService.signOut, child: const Text('Sign out')),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return LoginScreen(authService: widget.authService);
    }

    return AppShell(apiClient: widget.apiClient, authService: widget.authService, profile: profile);
  }
}
