import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Bookmarks and highlights are pure per-user data with no cross-user
/// access ever needed, so — unlike directory/attendance/sermons — this
/// talks straight to Supabase with the anon key, relying on RLS
/// (0003_content.sql) rather than routing through the FastAPI backend.
/// This is the "Flutter app --(anon key, RLS-scoped)--> Supabase" path
/// from docs/threat-model.md's trust-boundary diagram.
class BibleSyncService {
  /// The global Supabase client instance (set up once at app startup).
  SupabaseClient get _client => Supabase.instance.client;

  /// Lists the current user's bookmarks, most recently created first. RLS
  /// on the `bible_bookmarks` table ensures only their own rows come back.
  Future<List<BibleBookmark>> listBookmarks() async {
    final rows =
        await _client.from('bible_bookmarks').select().order('created_at', ascending: false);
    return (rows as List).map((r) => BibleBookmark.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Bookmarks a chapter for the current user. Uses upsert so bookmarking
  /// the same chapter twice doesn't create a duplicate row.
  Future<BibleBookmark> addBookmark({
    required String translationId,
    required String bookId,
    required String bookName,
    required int chapter,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('bible_bookmarks')
        .upsert({
          'profile_id': userId,
          'translation_id': translationId,
          'book_id': bookId,
          'book_name': bookName,
          'chapter': chapter,
        })
        .select()
        .single();
    return BibleBookmark.fromRow(row);
  }

  /// Deletes a bookmark by its row id.
  Future<void> removeBookmark(String id) async {
    await _client.from('bible_bookmarks').delete().eq('id', id);
  }

  /// Lists the current user's verse highlights for one specific chapter
  /// (used to re-apply highlight colors when the reader opens that
  /// chapter).
  Future<List<BibleHighlight>> listHighlights({
    required String translationId,
    required String bookId,
    required int chapter,
  }) async {
    final rows = await _client
        .from('bible_highlights')
        .select()
        .eq('translation_id', translationId)
        .eq('book_id', bookId)
        .eq('chapter', chapter);
    return (rows as List).map((r) => BibleHighlight.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Highlights (or re-colors, via upsert) a single verse for the current
  /// user.
  Future<BibleHighlight> addHighlight({
    required String translationId,
    required String bookId,
    required int chapter,
    required int verse,
    String color = 'yellow',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('bible_highlights')
        .upsert({
          'profile_id': userId,
          'translation_id': translationId,
          'book_id': bookId,
          'chapter': chapter,
          'verse': verse,
          'color': color,
        })
        .select()
        .single();
    return BibleHighlight.fromRow(row);
  }

  /// Removes a verse highlight by its row id.
  Future<void> removeHighlight(String id) async {
    await _client.from('bible_highlights').delete().eq('id', id);
  }
}
