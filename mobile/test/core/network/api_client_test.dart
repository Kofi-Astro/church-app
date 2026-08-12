import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/paged_result.dart';

const _config = EnvConfig(
  environment: AppEnvironment.dev,
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
);

void main() {
  test('attaches a bearer token when one is available', () async {
    String? capturedAuthHeader;
    final client = ApiClient(
      config: _config,
      getAccessToken: () async => 'test-token',
      httpClient: MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }),
    );

    await client.get('/health');

    expect(capturedAuthHeader, 'Bearer test-token');
  });

  test('omits the Authorization header when signed out', () async {
    String? capturedAuthHeader = 'unset';
    final client = ApiClient(
      config: _config,
      getAccessToken: () async => null,
      httpClient: MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }),
    );

    await client.get('/health');

    expect(capturedAuthHeader, isNull);
  });

  test('throws ApiException with the response detail on a non-2xx status', () async {
    final client = ApiClient(
      config: _config,
      getAccessToken: () async => null,
      httpClient: MockClient(
        (request) async => http.Response(jsonEncode({'detail': 'Insufficient role'}), 403),
      ),
    );

    expect(
      () => client.get('/api/v1/households'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.message, 'message', 'Insufficient role'),
      ),
    );
  });

  test('PagedResult.fromJson parses items and pagination metadata', () {
    final page = PagedResult.fromJson(
      {
        'items': [
          {'name': 'a'},
          {'name': 'b'},
        ],
        'total': 5,
        'limit': 2,
        'offset': 0,
      },
      (json) => json['name'] as String,
    );

    expect(page.items, ['a', 'b']);
    expect(page.total, 5);
    expect(page.hasMore, isTrue);
  });
}
