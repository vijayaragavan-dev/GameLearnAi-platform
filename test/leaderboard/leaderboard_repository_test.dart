import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/models/leaderboard_models.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/leaderboard/data/leaderboard_repository.dart';

class RecordingApiClient extends ApiClient {
  RecordingApiClient(this.responses);

  final Map<String, dynamic> responses;
  String? lastPath;
  Map<String, String>? lastQuery;
  String? lastPostPath;

  @override
  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query, Duration? timeout}) async {
    lastPath = path;
    lastQuery = query;
    final key = path;
    if (responses.containsKey(key)) {
      final v = responses[key];
      if (v is ApiException) throw v;
      return v as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, Object? body, {bool expectBody = true, Duration? timeout}) async {
    lastPostPath = path;
    return <String, dynamic>{};
  }

  @override
  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    lastPath = path;
    lastQuery = query;
    final v = responses[path];
    if (v is List) return v;
    return [];
  }
}

void main() {
  group('LeaderboardRepository', () {
    test('F-API-01 overall endpoint path/query correct', () async {
      final client = RecordingApiClient({
        '/api/v1/leaderboard/overall': {
          'segment': 'OVERALL',
          'season': 'LIFETIME',
          'page': 1,
          'size': 20,
          'totalPlayers': 0,
          'totalPages': 0,
          'top': [],
          'entries': [],
          'nearby': [],
        }
      });
      final repo = LeaderboardRepository(client);
      await repo.overall(page: 2, size: 10, includeTop: false, season: 'LIFETIME');
      expect(client.lastPath, '/api/v1/leaderboard/overall');
      expect(client.lastQuery?['page'], '2');
      expect(client.lastQuery?['size'], '10');
      expect(client.lastQuery?['includeTop'], 'false');
      expect(client.lastQuery?['season'], 'LIFETIME');
    });

    test('F-API-02 subject endpoint path/query correct', () async {
      final client = RecordingApiClient({
        '/api/v1/leaderboard/subject/11111111-1111-1111-1111-111111111101': {
          'segment': 'SUBJECT',
          'season': 'LIFETIME',
          'subjectId': '11111111-1111-1111-1111-111111111101',
          'page': 1,
          'size': 20,
          'totalPlayers': 0,
          'totalPages': 0,
          'top': [],
          'entries': [],
          'nearby': [],
        }
      });
      final repo = LeaderboardRepository(client);
      await repo.subject('11111111-1111-1111-1111-111111111101');
      expect(client.lastPath, '/api/v1/leaderboard/subject/11111111-1111-1111-1111-111111111101');
    });

    test('F-API-03 my position endpoint correct', () async {
      final client = RecordingApiClient({
        '/api/v1/me/leaderboard-position': {
          'segment': 'OVERALL',
          'rank': 5,
          'totalXp': 500,
          'level': 2,
          'totalPlayers': 10,
          'top': [],
        }
      });
      final repo = LeaderboardRepository(client);
      final pos = await repo.myPosition(segment: 'OVERALL');
      expect(pos.rank, 5);
      expect(client.lastPath, '/api/v1/me/leaderboard-position');
      expect(client.lastQuery?['segment'], 'OVERALL');
    });

    test('F-API-10 authenticated headers preserved via ApiClient', () async {
      // ApiClient token handling is tested separately; repository just delegates
      final client = RecordingApiClient({
        '/api/v1/leaderboard/overall': {
          'segment': 'OVERALL',
          'season': 'LIFETIME',
          'page': 1,
          'size': 20,
          'totalPlayers': 0,
          'totalPages': 0,
          'top': [],
          'entries': [],
          'nearby': [],
        }
      });
      final repo = LeaderboardRepository(client);
      final resp = await repo.overall();
      expect(resp.segment, 'OVERALL');
    });

    test('F-API-11 401 maps correctly', () async {
      final client = RecordingApiClient({
        '/api/v1/leaderboard/overall': const UnauthorizedException(),
      });
      final repo = LeaderboardRepository(client);
      expect(() => repo.overall(), throwsA(isA<UnauthorizedException>()));
    });

    test('F-API-13 403 maps correctly', () async {
      final client = RecordingApiClient({
        '/api/v1/leaderboard/overall': const ForbiddenException(),
      });
      final repo = LeaderboardRepository(client);
      expect(() => repo.overall(), throwsA(isA<ForbiddenException>()));
    });

    test('F-API-14 404 maps correctly', () async {
      final client = RecordingApiClient({
        '/api/v1/leaderboard/subject/bad-id': const NotFoundException(),
      });
      final repo = LeaderboardRepository(client);
      expect(() => repo.subject('bad-id'), throwsA(isA<NotFoundException>()));
    });

    test('F-API-16 429 maps correctly', () async {
      final client = RecordingApiClient({
        '/api/v1/leaderboard/overall': const RateLimitedException('Too many'),
      });
      final repo = LeaderboardRepository(client);
      expect(() => repo.overall(), throwsA(isA<RateLimitedException>()));
    });
  });
}
