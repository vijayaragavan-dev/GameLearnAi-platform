import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_adapters.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';
import 'package:gamelearn_app/features/game_engine/data/game_content_repository.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/games/debug_arena/data/debug_challenges.dart';
import 'package:gamelearn_app/features/games/unlock_code/data/unlock_challenges.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';

/// Phase 11 adapter + adversarial tests.
///
/// Every migrated game must prove: valid backend content maps, metadata is
/// preserved, mismatches/malformed content are rejected, empty content is
/// safe, and no static content silently replaces backend content.
void main() {
  const dbms = '11111111-1111-1111-1111-111111111101';
  const os = '11111111-1111-1111-1111-111111111102';
  const cnTopic = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa09';
  const txnTopic = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01';

  GameContentItem concept({
    required String id,
    required String subjectId,
    String subjectName = 'Database Management Systems',
    String? topicId = txnTopic,
    String topicName = 'Transactions',
    String definition =
        'A transaction is a single unit of work. It follows ACID properties. Either all operations commit or all roll back.',
    String gameType = 'memory_match',
    String difficulty = 'MEDIUM',
    String kind = 'CONCEPT',
  }) =>
      GameContentItem(
        kind: kind,
        id: id,
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicId,
        topicName: topicName,
        unitId: null,
        gameType: gameType,
        difficulty: difficulty,
        questionText: null,
        options: const [],
        definition: definition,
      );

  GameContentRequest dbmsRequest({String? topicId, String? gameType}) =>
      GameContentRequest.world(
        worldId: WorldId.dbms,
        subjectId: dbms,
        subjectName: 'Database Management Systems',
        topicId: topicId,
      );

  group('Memory adapter (CONCEPT → pairs)', () {
    test('valid backend content maps with metadata preserved', () {
      final pairs = GameContentAdapters.memoryPairsFromItems(
        items: [
          concept(id: 'c-1', subjectId: dbms),
          concept(
            id: 'c-2',
            subjectId: dbms,
            topicName: 'Normalization',
            definition:
                'Normalization organizes data to reduce redundancy. First normal form eliminates repeating groups.',
          ),
        ],
        request: dbmsRequest(),
        gameType: 'memory_match',
      );
      expect(pairs.length, 2);
      // Term = authoritative topic name; definition verbatim, order kept.
      expect(pairs[0].term, 'Transactions');
      expect(pairs[0].definition, contains('ACID'));
      expect(pairs[1].term, 'Normalization');
    });

    test('duplicate topic names de-duplicated (first wins)', () {
      final pairs = GameContentAdapters.memoryPairsFromItems(
        items: [
          concept(id: 'c-1', subjectId: dbms),
          concept(id: 'c-9', subjectId: dbms),
          concept(id: 'c-2', subjectId: dbms, topicName: 'Other'),
        ],
        request: dbmsRequest(),
        gameType: 'memory_match',
        minPairs: 2,
      );
      expect(pairs.length, 2);
      expect(pairs[0].term, 'Transactions');
    });

    test('maxPairs caps deterministically in backend order', () {
      final pairs = GameContentAdapters.memoryPairsFromItems(
        items: [
          for (var i = 0; i < 5; i++)
            concept(
              id: 'c-$i',
              subjectId: dbms,
              topicName: 'Topic $i',
            ),
        ],
        request: dbmsRequest(),
        gameType: 'memory_match',
        minPairs: 2,
        maxPairs: 3,
      );
      expect(pairs.length, 3);
      expect(pairs[0].term, 'Topic 0');
      expect(pairs[2].term, 'Topic 2');
    });

    test('insufficient valid pairs throws (empty-safe upstream)', () {
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [concept(id: 'c-1', subjectId: dbms)],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: const [],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('empty definition rejected per item', () {
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [
            concept(id: 'c-1', subjectId: dbms, definition: '   '),
            concept(id: 'c-2', subjectId: dbms, definition: ''),
          ],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });
  });

  group('Drag adapter (STRUCTURE → zones + items)', () {
    GameContentItem structure({
      required String id,
      required String subjectId,
      String topicName = 'Transactions',
      String difficulty = 'MEDIUM',
      String gameType = 'drag_drop',
    }) =>
        concept(
          id: id,
          subjectId: subjectId,
          topicName: topicName,
          difficulty: difficulty,
          gameType: gameType,
          kind: 'STRUCTURE',
        );

    test('zones follow canonical difficulty order with topic items', () {
      final payload = GameContentAdapters.dragPayloadFromItems(
        items: [
          structure(id: 's-1', subjectId: dbms, difficulty: 'HARD'),
          structure(
            id: 's-2',
            subjectId: dbms,
            topicName: 'Indexing',
            difficulty: 'EASY',
          ),
          structure(
            id: 's-3',
            subjectId: dbms,
            topicName: 'Views',
            difficulty: 'MEDIUM',
          ),
          structure(
            id: 's-4',
            subjectId: dbms,
            topicName: 'Joins',
            difficulty: 'EASY',
          ),
        ],
        request: dbmsRequest(),
        gameType: 'drag_drop',
      );
      expect(payload.zones, ['EASY', 'MEDIUM', 'HARD']);
      expect(payload.items.length, 4);
      final joins = payload.items.firstWhere((i) => i.id == 's-4');
      expect(joins.label, 'Joins');
      expect(joins.correctZone, 'EASY');
    });

    test('malformed difficulty items skipped, not guessed', () {
      expect(
        () => GameContentAdapters.dragPayloadFromItems(
          items: [
            structure(id: 's-1', subjectId: dbms, difficulty: 'NIGHTMARE'),
            structure(id: 's-2', subjectId: dbms, difficulty: ''),
            structure(id: 's-3', subjectId: dbms, difficulty: 'EASY'),
          ],
          request: dbmsRequest(),
          gameType: 'drag_drop',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('single zone rejected (needs at least 2)', () {
      expect(
        () => GameContentAdapters.dragPayloadFromItems(
          items: [
            structure(id: 's-1', subjectId: dbms, difficulty: 'EASY'),
            structure(
              id: 's-2',
              subjectId: dbms,
              topicName: 'B',
              difficulty: 'EASY',
            ),
            structure(
              id: 's-3',
              subjectId: dbms,
              topicName: 'C',
              difficulty: 'EASY',
            ),
          ],
          request: dbmsRequest(),
          gameType: 'drag_drop',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });
  });

  group('Concept-builder adapter (CONCEPT → ordered blocks)', () {
    test('definition sentences become blocks in backend order', () {
      final challenge = GameContentAdapters.conceptChallengeFromItem(
        item: concept(
          id: 'c-1',
          subjectId: dbms,
          gameType: 'concept_builder',
        ),
        request: dbmsRequest(),
        gameType: 'concept_builder',
      );
      expect(challenge.id, 'c-1');
      expect(challenge.title, 'Transactions');
      expect(challenge.blocks.length, 3);
      expect(challenge.correctOrder, ['c-1_b0', 'c-1_b1', 'c-1_b2']);
      expect(challenge.blocks[0].label, contains('single unit of work'));
      expect(challenge.explanation, contains('ACID'));
      expect(challenge.difficulty, GameDifficulty.medium);
      expect(
        challenge.isCorrect(['c-1_b0', 'c-1_b1', 'c-1_b2']),
        isTrue,
      );
      expect(challenge.isCorrect(['c-1_b1', 'c-1_b0', 'c-1_b2']), isFalse);
    });

    test('single-sentence definition rejected (impossible ordering)', () {
      expect(
        () => GameContentAdapters.conceptChallengeFromItem(
          item: concept(
            id: 'c-1',
            subjectId: dbms,
            gameType: 'concept_builder',
            definition: 'Just one short sentence here yes.',
          ),
          request: dbmsRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('malformed difficulty rejected, never defaulted', () {
      expect(
        () => GameContentAdapters.conceptChallengeFromItem(
          item: concept(
            id: 'c-1',
            subjectId: dbms,
            gameType: 'concept_builder',
            difficulty: 'EXTREME',
          ),
          request: dbmsRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('batch adapts valid, skips invalid, enforces minimum', () {
      final out = GameContentAdapters.conceptChallengesFromItems(
        items: [
          concept(id: 'c-1', subjectId: dbms, gameType: 'concept_builder'),
          concept(
            id: 'bad',
            subjectId: dbms,
            gameType: 'concept_builder',
            definition: 'x',
          ),
          concept(
            id: 'c-2',
            subjectId: dbms,
            gameType: 'concept_builder',
            topicName: 'Second',
          ),
        ],
        request: dbmsRequest(),
        gameType: 'concept_builder',
        minChallenges: 2,
        maxChallenges: 4,
      );
      expect(out.map((c) => c.id), ['c-1', 'c-2']);
      expect(
        () => GameContentAdapters.conceptChallengesFromItems(
          items: [
            concept(
              id: 'bad',
              subjectId: dbms,
              gameType: 'concept_builder',
              definition: 'x',
            ),
          ],
          request: dbmsRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });
  });

  group('Adversarial cases', () {
    test('Case 1: Programming item requested for CN topic → REJECT', () {
      const cn = '33333333-3333-3333-3333-333333333303';
      final request = GameContentRequest.world(
        worldId: WorldId.computerNetworks,
        subjectId: cn,
        subjectName: 'Computer Networks',
        topicId: cnTopic,
      );
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [
            concept(
              id: 'p-1',
              subjectId: dbms,
              subjectName: 'Programming',
              topicId: cnTopic,
            ),
            concept(id: 'p-2', subjectId: dbms, subjectName: 'Programming'),
          ],
          request: request,
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('Case 2: CN item supplied to Programming route → REJECT', () {
      const prog = '11111111-1111-1111-1111-111111111101';
      final request = GameContentRequest.world(
        worldId: WorldId.programming,
        subjectId: prog,
        subjectName: 'Programming',
        topicId: txnTopic,
      );
      expect(
        () => GameContentAdapters.dragPayloadFromItems(
          items: [
            concept(
              id: 'n-1',
              subjectId: cnSubjectOf(request),
              subjectName: 'Computer Networks',
              topicId: txnTopic,
              kind: 'STRUCTURE',
              gameType: 'drag_drop',
            ),
          ],
          request: request,
          gameType: 'drag_drop',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('Case 6: unknown gameType content never enters a game', () {
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [
            concept(id: 'c-1', subjectId: dbms, gameType: 'nope_game'),
            concept(id: 'c-2', subjectId: dbms, gameType: 'nope_game'),
          ],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
      expect(GameContentKind.fromString('BOGUS'), isNull);
    });

    test('Case 7: zero backend content → safe rejection (empty upstream)',
        () {
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: const [],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('Case 8: backend unavailable surfaces transport error', () async {
      final client = MockClient((_) async => throw http.ClientException('x'));
      final repo = GameContentRepository(ApiClient(client: client));
      expect(
        () => repo.subjectContent(subjectId: dbms, gameType: 'memory_match'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('Case 9: global mixed subjects accepted with identity kept', () {
      final global = GameContentRequest.global();
      final pairs = GameContentAdapters.memoryPairsFromItems(
        items: [
          concept(id: 'c-1', subjectId: dbms),
          concept(
            id: 'c-2',
            subjectId: os,
            subjectName: 'Operating Systems',
            topicName: 'Deadlocks',
            definition:
                'A deadlock occurs when processes wait forever. Four Coffman conditions must all hold.',
          ),
        ],
        request: global,
        gameType: 'memory_match',
      );
      expect(pairs.length, 2);
      expect(pairs[1].term, 'Deadlocks');
    });

    test('Case 10: subject-mode mixed payload rejected wholesale', () {
      final payload = GameContentPayload.fromJson({
        'mode': 'SUBJECT',
        'subjectId': dbms,
        'items': [
          {
            'kind': 'CONCEPT',
            'id': 'c-1',
            'subjectId': dbms,
            'subjectName': 'Database Management Systems',
            'topicId': txnTopic,
            'topicName': 'Transactions',
            'unitId': null,
            'gameType': 'memory_match',
            'difficulty': 'MEDIUM',
            'questionText': null,
            'options': [],
            'definition': 'Authoritative definition one. Second sentence here.',
          },
          {
            'kind': 'CONCEPT',
            'id': 'c-2',
            'subjectId': os,
            'subjectName': 'Operating Systems',
            'topicId': txnTopic,
            'topicName': 'Deadlocks',
            'unitId': null,
            'gameType': 'memory_match',
            'difficulty': 'MEDIUM',
            'questionText': null,
            'options': [],
            'definition': 'Foreign definition one. Second sentence here.',
          },
        ],
      });
      expect(
        () => WorldContentGate.validateGameContentPayload(
          payload: payload,
          request: dbmsRequest(),
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('Case 11: same topic name, different subjects → UUID decides', () {
      const prog = '11111111-1111-1111-1111-111111111101';
      final request = GameContentRequest.world(
        worldId: WorldId.programming,
        subjectId: prog,
        subjectName: 'Programming',
      );
      // Same topicName 'Transactions' under DBMS subject must not play.
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [
            concept(id: 'c-1', subjectId: dbms, topicName: 'Transactions'),
            concept(id: 'c-2', subjectId: dbms, topicName: 'Transactions B'),
          ],
          request: request,
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });
  });

  group('Static-bank answer invariants (Cases 3/4/5 at bank level)', () {
    test('unlock bank: choices non-empty, correctAnswer ∈ choices', () {
      expect(UnlockChallenges.all, isNotEmpty);
      for (final c in UnlockChallenges.all) {
        expect(c.choices.length, greaterThanOrEqualTo(2), reason: c.id);
        expect(c.choices, contains(c.correctAnswer), reason: c.id);
        expect(c.explanation.trim().isNotEmpty, isTrue, reason: c.id);
        expect(c.id.isNotEmpty, isTrue);
      }
      final ids = UnlockChallenges.all.map((c) => c.id).toSet();
      expect(ids.length, UnlockChallenges.all.length);
    });

    test('debug bank: choices non-empty, diagnosis ∈ choices', () {
      expect(DebugChallenges.all, isNotEmpty);
      for (final c in DebugChallenges.all) {
        expect(c.choices.length, greaterThanOrEqualTo(2), reason: c.id);
        expect(c.choices, contains(c.correctDiagnosis), reason: c.id);
        expect(c.explanation.trim().isNotEmpty, isTrue, reason: c.id);
      }
      final ids = DebugChallenges.all.map((c) => c.id).toSet();
      expect(ids.length, DebugChallenges.all.length);
    });
  });
}

String cnSubjectOf(GameContentRequest request) =>
    '33333333-3333-3333-3333-333333333303';
