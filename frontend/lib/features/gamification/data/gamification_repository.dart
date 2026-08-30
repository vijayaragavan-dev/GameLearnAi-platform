import '../../../../core/models/gamification_models.dart';
import '../../../../core/network/api_client.dart';
import 'game_result_models.dart';

/// GAM-001..003 (read-only), USER-001, PROG-001/002, PROG-101/102
/// Persistent Gamification + Player Progression (frontend-only, token-sourced)
class GamificationRepository {
  GamificationRepository(this._client);

  final ApiClient _client;

  /// GAM-001..003
  Future<GamificationSummary> summary() async =>
      GamificationSummary.fromJson(await _client.getJson('/api/v1/gamification/summary'));

  /// USER-001
  Future<List<Achievement>> achievements() async {
    final list = await _client.getList('/api/v1/achievements');
    return list
        .whereType<Map<String, dynamic>>()
        .map(Achievement.fromJson)
        .toList(growable: false);
  }

  /// PROG-001
  Future<StreakState> streak() async =>
      StreakState.fromJson(await _client.getJson('/api/v1/streak'));

  /// USER-001
  Future<LearnerProfile> profile() async =>
      LearnerProfile.fromJson(await _client.getJson('/api/v1/profile'));

  /// PROG-001/002
  Future<List<TopicProgress>> progressAll() async {
    final list = await _client.getList('/api/v1/progress');
    return list
        .whereType<Map<String, dynamic>>()
        .map(TopicProgress.fromJson)
        .toList(growable: false);
  }

  /// PROG-102
  Future<TopicProgress> progressForTopic(String topicId) async =>
      TopicProgress.fromJson(await _client.getJson('/api/v1/progress/$topicId'));

  /// PROG-101: submit a game result (idempotent, client UUID guarantees no double-award)
  Future<GameResultSubmissionResponse> submitGameResult(
      GameResultSubmission submission) async {
    final json = await _client.postJson(
      '/api/v1/me/game-results',
      submission.toJson(),
    );
    return GameResultSubmissionResponse.fromJson(json);
  }

  /// PROG-102: list per-user game results
  Future<List<GameResultProgress>> listGameResults() async {
    final list = await _client.getList('/api/v1/me/game-results');
    return list
        .cast<Map<String, dynamic>>()
        .map(GameResultProgress.fromJson)
        .toList(growable: false);
  }

  /// PROG-102: per-game progress for authenticated user
  Future<GameResultProgress> gameResult(String gameType) async {
    final json =
        await _client.getJson('/api/v1/me/game-results/$gameType');
    return GameResultProgress.fromJson(json);
  }