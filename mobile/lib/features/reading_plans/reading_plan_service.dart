import '../../core/network/api_client.dart';
import 'models.dart';

class ReadingPlanService {
  final ApiClient _client;
  const ReadingPlanService(this._client);

  Future<List<ReadingPlan>> listPlans() async {
    final json = await _client.get('/api/v1/reading-plans');
    return (json as List).map((e) => ReadingPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ReadingPlanDay>> listDays(String planId) async {
    final json = await _client.get('/api/v1/reading-plans/$planId/days');
    return (json as List).map((e) => ReadingPlanDay.fromJson(e as Map<String, dynamic>)).toList();
  }
}
