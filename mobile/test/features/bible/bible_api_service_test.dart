import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile/features/bible/bible_api_service.dart';

void main() {
  test('fetchChapter requests the right URL and parses the response', () async {
    Uri? requestedUri;
    final service = BibleApiService(
      httpClient: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'reference': 'John 3',
            'verses': [
              {'book_id': 'JHN', 'book_name': 'John', 'chapter': 3, 'verse': 1, 'text': 'Verse one'},
              {'book_id': 'JHN', 'book_name': 'John', 'chapter': 3, 'verse': 2, 'text': 'Verse two'},
            ],
          }),
          200,
        );
      }),
    );

    final chapter = await service.fetchChapter(translationId: 'kjv', bookId: 'JHN', chapter: 3);

    expect(requestedUri.toString(), 'https://bible-api.com/JHN+3?translation=kjv');
    expect(chapter.bookName, 'John');
    expect(chapter.chapter, 3);
    expect(chapter.reference, 'John 3');
    expect(chapter.verses, hasLength(2));
    expect(chapter.verses.first.text, 'Verse one');
  });

  test('throws when the API returns a non-200 status', () async {
    final service = BibleApiService(
      httpClient: MockClient((request) async => http.Response('not found', 404)),
    );

    expect(
      () => service.fetchChapter(translationId: 'kjv', bookId: 'ZZZ', chapter: 1),
      throwsException,
    );
  });
}
