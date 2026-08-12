import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Thin wrapper around the backend API.
///
/// Deliberately minimal for Phase 0 — just enough to prove the mobile app
/// can reach the FastAPI health check. Real feature calls (directory,
/// attendance, ...) get their own methods here starting Phase 1, with auth
/// tokens attached via an interceptor-style header hook once Supabase Auth
/// is wired up.
class ApiClient {
  final EnvConfig config;
  final http.Client _http;

  ApiClient({required this.config, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  Uri _uri(String path) => Uri.parse('${config.apiBaseUrl}$path');

  Future<Map<String, dynamic>> health() async {
    final response = await _http.get(_uri('/health'));
    if (response.statusCode != 200) {
      throw ApiException(
        'Health check failed with status ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() => _http.close();
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
