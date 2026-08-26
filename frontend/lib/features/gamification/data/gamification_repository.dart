import '../../../../core/models/gamification_models.dart';
import '../../../../core/network/api_client.dart';

/// GAM-001..003 (read-only), USER-001, PROG-001/002.
class GamificationRepository {
  GamificationRepository(this._client);

  final ApiClient _client;

  Future<GamificationSummary> summary() async => GamificationSummary.fromJson(
    await _client.getJson('/api/v1/gamification/summary'),
  );

  Future<List<Achievement>> achievements() async {
    final list = await _client.getList('/api/v1/achievements');
    return list
        .whereType<Map<String, dynamic>>()
        .map(Achievement.fromJson)
        .toList(growable: false);
  }

  Future<StreakState> streak() async =>
      StreakState.fromJson(await _client.getJson('/api/v1/streak'));

  Future<LearnerProfile> profile() async =>
      LearnerProfile.fromJson(await _client.getJson('/api/v1/profile'));

  Future<List<TopicProgress>> progressAll() async {
    final list = await _client.getList('/api/v1/progress');
    return list
        .whereType<Map<String, dynamic>>()
        .map(TopicProgress.fromJson)
        .toList(growable: false);
  }

  Future<TopicProgress> progressForTopic(String topicId) async =>
      TopicProgress.fromJson(
        await _client.getJson('/api/v1/progress/$topicId'),
      );
}
