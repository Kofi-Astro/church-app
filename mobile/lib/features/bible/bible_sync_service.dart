import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Bookmarks and highlights are pure per-user data with no cross-user
/// access ever needed, so — unlike directory/attendance/sermons — this
/// talks straight to Supabase with the anon key, relying on RLS
/// (0003_content.sql) rather than routing through the FastAPI backend.
/// This is the "Flutter app --(anon key, RLS-scoped)--> Supabase" path
/// from docs/threat-model.md's trust-boundary diagram.
class BibleSyncService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<BibleBookmark>> listBookmarks() async {
    final rows =
        await _client.from('bible_bookmarks').select().order('created_at', ascending: false);
    return (rows as List).map((r) => BibleBookmark.fromRow(r as Map<String, dynamic>)).toList();
  }

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

  Future<void> removeBookmark(String id) async {
    await _client.from('bible_bookmarks').delete().eq('id', id);
  }

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

  Future<void> removeHighlight(String id) async {
    await _client.from('bible_highlights').delete().eq('id', id);
  }
}
