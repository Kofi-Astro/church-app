// Data models for the Bible feature: translations, verses/chapters (from
// bible-api.com), and the user's own bookmarks/highlights (from Supabase).

/// One available Bible translation (e.g. King James Version), identified
/// by the short code bible-api.com uses (e.g. 'kjv').
class BibleTranslation {
  final String id;
  final String name;

  const BibleTranslation({required this.id, required this.name});
}

/// The handful of public-domain English translations bible-api.com serves
/// (see https://bible-api.com/data) — hardcoded rather than fetched on
/// every launch since this list changes essentially never.
const kBibleTranslations = [
  BibleTranslation(id: 'kjv', name: 'King James Version'),
  BibleTranslation(id: 'web', name: 'World English Bible'),
  BibleTranslation(id: 'webbe', name: 'World English Bible, British Edition'),
  BibleTranslation(id: 'bbe', name: 'Bible in Basic English'),
  BibleTranslation(id: 'asv', name: 'American Standard Version'),
  BibleTranslation(id: 'darby', name: 'Darby Bible'),
];

/// A single numbered verse and its text.
class BibleVerse {
  final int verse;
  final String text;

  const BibleVerse({required this.verse, required this.text});

  /// Builds a [BibleVerse] from the raw JSON returned by bible-api.com.
  factory BibleVerse.fromJson(Map<String, dynamic> json) => BibleVerse(
        verse: json['verse'] as int,
        text: (json['text'] as String).trim(),
      );
}

/// A single chapter, identified by (translationId, bookId, chapter) — the
/// same triple used as the cache key and the bookmark/highlight target.
class BibleChapter {
  final String translationId;
  final String bookId;
  final String bookName;
  final int chapter;
  final List<BibleVerse> verses;

  const BibleChapter({
    required this.translationId,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verses,
  });

  /// Builds a [BibleChapter] from bible-api.com's chapter-fetch response.
  /// [translationId] is passed in separately because the API response
  /// itself doesn't echo back which translation was requested.
  factory BibleChapter.fromApiJson(Map<String, dynamic> json, String translationId) {
    final verseRows = json['verses'] as List;
    final first = verseRows.first as Map<String, dynamic>;
    return BibleChapter(
      translationId: translationId,
      bookId: first['book_id'] as String,
      bookName: first['book_name'] as String,
      chapter: first['chapter'] as int,
      verses: verseRows
          .map((v) => BibleVerse.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Human-readable reference for display, e.g. "John 3".
  String get reference => '$bookName $chapter';
}

/// A user's saved "come back to this chapter" bookmark, stored in
/// Supabase's `bible_bookmarks` table.
class BibleBookmark {
  final String id;
  final String translationId;
  final String bookId;
  final String bookName;
  final int chapter;
  final DateTime createdAt;

  const BibleBookmark({
    required this.id,
    required this.translationId,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.createdAt,
  });

  /// Human-readable reference for display, e.g. "John 3".
  String get reference => '$bookName $chapter';

  /// Builds a [BibleBookmark] from a Supabase row.
  factory BibleBookmark.fromRow(Map<String, dynamic> row) => BibleBookmark(
        id: row['id'] as String,
        translationId: row['translation_id'] as String,
        bookId: row['book_id'] as String,
        bookName: row['book_name'] as String,
        chapter: row['chapter'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

/// A user's highlight on a single verse, stored in Supabase's
/// `bible_highlights` table.
class BibleHighlight {
  final String id;
  final String translationId;
  final String bookId;
  final int chapter;
  final int verse;
  /// Highlight color name (e.g. 'yellow') — interpreted by the reader UI.
  final String color;

  const BibleHighlight({
    required this.id,
    required this.translationId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.color,
  });

  /// Builds a [BibleHighlight] from a Supabase row.
  factory BibleHighlight.fromRow(Map<String, dynamic> row) => BibleHighlight(
        id: row['id'] as String,
        translationId: row['translation_id'] as String,
        bookId: row['book_id'] as String,
        chapter: row['chapter'] as int,
        verse: row['verse'] as int,
        color: row['color'] as String,
      );
}
