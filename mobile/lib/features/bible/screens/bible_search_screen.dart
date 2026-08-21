import 'package:flutter/material.dart';

import '../bible_api_service.dart';
import '../bible_cache.dart';
import '../bible_sync_service.dart';
import 'bible_reader_screen.dart';

/// Searches whatever this device has already downloaded — see
/// bible_cache.dart for why this doesn't hit the network.
class BibleSearchScreen extends StatefulWidget {
  final BibleApiService apiService;
  final BibleCache cache;
  final BibleSyncService syncService;

  const BibleSearchScreen({
    super.key,
    required this.apiService,
    required this.cache,
    required this.syncService,
  });

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

/// Manages the search query and results against the local offline cache.
class _BibleSearchScreenState extends State<BibleSearchScreen> {
  List<BibleSearchHit> _hits = [];
  // Whether a search has been run yet — before the first search, the
  // screen shows an explanatory hint instead of an empty results list.
  bool _searched = false;

  /// Runs a search against the locally cached (downloaded) chapters.
  Future<void> _search(String query) async {
    final hits = await widget.cache.search(query);
    setState(() {
      _hits = hits;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onSubmitted: _search,
          decoration: const InputDecoration(
            hintText: 'Search downloaded chapters…',
            border: InputBorder.none,
          ),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: !_searched
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Only chapters you\'ve already opened are searchable offline. '
                  'Open a few chapters in the reader first.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _hits.isEmpty
              ? const Center(child: Text('No matches in your downloaded chapters.'))
              : ListView.builder(
                  itemCount: _hits.length,
                  itemBuilder: (context, index) {
                    final hit = _hits[index];
                    return ListTile(
                      title: Text('${hit.chapter.reference}:${hit.verse.verse}'),
                      subtitle: Text(hit.verse.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BibleReaderScreen(
                            apiService: widget.apiService,
                            cache: widget.cache,
                            syncService: widget.syncService,
                            initialTranslationId: hit.chapter.translationId,
                            initialBookId: hit.chapter.bookId,
                            initialBookName: hit.chapter.bookName,
                            initialChapter: hit.chapter.chapter,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
