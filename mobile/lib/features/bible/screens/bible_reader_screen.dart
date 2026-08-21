import 'package:flutter/material.dart';

import '../bible_api_service.dart';
import '../bible_cache.dart';
import '../bible_sync_service.dart';
import '../models.dart';
import 'bible_bookmarks_screen.dart';
import 'bible_search_screen.dart';

/// Main Bible reading screen: shows one chapter's verses, lets the user
/// jump to another book/chapter/translation, bookmark the chapter, and
/// long-press a verse to highlight it. Falls back to the local offline
/// cache automatically if the live fetch fails (e.g. no connection).
class BibleReaderScreen extends StatefulWidget {
  final BibleApiService apiService;
  final BibleCache cache;
  final BibleSyncService syncService;
  // Starting book/chapter/translation to open — defaults to John 1 (KJV)
  // when opened from the main nav; callers like the bookmarks/search
  // screens pass a specific passage to jump straight to it.
  final String initialTranslationId;
  final String initialBookId;
  final String initialBookName;
  final int initialChapter;

  const BibleReaderScreen({
    super.key,
    required this.apiService,
    required this.cache,
    required this.syncService,
    this.initialTranslationId = 'kjv',
    this.initialBookId = 'JHN',
    this.initialBookName = 'John',
    this.initialChapter = 1,
  });

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

/// Manages the currently displayed passage (translation/book/chapter),
/// its fetched verse data, highlight state, and loading/error/offline
/// status.
class _BibleReaderScreenState extends State<BibleReaderScreen> {
  // Current passage coordinates — mutable because "Previous"/"Next"/"Go to
  // passage" change these in place rather than pushing a new screen.
  late String _translationId = widget.initialTranslationId;
  late String _bookId = widget.initialBookId;
  late String _bookName = widget.initialBookName;
  late int _chapter = widget.initialChapter;

