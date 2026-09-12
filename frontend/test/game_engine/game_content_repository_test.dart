import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';
import 'package:gamelearn_app/features/game_engine/data/game_content_repository.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';

/// Phase 7: real backend game-content contracts (Batch 2, read verbatim).
///
/// Covers the per-world acceptance matrix at the repository + payload
/// validation layer. No invented endpoints, no invented fields.
void main() {
  const dbms = '11111111-1111-1111-1111-111111111101';
  const os = '11111111-1111-1111-1111-111111111102';
  const cn = '11111111-1111-1111-1111-111111111103';
  const topicTxn = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01';
  const topicIdx = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02';

  Map<String, dynamic> item({
    required String id,
    required String subjectId,
    String subjectName = 'Database Management Systems',
    String? topicId = topicTxn,
    String gameType = 'quiz_battle',
    String kind = 'QUESTION',
  }) =>
      {
        'kind': kind,
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'topicId': topicId,
        'topicName': 'Transactions',
        'unitId': null,
        'gameType': gameType,
        'difficulty': 'MEDIUM',
        'questionText': 'What does ACID stand for?',
        'options': ['Atomicity...', 'Nothing'],
        'definition': null,
      };

  Map<String, dynamic> subjectPayload(List<Map<String, dynamic>> items) => {
        'mode': 'SUBJECT',
        'subjectId': dbms,
        'items': items,
      };

  GameContentRepository repo(
    Map<String, dynamic> Function(http.Request request) handler,
  ) {
    final client = MockClient((request) async {
      final result = handler(request);
      final status = (result['status'] as num?)?.toInt() ?? 200;
      final body = result['body'];
      return http.Response(
        body is String ? body : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
    });
    return GameContentRepository(ApiClient(client: client));
  }

  GameContentRequest dbmsRequest({String? topicId}) =>
      GameContentRequest.world(
        worldId: WorldId.dbms,
        subjectId: dbms,
        subjectName: 'Database Management Systems',
        topicId: topicId,
      );

  group('GameContentRepository — verbatim contracts', () {
    test('subjectContent parses SUBJECT payload', () async {
      final repository = repo((request) {
        expect(request.url.path, '/api/v1/game-content');
        expect(request.url.queryParameters['subjectId'], dbms);
        expect(request.url.queryParameters['gameType'], 'quiz_battle');
        return {
          'body': subjectPayload([
            item(id: 'q-1', subjectId: dbms),
            item(id: 'q-2', subjectId: dbms),
          ]),
        };
      });
      final payload = await repository.subjectContent(
        subjectId: dbms,
        gameType: 'quiz_battle',
      );
      expect(payload.isSubjectMode, isTrue);
      expect(payload.items.length, 2);
      expect(payload.items.first.questionText, contains('ACID'));
      expect(payload.items.first.options.length, 2);
    });

    test('subjectContent forwards topic/difficulty/limit verbatim', () async {
      final repository = repo((request) {
        expect(request.url.queryParameters['topicId'], topicTxn);
        expect(request.url.queryParameters['difficulty'], 'HARD');
        expect(request.url.queryParameters['limit'], '5');
        return {'body': subjectPayload([item(id: 'q-1', subjectId: dbms)])};
      });
      final payload = await repository.subjectContent(
        subjectId: dbms,
        topicId: topicTxn,
        gameType: 'quiz_battle',
        difficulty: 'HARD',
        limit: 5,
      );
      expect(payload.items.single.id, 'q-1');
    });

    test('empty subjectId/gameType rejected client-side (mirrors 400)', () {
      final repository = repo((_) => {'body': subjectPayload([])});
      expect(
        () => repository.subjectContent(subjectId: '', gameType: 'quiz_battle'),
        throwsArgumentError,
      );
      expect(
        () => repository.subjectContent(subjectId: dbms, gameType: ''),
        throwsArgumentError,
      );
      expect(
        () => repository.globalContent(gameType: ''),
        throwsArgumentError,
      );
    });

    test('404 empty content surfaces as NotFoundException (honest empty)',
        () async {
      final repository = repo((_) => {
            'status': 404,
            'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
          });
      expect(
        () => repository.subjectContent(
            subjectId: dbms, gameType: 'debug_arena'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('subjectGames parses compat entries verbatim', () async {
      final repository = repo((request) {
        expect(request.url.path, '/api/v1/subjects/$dbms/games');
        return {
          'body': {
            'subjectId': dbms,
            'subjectName': 'Database Management Systems',
            'games': [
              {
                'gameType': 'quiz_battle',
                'rationale': 'MCQ backed',
                'hasContent': true,
                'contentCount': 12,
              },
              {
                'gameType': 'debug_arena',
                'rationale': 'No MCQs yet',
                'hasContent': false,
                'contentCount': 0,
              },
            ],
          },
        };
      });
      final games = await repository.subjectGames(dbms);
      expect(games.subjectName, 'Database Management Systems');
      expect(games.entryFor('quiz_battle')?.hasContent, isTrue);
      expect(games.entryFor('quiz_battle')?.contentCount, 12);
      expect(games.entryFor('debug_arena')?.hasContent, isFalse);
      expect(games.entryFor('snake_and_ladder'), isNull);
    });

    test('globalContent parses GLOBAL payload with per-item identity',
        () async {
      final repository = repo((request) {
        expect(request.url.path, '/api/v1/game-content/global');
        expect(request.url.queryParameters['gameType'], 'memory_match');
        return {
          'body': {
            'mode': 'GLOBAL',
            'subjectId': null,
            'items': [
              item(id: 'c-1', subjectId: dbms, kind: 'CONCEPT'),
              item(
                id: 'c-2',
                subjectId: os,
                subjectName: 'Operating Systems',
                kind: 'CONCEPT',
              ),
            ],
          },
        };
      });
      final payload = await repository.globalContent(gameType: 'memory_match');
      expect(payload.isGlobalMode, isTrue);
      expect(payload.subjectId, isNull);
      expect(
        payload.items.map((i) => i.subjectId).toSet(),
        {dbms, os},
      );
      // CONCEPT definitions are server-resolved, never fabricated here.
      expect(payload.items.first.kindEnum, GameContentKind.concept);
    });
  });

  group('validateGameContentPayload — Phase 7.2 pipeline', () {
    GameContentPayload payload(List<Map<String, dynamic>> items) =>
        GameContentPayload.fromJson(subjectPayload(items));

    test('DBMS accepts DBMS items; OS/CN items rejected', () {
      final ok = payload([item(id: 'q-1', subjectId: dbms)]);
      expect(
        () => WorldContentGate.validateGameContentPayload(
          payload: ok,
          request: dbmsRequest(),
        ),
        returnsNormally,
      );
      for (final foreign in [os, cn]) {
        final bad = payload([item(id: 'q-x', subjectId: foreign)]);
        expect(
          () => WorldContentGate.validateGameContentPayload(
            payload: bad,
            request: dbmsRequest(),
          ),
          throwsA(isA<GameContentScopeMismatch>()),
        );
      }
    });

    test('topic scope: matching accepted, wrong rejected', () {
      final ok = payload([item(id: 'q-1', subjectId: dbms, topicId: topicTxn)]);
      expect(
        () => WorldContentGate.validateGameContentPayload(
          payload: ok,
          request: dbmsRequest(topicId: topicTxn),
        ),
        returnsNormally,
      );
      final wrong = payload(
        [item(id: 'q-2', subjectId: dbms, topicId: topicIdx)],
      );
      expect(
        () => WorldContentGate.validateGameContentPayload(
          payload: wrong,
          request: dbmsRequest(topicId: topicTxn),
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('GLOBAL payload never satisfies a world request', () {
      final global = GameContentPayload.fromJson({
        'mode': 'GLOBAL',
        'subjectId': null,
        'items': [item(id: 'q-1', subjectId: dbms)],
      });
      expect(
        () => WorldContentGate.validateGameContentPayload(
          payload: global,
          request: dbmsRequest(),
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('payload subject header mismatch rejected', () {
      final mismatched = GameContentPayload.fromJson({
        'mode': 'SUBJECT',
        'subjectId': os,
        'items': [item(id: 'q-1', subjectId: dbms)],
      });
      expect(
        () => WorldContentGate.validateGameContentPayload(
          payload: mismatched,
          request: dbmsRequest(),
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('world-identity agreement enforced when resolvable', () {
      // Item claims DBMS subjectId but an OS-resolving name → reject.
      final sneaky = payload([
        item(
          id: 'q-9',
          subjectId: dbms,
          subjectName: 'Operating Systems',
        ),
      ]);
      expect(
        () => WorldContentGate.validateGameContentPayload(
          payload: sneaky,
          request: dbmsRequest(),
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('global requests accept mixed identities, reject identity-less', () {
      final globalReq = GameContentRequest.global();
      final mixed = GameContentPayload.fromJson({
        'mode': 'GLOBAL',
        'subjectId': null,
        'items': [
          item(id: 'c-1', subjectId: dbms),
          item(
            id: 'c-2',
            subjectId: os,
            subjectName: 'Operating Systems',
          ),
        ],
      });
      expect(
        () => WorldContentGate.validateGameContentPayload(
          payload: mixed,
          request: globalReq,
        ),
        returnsNormally,
      );
    });
  });

  group('per-world acceptance matrix (payload level)', () {
    GameContentPayload payloadFor(String subjectId, String name) =>
        GameContentPayload.fromJson({
          'mode': 'SUBJECT',
          'subjectId': subjectId,
          'items': [
            item(id: 'x-1', subjectId: subjectId, subjectName: name),
          ],
        });

    test('each world accepts own, rejects others', () {
      final matrix = {
        WorldId.dbms: ('Database Management Systems', dbms),
        WorldId.operatingSystems: ('Operating Systems', os),
        WorldId.computerNetworks: ('Computer Networks', cn),
      };
      matrix.forEach((world, record) {
        final (name, sid) = record;
        final req = GameContentRequest.world(
          worldId: world,
          subjectId: sid,
          subjectName: name,
        );
        expect(
          () => WorldContentGate.validateGameContentPayload(
            payload: payloadFor(sid, name),
            request: req,
          ),
          returnsNormally,
          reason: '$world accepts own',
        );
        for (final other in matrix.entries) {
          if (other.key == world) continue;
          expect(
            () => WorldContentGate.validateGameContentPayload(
              payload: payloadFor(other.value.$2, other.value.$1),
              request: req,
            ),
            throwsA(isA<GameContentScopeMismatch>()),
            reason: '$world rejects ${other.key}',
          );
        }
      });
    });

    test('difficulty passes through verbatim (EASY/MEDIUM/HARD preserved)',
        () async {
      final repository = repo((request) {
        expect(request.url.queryParameters['difficulty'], 'EASY');
        return {
          'body': subjectPayload([
            item(id: 'q-1', subjectId: dbms),
          ]),
        };
      });
      final payload = await repository.subjectContent(
        subjectId: dbms,
        gameType: GameType.quizBattle.id,
        difficulty: GameDifficulty.easy.apiValue,
      );
      expect(payload.items, isNotEmpty);
    });
  });
}
