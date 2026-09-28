import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/models/leaderboard_models.dart';

void main() {
  group('Leaderboard models', () {
    test('F-LEAD-01 overall response decodes', () {
      final json = {
        'segment': 'OVERALL',
        'season': 'LIFETIME',
        'page': 1,
        'size': 20,
        'totalPlayers': 10,
        'totalPages': 1,
        'top': [
          {
            'rank': 1,
            'displayName': 'Ava',
            'avatar': {'assetKey': 'characters/oracle', 'rarity': 'LEGENDARY'},
            'level': 5,
            'totalXp': 1000,
            'mastery': 80.0,
          }
        ],
        'entries': [
          {
            'rank': 1,
            'displayName': 'Ava',
            'avatar': {'assetKey': 'characters/oracle', 'rarity': 'LEGENDARY'},
            'level': 5,
            'totalXp': 1000,
          }
        ],
        'me': {
          'rank': 5,
          'displayName': 'Me',
          'avatar': {'assetKey': 'characters/nova_spark', 'rarity': 'INITIATE'},
          'level': 2,
          'totalXp': 500,
          'isMe': true,
        },
        'nearby': [],
        'generatedAt': '2026-09-06T10:00:00Z',
        'cacheTtlSeconds': 60,
      };
      final resp = LeaderboardResponse.fromJson(json);
      expect(resp.segment, 'OVERALL');
      expect(resp.top.length, 1);
      expect(resp.entries.length, 1);
      expect(resp.me?.rank, 5);
      expect(resp.me?.isMe, true);
      expect(resp.generatedAt, isNotNull);
    });

    test('F-LEAD-02 subject response decodes', () {
      final json = {
        'segment': 'SUBJECT',
        'season': 'LIFETIME',
        'subjectId': '11111111-1111-1111-1111-111111111101',
        'subjectName': 'Programming',
        'page': 1,
        'size': 20,
        'totalPlayers': 2,
        'totalPages': 1,
        'top': [],
        'entries': [
          {
            'rank': 1,
            'displayName': 'Bob',
            'avatar': {'assetKey': 'characters/coder', 'rarity': 'COMMON'},
            'level': 3,
            'totalXp': 0,
            'subjectXp': 500,
          }
        ],
        'me': {
          'rank': 2,
          'displayName': 'Me',
          'avatar': {'assetKey': 'characters/nova_spark', 'rarity': 'INITIATE'},
          'level': 1,
          'totalXp': 0,
          'subjectXp': 300,
          'isMe': true,
        },
        'nearby': [],
      };
      final resp = LeaderboardResponse.fromJson(json);
      expect(resp.segment, 'SUBJECT');
      expect(resp.subjectId, '11111111-1111-1111-1111-111111111101');
      expect(resp.entries.first.subjectXp, 500);
      expect(resp.me?.subjectXp, 300);
    });

    test('F-LEAD-03 pagination decodes', () {
      final json = {
        'segment': 'OVERALL',
        'season': 'LIFETIME',
        'page': 2,
        'size': 10,
        'totalPlayers': 25,
        'totalPages': 3,
        'top': [],
        'entries': [],
        'nearby': [],
      };
      final resp = LeaderboardResponse.fromJson(json);
      expect(resp.page, 2);
      expect(resp.size, 10);
      expect(resp.totalPlayers, 25);
      expect(resp.totalPages, 3);
    });

    test('F-LEAD-04 me outside current page remains supported', () {
      final json = {
        'segment': 'OVERALL',
        'season': 'LIFETIME',
        'page': 1,
        'size': 2,
        'totalPlayers': 10,
        'totalPages': 5,
        'top': [],
        'entries': [
          {'rank': 1, 'displayName': 'A', 'avatar': {'assetKey': 'a', 'rarity': 'COMMON'}, 'level': 5, 'totalXp': 1000},
          {'rank': 2, 'displayName': 'B', 'avatar': {'assetKey': 'b', 'rarity': 'COMMON'}, 'level': 4, 'totalXp': 900},
        ],
        'me': {'rank': 10, 'displayName': 'Me', 'avatar': {'assetKey': 'c', 'rarity': 'INITIATE'}, 'level': 1, 'totalXp': 100, 'isMe': true},
        'nearby': [],
      };
      final resp = LeaderboardResponse.fromJson(json);
      expect(resp.entries.length, 2);
      expect(resp.me?.rank, 10);
      expect(resp.me?.isMe, true);
    });

    test('F-LEAD-05 nearby entries decode', () {
      final json = {
        'segment': 'OVERALL',
        'season': 'LIFETIME',
        'page': 1,
        'size': 20,
        'totalPlayers': 5,
        'totalPages': 1,
        'top': [],
        'entries': [],
        'me': {'rank': 3, 'displayName': 'Me', 'avatar': {'assetKey': 'c', 'rarity': 'INITIATE'}, 'level': 2, 'totalXp': 500, 'isMe': true},
        'nearby': [
          {'rank': 2, 'displayName': 'Above', 'avatar': {'assetKey': 'a', 'rarity': 'RARE'}, 'level': 3, 'totalXp': 600},
          {'rank': 3, 'displayName': 'Me', 'avatar': {'assetKey': 'c', 'rarity': 'INITIATE'}, 'level': 2, 'totalXp': 500, 'isMe': true},
          {'rank': 4, 'displayName': 'Below', 'avatar': {'assetKey': 'b', 'rarity': 'COMMON'}, 'level': 1, 'totalXp': 400},
        ],
      };
      final resp = LeaderboardResponse.fromJson(json);
      expect(resp.nearby.length, 3);
      expect(resp.nearby[1].isMe, true);
    });

    test('F-LEAD-06 xpToNextRank null handling', () {
      final json = {
        'segment': 'OVERALL',
        'rank': 1,
        'totalXp': 1000,
        'level': 5,
        'totalPlayers': 10,
        'top': [],
      };
      final pos = LeaderboardPosition.fromJson(json);
      expect(pos.xpToNextRank, isNull);
      expect(pos.rank, 1);
    });

    test('F-LEAD-07 unknown avatar rarity does not crash', () {
      final json = {
        'rank': 1,
        'displayName': 'X',
        'avatar': {'assetKey': 'characters/unknown', 'rarity': 'MYTHIC_FUTURE'},
        'level': 1,
        'totalXp': 100,
      };
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.avatar.rarity, AvatarRarity.unknown);
      expect(entry.avatar.assetKey, 'characters/unknown');
    });
  });
}