  BibleChapter? _chapterData;
  // Verse numbers the current user has highlighted in this chapter.
  Set<int> _highlightedVerses = {};
  bool _loading = true;
  // True if the currently displayed chapter came from the local cache
  // (i.e. the live fetch failed) — drives the "Offline" banner.
  bool _fromCache = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches the current chapter from the live API and caches it locally;
  /// if that fails (e.g. offline), falls back to whatever cached copy
  /// exists for this exact passage, and only shows an error if neither
  /// works.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chapter = await widget.apiService.fetchChapter(
        translationId: _translationId,
        bookId: _bookId,
        chapter: _chapter,
      );
      await widget.cache.save(chapter);
      await _applyChapter(chapter, fromCache: false);
    } catch (e) {
      final cached = await widget.cache.read(
        translationId: _translationId,
        bookId: _bookId,
        chapter: _chapter,
      );
      if (cached != null) {
        await _applyChapter(cached, fromCache: true);
      } else {
        setState(() {
          _error = 'Could not load this chapter and nothing is cached offline: $e';
          _loading = false;
        });
      }
    }
  }

  /// Updates screen state with a newly loaded chapter, also pulling in
  /// this user's saved highlights for it (best-effort — a highlights
  /// fetch failure doesn't block showing the chapter text).
  Future<void> _applyChapter(BibleChapter chapter, {required bool fromCache}) async {
    Set<int> highlights = {};
    try {
      final rows = await widget.syncService.listHighlights(
        translationId: chapter.translationId,
        bookId: chapter.bookId,
        chapter: chapter.chapter,
      );
      highlights = rows.map((h) => h.verse).toSet();
    } catch (_) {
      // Highlights are a nice-to-have overlay — a failed fetch (e.g. no
      // Supabase session yet) shouldn't block reading the chapter itself.
    }

    if (!mounted) return;
    setState(() {
      _chapterData = chapter;
      _bookName = chapter.bookName;
      _highlightedVerses = highlights;
      _fromCache = fromCache;
      _loading = false;
    });
  }

  /// Switches to a different chapter number within the same book/
  /// translation (used by the Previous/Next buttons). Ignores requests
  /// below chapter 1 (there's no chapter-count check for the upper bound —
  /// an out-of-range "Next" simply fails to load and shows an error).
  void _goToChapter(int chapter) {
    if (chapter < 1) return;
    setState(() => _chapter = chapter);
    _load();
  }

  /// Adds or removes a highlight on [verse] for the current chapter,
  /// updating local state immediately and syncing the change to Supabase.
  Future<void> _toggleHighlight(int verse) async {
    final highlighted = _highlightedVerses.contains(verse);
    try {
      if (highlighted) {
        // Highlights are looked up by value, not id, in this simple flow —
        // refetch to find the row id to delete.
        final rows = await widget.syncService.listHighlights(
          translationId: _translationId,
          bookId: _bookId,
          chapter: _chapter,
        );
        final match = rows.where((h) => h.verse == verse).toList();
        for (final row in match) {
          await widget.syncService.removeHighlight(row.id);
        }
        setState(() => _highlightedVerses = _highlightedVerses.difference({verse}));
      } else {
        await widget.syncService.addHighlight(
          translationId: _translationId,
          bookId: _bookId,
          chapter: _chapter,
          verse: verse,
        );
        setState(() => _highlightedVerses = {..._highlightedVerses, verse});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save highlight: $e')));
    }
  }

  /// Saves the current chapter as a bookmark and shows a confirmation
  /// snackbar.
  Future<void> _bookmarkChapter() async {
    try {
      await widget.syncService.addBookmark(
        translationId: _translationId,
        bookId: _bookId,
        bookName: _bookName,
        chapter: _chapter,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Bookmarked $_bookName $_chapter')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not bookmark: $e')));
    }
  }

  /// Shows a dialog to pick a translation, book code, and chapter number
  /// directly, then jumps the reader to that passage. Uses a nested
  /// StatefulBuilder so the translation dropdown updates within the
  /// dialog without rebuilding the whole screen.
  Future<void> _showGoToDialog() async {
    final bookController = TextEditingController(text: _bookId);
    final chapterController = TextEditingController(text: '$_chapter');
    String translation = _translationId;

    final go = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Go to passage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: translation,
                decoration: const InputDecoration(labelText: 'Translation'),
                items: [
                  for (final t in kBibleTranslations)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: (value) => setDialogState(() => translation = value ?? translation),
              ),
              TextField(
                controller: bookController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Book code (e.g. JHN, GEN, 1SA)',
                ),
              ),
              TextField(
                controller: chapterController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chapter'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Go')),
          ],
        ),
      ),
    );

    if (go != true) return;
    final chapter = int.tryParse(chapterController.text) ?? 1;
    setState(() {
      _translationId = translation;
      _bookId = bookController.text.trim().toUpperCase();
      _chapter = chapter;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chapterData != null ? '${_chapterData!.reference} ($_translationId)' : 'Bible'),
        // Toolbar: jump to passage, search offline cache, bookmark this
        // chapter, view saved bookmarks.
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Go to passage',
            onPressed: _showGoToDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search downloaded chapters',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BibleSearchScreen(
                  apiService: widget.apiService,
                  cache: widget.cache,
                  syncService: widget.syncService,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Bookmark this chapter',
            onPressed: _bookmarkChapter,
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'View bookmarks',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BibleBookmarksScreen(
                  apiService: widget.apiService,
                  cache: widget.cache,
                  syncService: widget.syncService,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : Column(
                  children: [
                    // Offline indicator banner — only shown when the
                    // displayed chapter came from the local cache.
                    if (_fromCache)
                      Container(
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: const Text(
                          'Offline — showing a previously downloaded copy',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    // Scrollable verse list — each verse is long-press-able
                    // to toggle its highlight.
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final verse in _chapterData!.verses)
                            GestureDetector(
                              onLongPress: () => _toggleHighlight(verse.verse),
                              child: Container(
                                // Yellow tint when this verse is highlighted.
                                color: _highlightedVerses.contains(verse.verse)
                                    ? Colors.yellow.withValues(alpha: 0.35)
                                    : null,
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      // Bold verse number, then the verse
                                      // text itself.
                                      TextSpan(
                                        text: '${verse.verse} ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: verse.text),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Previous/Next chapter navigation.
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _goToChapter(_chapter - 1),
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Previous'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _goToChapter(_chapter + 1),
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
