import '../../../core/models/leaderboard_models.dart';
import '../../../core/network/api_client.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final ApiClient _client;

  Future<LeaderboardResponse> overall({
    int page = 1,
    int size = 20,
    bool includeTop = true,
    String season = 'LIFETIME',
  }) async {
    assert(page >= 1, 'page must be >=1');
    assert(size >= 1 && size <= 50, 'size must be 1..50');
    final json = await _client.getJson(
      '/api/v1/leaderboard/overall',
      query: {
        'page': '$page',
        'size': '$size',
        'includeTop': '$includeTop',
        'season': season,
      },
    );
    return LeaderboardResponse.fromJson(json);
  }

  Future<LeaderboardResponse> subject(
    String subjectId, {
    int page = 1,
    int size = 20,
    bool includeTop = true,
    String season = 'LIFETIME',
  }) async {
    assert(subjectId.isNotEmpty, 'subjectId must not be empty');
    assert(page >= 1);
    assert(size >= 1 && size <= 50);
    final json = await _client.getJson(
      '/api/v1/leaderboard/subject/$subjectId',
      query: {
        'page': '$page',
        'size': '$size',
        'includeTop': '$includeTop',
        'season': season,
      },
    );
    return LeaderboardResponse.fromJson(json);
  }

  Future<LeaderboardPosition> myPosition({
    String segment = 'OVERALL',
    String? subjectId,
  }) async {
    final query = <String, String>{'segment': segment};
    if (subjectId != null && subjectId.isNotEmpty) query['subjectId'] = subjectId;
    final json = await _client.getJson('/api/v1/me/leaderboard-position', query: query);
    return LeaderboardPosition.fromJson(json);
  }
}
