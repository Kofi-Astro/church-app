import 'package:supabase_flutter/supabase_flutter.dart';

/// Role mirrors the `app_role` enum in infra/migrations/0001_init.sql.
enum AppRole { member, groupLeader, admin, financeAdmin }

/// Converts the role string stored in the database (snake_case, e.g.
/// 'group_leader') into an [AppRole]. Unrecognized/missing values fall
/// back to the least-privileged role ([AppRole.member]).
AppRole roleFromString(String value) {
  switch (value) {
    case 'group_leader':
      return AppRole.groupLeader;
    case 'admin':
      return AppRole.admin;
    case 'finance_admin':
      return AppRole.financeAdmin;
    default:
      return AppRole.member;
  }
}

/// The signed-in user's profile info as stored in the `profiles` table
/// (name + role). This is the app's local copy of "who is this person and
/// what are they allowed to do" — separate from Supabase's own auth user.
class AppProfile {
  final String id;
  final String fullName;
  final AppRole role;

  const AppProfile({required this.id, required this.fullName, required this.role});

  /// True for any role above plain member — used to decide whether to show
  /// admin-only UI (e.g. the admin dashboard entry point).
  bool get canAccessAdmin =>
      role == AppRole.admin || role == AppRole.financeAdmin || role == AppRole.groupLeader;
}

/// Thin wrapper around Supabase Auth. Kept separate from ApiClient because
/// this talks directly to Supabase (for login/session/profile), while
/// ApiClient talks to our own FastAPI backend — see docs/threat-model.md
/// for why those are two different trust boundaries.
class AuthService {
  /// The global Supabase client instance (set up once at app startup).
  SupabaseClient get _client => Supabase.instance.client;

  /// The current logged-in session, or null if nobody is signed in.
  Session? get currentSession => _client.auth.currentSession;

  /// Fires whenever sign-in/sign-out/token-refresh happens, so the app can
  /// react (e.g. redirect to login) without polling.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Signs the user in with email + password via Supabase Auth. Throws if
  /// the credentials are invalid; callers should catch and show an error.
  Future<void> signInWithPassword({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Signs the current user out and clears the local session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// The current user's row in `profiles` — null if not signed in or the
  /// profile hasn't been provisioned yet (e.g. auth user created but the
  /// profiles insert failed/hasn't landed).
  Future<AppProfile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final row = await _client
        .from('profiles')
        .select('id, full_name, role')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;

    return AppProfile(
      id: row['id'] as String,
      fullName: row['full_name'] as String,
      role: roleFromString(row['role'] as String),
    );
  }
}
