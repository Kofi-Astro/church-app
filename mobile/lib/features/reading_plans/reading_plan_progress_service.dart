import 'package:supabase_flutter/supabase_flutter.dart';

/// Per-user reading progress — same "talk to Supabase directly, RLS-scoped
/// to the caller's own rows" pattern as bible_sync_service.dart. Plan
/// content itself (title, days) comes from FastAPI via ReadingPlanService;
/// this is only the "which days has THIS user completed" half.
class ReadingPlanProgressService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Returns the set of day numbers the current user has marked complete
  /// for `planId`. Returns an empty set (rather than throwing) if nobody
  /// is signed in to Supabase.
  Future<Set<int>> completedDays(String planId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};
    final rows = await _client
        .from('reading_plan_progress')
        .select('day_number')
        .eq('plan_id', planId)
        .eq('profile_id', userId);
    return (rows as List).map((r) => r['day_number'] as int).toSet();
  }

  /// Marks `dayNumber` of `planId` as complete for the current user.
  /// Uses upsert so calling this twice for the same day is a no-op rather
  /// than an error.
  Future<void> markComplete({required String planId, required int dayNumber}) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('reading_plan_progress').upsert({
      'profile_id': userId,
      'plan_id': planId,
      'day_number': dayNumber,
    });
  }

  /// Undoes [markComplete] — removes the completion record for that day.
  Future<void> markIncomplete({required String planId, required int dayNumber}) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('reading_plan_progress')
        .delete()
        .eq('profile_id', userId)
        .eq('plan_id', planId)
        .eq('day_number', dayNumber);
  }
}
