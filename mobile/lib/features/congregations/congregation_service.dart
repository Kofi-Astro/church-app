// Talks to the backend's /api/v1/congregations endpoints (admin-managed
// CRUD, readable by any signed-in profile).
import '../../core/network/api_client.dart';
import 'models.dart';

/// API wrapper for congregations.
class CongregationService {
  final ApiClient _client;
  const CongregationService(this._client);

  /// Fetches every congregation, alphabetical by name.
  Future<List<Congregation>> listCongregations() async {
    final json = await _client.get('/api/v1/congregations');
    return (json as List).map((e) => Congregation.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Creates a new congregation (admin-only on the backend).
  Future<Congregation> createCongregation({required String name, String? description}) async {
    final json = await _client.post(
      '/api/v1/congregations',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    return Congregation.fromJson(json as Map<String, dynamic>);
  }

  /// Deletes a congregation (admin-only on the backend).
  Future<void> deleteCongregation(String congregationId) async {
    await _client.delete('/api/v1/congregations/$congregationId');
  }
}
