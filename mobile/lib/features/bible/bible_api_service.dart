import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class BibleBookSummary {
  final String id;
  final String name;
  const BibleBookSummary({required this.id, required this.name});
}

/// Talks directly to bible-api.com — a free, keyless, public-domain Bible
/// text API (https://bible-api.com). No secret is involved, so unlike the
/// Paystack integration in Phase 5, there's no reason to proxy this
/// through our own backend; the mobile app calls it straight, the same
/// way the threat model's trust-boundary diagram allows for the
/// Flutter-app-to-Supabase-directly path.
class BibleApiService {
  static const _baseUrl = 'https://bible-api.com';
  final http.Client _http;

  BibleApiService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  void _checkOk(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Bible API request failed (HTTP ${response.statusCode})');
    }
  }

  Future<List<BibleBookSummary>> listBooks(String translationId) async {
    final response = await _http.get(Uri.parse('$_baseUrl/data/$translationId'));
    _checkOk(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['books'] as List)
        .map((b) => BibleBookSummary(id: b['id'] as String, name: b['name'] as String))
        .toList();
  }

  Future<int> chapterCount(String translationId, String bookId) async {
    final response = await _http.get(Uri.parse('$_baseUrl/data/$translationId/$bookId'));
    _checkOk(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['chapters'] as List).length;
  }

  Future<BibleChapter> fetchChapter({
    required String translationId,
    required String bookId,
    required int chapter,
  }) async {
    final response = await _http.get(
      Uri.parse('$_baseUrl/$bookId+$chapter?translation=$translationId'),
    );
    _checkOk(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return BibleChapter.fromApiJson(json, translationId);
  }

  void dispose() => _http.close();
}
