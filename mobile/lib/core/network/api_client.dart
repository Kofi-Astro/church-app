import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Thin, generic wrapper around the backend API.
///
/// Feature modules (directory, attendance, ...) build their own typed
/// service classes on top of this rather than calling http directly, so
/// this file stays a stable, dependency-free base: auth header injection,
/// JSON (de)serialization, and error handling in one place.
class ApiClient {
  final EnvConfig config;
  final http.Client _http;

  /// Returns the current Supabase access token, or null if signed out.
  /// Injected rather than imported directly so this file has no
  /// dependency on the auth package/service.
  final Future<String?> Function() getAccessToken;

  ApiClient({
    required this.config,
    required this.getAccessToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Builds the full request URL from a path + optional query params,
  /// dropping any null query values and stringifying the rest (e.g. ints,
  /// bools) since Uri query params must be strings.
  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = query == null
        ? null
        : {
            for (final entry in query.entries)
              if (entry.value != null) entry.key: entry.value.toString(),
          };
    return Uri.parse('${config.apiBaseUrl}$path').replace(
      queryParameters: (cleanQuery == null || cleanQuery.isEmpty) ? null : cleanQuery,
    );
  }

  /// Standard headers for every request: JSON content type, plus a bearer
  /// auth token when the user is signed in (omitted entirely if signed out).
  Future<Map<String, String>> _headers() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Decodes a successful (2xx) response body as JSON, or throws an
  /// [ApiException] for error responses — pulling the backend's `detail`
  /// message out of the JSON error body when present, else using the raw
  /// text.
  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String detail = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } catch (_) {
      // Non-JSON error body — fall back to the raw text above.
    }
    throw ApiException(detail, statusCode: response.statusCode);
  }

  /// Performs a GET request and returns the decoded JSON body.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _http.get(_uri(path, query), headers: await _headers());
    return _decode(response);
  }

  /// Like [get], but returns the raw response body instead of decoding it
  /// as JSON — for endpoints like the CSV export that return plain text.
  Future<String> getRaw(String path, {Map<String, dynamic>? query}) async {
    final response = await _http.get(_uri(path, query), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }
    throw ApiException(response.body, statusCode: response.statusCode);
  }

  /// Performs a POST request with an optional JSON body and returns the
  /// decoded JSON response.
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _http.post(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  /// Performs a PUT request (full update) with an optional JSON body.
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await _http.put(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  /// Performs a PATCH request (partial update) with an optional JSON body.
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await _http.patch(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  /// Returns the decoded body (null for a 204/empty response) — some
  /// DELETE endpoints return the updated resource (e.g. unpray returns
  /// the prayer request with its new count), others return nothing.
  Future<dynamic> delete(String path) async {
    final response = await _http.delete(_uri(path), headers: await _headers());
    return _decode(response);
  }

  /// Calls the backend's /health endpoint — useful for a quick "is the
  /// server reachable" check (e.g. on app startup or a settings screen).
  Future<Map<String, dynamic>> health() async => await get('/health') as Map<String, dynamic>;

  /// Releases the underlying HTTP client's resources. Call when this
  /// ApiClient is no longer needed (e.g. app teardown), not per-request.
  void dispose() => _http.close();
}

/// Thrown when the backend returns a non-2xx response. Carries the
/// human-readable error message and the HTTP status code so callers can
/// branch on it (e.g. 401 -> force sign-out) or just display [message].
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
