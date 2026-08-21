// Talks to the backend's /api/v1/reading-plans endpoints for plan
// content itself (titles, days). Per-user progress is handled
// separately by ReadingPlanProgressService (talks to Supabase directly).
import '../../core/network/api_client.dart';
import 'models.dart';

/// API wrapper for reading plan content (not progress).
class ReadingPlanService {
  final ApiClient _client;
  const ReadingPlanService(this._client);

  /// Fetches all reading plans available to the current user.
  Future<List<ReadingPlan>> listPlans() async {
    final json = await _client.get('/api/v1/reading-plans');
    return (json as List).map((e) => ReadingPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches the ordered list of days for a given plan.
  Future<List<ReadingPlanDay>> listDays(String planId) async {
    final json = await _client.get('/api/v1/reading-plans/$planId/days');
    return (json as List).map((e) => ReadingPlanDay.fromJson(e as Map<String, dynamic>)).toList();
  }
}
