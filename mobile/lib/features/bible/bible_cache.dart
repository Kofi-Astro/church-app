import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Local offline cache for downloaded chapters, keyed by
/// (translation, book, chapter) — this is what makes the reader usable
/// without a connection once a passage has been opened once, and gives
/// "search" something to search across without hitting the network.
class BibleCache {
  static Database? _db;

  Future<Database> _database() async {
    final existing = _db;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final db = await openDatabase(
      join(dbPath, 'bible_cache.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chapters (
            translation_id TEXT NOT NULL,
            book_id TEXT NOT NULL,
            book_name TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verses_json TEXT NOT NULL,
            cached_at TEXT NOT NULL,
            PRIMARY KEY (translation_id, book_id, chapter)
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  Future<void> save(BibleChapter chapter) async {
    final db = await _database();
    await db.insert(
      'chapters',
      {
        'translation_id': chapter.translationId,
        'book_id': chapter.bookId,
        'book_name': chapter.bookName,
        'chapter': chapter.chapter,
        'verses_json': jsonEncode(
          chapter.verses.map((v) => {'verse': v.verse, 'text': v.text}).toList(),
        ),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<BibleChapter?> read({
    required String translationId,
    required String bookId,
    required int chapter,
  }) async {
    final db = await _database();
    final rows = await db.query(
      'chapters',
      where: 'translation_id = ? AND book_id = ? AND chapter = ?',
      whereArgs: [translationId, bookId, chapter],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToChapter(rows.first);
  }

  /// Text search across every chapter this device has already downloaded.
  /// Deliberately local-only — see bible_api_service.dart for why there's
  /// no server-side full-Bible search here.
  Future<List<BibleSearchHit>> search(String query, {String? translationId}) async {
    if (query.trim().isEmpty) return [];
    final db = await _database();
    final rows = await db.query(
      'chapters',
      where: translationId != null ? 'translation_id = ?' : null,
      whereArgs: translationId != null ? [translationId] : null,
    );

    final hits = <BibleSearchHit>[];
    final needle = query.toLowerCase();
    for (final row in rows) {
      final chapter = _rowToChapter(row);
      for (final verse in chapter.verses) {
        if (verse.text.toLowerCase().contains(needle)) {
          hits.add(BibleSearchHit(chapter: chapter, verse: verse));
        }
      }
    }
    return hits;
  }

  BibleChapter _rowToChapter(Map<String, dynamic> row) {
    final versesJson = jsonDecode(row['verses_json'] as String) as List;
    return BibleChapter(
      translationId: row['translation_id'] as String,
      bookId: row['book_id'] as String,
      bookName: row['book_name'] as String,
      chapter: row['chapter'] as int,
      verses: versesJson
          .map((v) => BibleVerse(verse: v['verse'] as int, text: v['text'] as String))
          .toList(),
    );
  }
}

class BibleSearchHit {
  final BibleChapter chapter;
  final BibleVerse verse;
  const BibleSearchHit({required this.chapter, required this.verse});
}
