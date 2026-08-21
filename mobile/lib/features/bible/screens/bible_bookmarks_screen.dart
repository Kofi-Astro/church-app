import 'package:flutter/material.dart';

import '../bible_api_service.dart';
import '../bible_cache.dart';
import '../bible_sync_service.dart';
import '../models.dart';
import 'bible_reader_screen.dart';

/// Lists the current user's saved chapter bookmarks; tapping one opens
/// [BibleReaderScreen] at that chapter, and each row can be deleted.
class BibleBookmarksScreen extends StatefulWidget {
  final BibleApiService apiService;
  final BibleCache cache;
  final BibleSyncService syncService;

  const BibleBookmarksScreen({
    super.key,
    required this.apiService,
    required this.cache,
    required this.syncService,
  });

  @override
  State<BibleBookmarksScreen> createState() => _BibleBookmarksScreenState();
}

/// Manages the loaded bookmark list and its loading/error state.
class _BibleBookmarksScreenState extends State<BibleBookmarksScreen> {
  List<BibleBookmark> _bookmarks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches the current user's bookmarks from Supabase.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bookmarks = await widget.syncService.listBookmarks();
      setState(() {
        _bookmarks = bookmarks;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Deletes a bookmark and refreshes the list.
  Future<void> _remove(BibleBookmark bookmark) async {
    await widget.syncService.removeBookmark(bookmark.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _bookmarks.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No bookmarks yet.', textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = _bookmarks[index];
                          return ListTile(
                            title: Text(bookmark.reference),
                            subtitle: Text(bookmark.translationId.toUpperCase()),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _remove(bookmark),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BibleReaderScreen(
                                  apiService: widget.apiService,
                                  cache: widget.cache,
                                  syncService: widget.syncService,
                                  initialTranslationId: bookmark.translationId,
                                  initialBookId: bookmark.bookId,
                                  initialBookName: bookmark.bookName,
                                  initialChapter: bookmark.chapter,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
