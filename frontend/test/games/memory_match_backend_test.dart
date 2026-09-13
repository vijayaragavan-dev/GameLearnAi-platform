import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_adapters.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_validation.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/game_engine/utils/difficulty_utils.dart';
import 'package:gamelearn_app/features/games/memory_match/presentation/memory_match_screen.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';

import '../helpers/fake_backend.dart';

/// Phase 11 — Gate 4: Memory Match backend-content adapter verification.
///
/// Semantic contract under test: pairs are term<->definition from CONCEPT
/// items (topicName<->definition verbatim) — never question<->options[0].
/// `QUESTION` items withhold answers and can never enter Memory Match.
void main() {
  const subjectId = '11111111-1111-1111-1111-111111111101';
  const otherSubject = '11111111-1111-1111-1111-111111111102';
  const subjectName = 'Programming';
  const topicId = 't1';
  const topicA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01';
  const topicB = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02';

  GameContentItem concept({
    String id = 'c-1',
    String subject = subjectId,
    String subjectName = subjectName,
    String? topic = topicA,
    String topicName = 'Transactions',
    String? definition =
        'A transaction is a single unit of work. It follows ACID properties.',
    String gameType = 'memory_match',
    String difficulty = 'MEDIUM',
    String kind = 'CONCEPT',
    String? questionText,
    List<String> options = const [],
  }) =>
      GameContentItem(
        kind: kind,
        id: id,
        subjectId: subject,
        subjectName: subjectName,
        topicId: topic,
        topicName: topicName,
        unitId: null,
        gameType: gameType,
        difficulty: difficulty,
        questionText: questionText,
        options: options,
        definition: definition,
      );

  GameContentRequest dbmsRequest() => GameContentRequest.world(
        worldId: WorldId.programming,
        subjectId: subjectId,
        subjectName: 'Programming',
      );

  Map<String, dynamic> conceptJson({
    required String id,
    required String topicName,
    required String definition,
    String subject = subjectId,
    String gameType = 'memory_match',
  }) =>
      {
        'kind': 'CONCEPT',
        'id': id,
        'subjectId': subject,
        'subjectName': subjectName,
        'topicId': topicId,
        'topicName': topicName,
        'unitId': null,
        'gameType': gameType,
        'difficulty': 'EASY',
        'questionText': null,
        'options': [],
        'definition': definition,
      };

  Map<String, dynamic> topicJson() => {
        'id': topicId,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'name': 'Variables & Types',
        'description':
            'Variables store values for later use. Types describe the kind of data held.',
        'difficulty': 'EASY',
        'displayOrder': 1,
      };

  Map<String, dynamic> subjectPayload(List<Map<String, dynamic>> items) => {
        'mode': 'SUBJECT',
        'subjectId': subjectId,
        'items': items,
      };

  Map<String, dynamic> Function(http.Request) boardHandler(
      List<Map<String, dynamic>> items) {
    return (http.Request request) {
      final path = request.url.path;
      if (path.endsWith('/api/v1/game-content')) {
        expect(request.url.queryParameters['gameType'], 'memory_match');
        return {'body': subjectPayload(items)};
      }
      if (path.endsWith('/api/v1/topics/$topicId')) {
        return {'body': topicJson()};
      }
      return {
        'status': 404,
        'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
      };
    };
  }

  Widget board(List<Map<String, dynamic>> items) => fakeScope(
        child: const MaterialApp(
          home: MemoryMatchScreen(
            topicId: topicId,
            topicName: 'Variables & Types',
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
        handler: boardHandler(items),
      );

  List<Map<String, dynamic>> twoConcepts() => [
        conceptJson(
          id: 'c-1',
          topicName: 'Variables',
          definition:
              'A variable names a storage location. Its value can change during execution.',
        ),
        conceptJson(
          id: 'c-2',
          topicName: 'Types',
          definition:
              'A type defines the values an expression may take. Static typing catches errors early.',
        ),
      ];

  group('backend-first board (widget)', () {
    testWidgets('1+2+21. valid backend content builds the board first',
        (tester) async {
      await tester.pumpWidget(board(twoConcepts()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('TERM'), findsNWidgets(2));
      expect(find.textContaining('MATCHED 0 / 2'), findsOneWidget);
      // Backend term flips into view (fallback placeholder never appears).
      await tester.tap(find.text('TERM').first);
      await tester.pump(const Duration(milliseconds: 700));
      final backendTermVisible =
          find.text('Variables').evaluate().isNotEmpty ||
              find.text('Types').evaluate().isNotEmpty;
      expect(backendTermVisible, isTrue);
      expect(find.textContaining('Key concept of'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. flip + match mechanics work on backend cards',
        (tester) async {
      await tester.pumpWidget(board(twoConcepts()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // The first flip targets a TERM back, so its mate is one of the two
      // DEF backs. Grid order is stable and flipped-back cards return to
      // position, so re-flipping the first TERM and trying each DEF finds
      // the mate within 2 attempts.
      var matched = false;
      for (var mateIndex = 0; mateIndex < 2 && !matched; mateIndex++) {
        final terms = find.text('TERM');
        if (terms.evaluate().isEmpty) break;
        await tester.tap(terms.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
        final defs = find.text('DEF');
        if (defs.evaluate().length <= mateIndex) break;
        await tester.tap(defs.at(mateIndex), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 1400));
        matched =
            find.textContaining('MATCHED 1 / 2').evaluate().isNotEmpty;
      }
      expect(matched, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('22. scope violation fails hard, never substituted',
        (tester) async {
      await tester.pumpWidget(
        board([
          conceptJson(
            id: 'c-x',
            topicName: 'Variables',
            definition: 'Foreign content that must never play here.',
            subject: otherSubject,
          ),
        ]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Unable to start'), findsOneWidget);
      expect(find.text('TERM'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. transport failure falls back explicitly, never crashes',
        (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: MemoryMatchScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
          handler: (http.Request request) {
            final path = request.url.path;
            if (path.endsWith('/api/v1/game-content')) {
              return {
                'status': 500,
                'body': {'errorCode': 'SERVER_ERROR'},
              };
            }
            if (path.endsWith('/api/v1/topics/$topicId/lesson')) {
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            }
            if (path.endsWith('/api/v1/quiz/$topicId')) {
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            }
            if (path.endsWith('/api/v1/topics/$topicId')) {
              return {
                'body': {
                  'id': topicId,
                  'subjectId': subjectId,
                  'subjectName': subjectName,
                  'name': 'Variables & Types',
                  'description':
                      'Variables store values for later use. Types describe the kind of data held.',
                  'difficulty': 'EASY',
                  'displayOrder': 1,
                },
              };
            }
            return {
              'status': 404,
              'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
            };
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Explicit topic-description fallback board (2 sentence pairs).
      expect(find.text('TERM'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('long backend definitions lay out without overflow',
        (tester) async {
      final longDef = List.filled(
          4, 'A variable names a storage location with block scope').join(' ');
      await tester.pumpWidget(
        board([
          conceptJson(id: 'c-1', topicName: 'Variables', definition: longDef),
          conceptJson(
            id: 'c-2',
            topicName: 'Types',
            definition:
                'A type defines the values an expression may take. Static typing catches errors early.',
          ),
        ]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('TERM'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('adapter semantics (unit)', () {
    test('2. valid content produces valid pairs in backend order', () {
      final pairs = GameContentAdapters.memoryPairsFromItems(
        items: [
          concept(),
          concept(
            id: 'c-2',
            topicName: 'Normalization',
            definition:
                'Normalization organizes data to reduce redundancy. First normal form helps.',
          ),
        ],
        request: dbmsRequest(),
        gameType: 'memory_match',
      );
      expect(pairs.length, 2);
      expect(pairs[0].term, 'Transactions');
      expect(pairs[1].term, 'Normalization');
    });

    test('3. pair/card identity is stable and deterministic', () {
      List<({String term, String definition})> run() =>
          GameContentAdapters.memoryPairsFromItems(
            items: [concept(), concept(id: 'c-2', topicName: 'Other')],
            request: dbmsRequest(),
            gameType: 'memory_match',
          );
      final first = run();
      final second = run();
      expect(second.map((p) => p.term), first.map((p) => p.term));
      expect(second.map((p) => p.definition), first.map((p) => p.definition));
    });

    test('4. semantic relationship is topicName<->definition verbatim', () {
      const rawDef =
          'A transaction is a single unit of work. It follows ACID properties.';
      final pairs = GameContentAdapters.memoryPairsFromItems(
        items: [concept(definition: rawDef), concept(id: 'c-2', topicName: 'N')],
        request: dbmsRequest(),
        gameType: 'memory_match',
      );
      expect(pairs[0].term, 'Transactions');
      expect(pairs[0].definition, rawDef);
    });

    test('5+6+7. subject/topic/gameType agreement enforced by ID', () {
      // Wrong subject / wrong topic / wrong game are skipped, never repaired.
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(),
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNull,
      );
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(subject: otherSubject),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(topic: topicB),
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(gameType: 'quiz_battle'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('9+10. memory_match accepted; incompatible games rejected', () {
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(),
          expectedSubjectId: subjectId,
        ),
        isNull,
      );
      for (final other in ['quiz_battle', 'speed_run', 'drag_drop']) {
        expect(
          GameContentValidation.validateMemoryPairItem(
            item: concept(gameType: other),
            expectedSubjectId: subjectId,
          ),
          isNotNull,
          reason: other,
        );
      }
      // Non-CONCEPT kinds can never enter, even with the right gameType.
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(kind: 'QUESTION', definition: null),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('13. same topic name under another subject fails ID validation', () {
      final foreign = concept(subject: otherSubject, topic: topicB);
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: foreign,
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNotNull,
      );
    });

    test('14+15+16. EASY/MEDIUM/HARD accepted', () {
      for (final d in ['EASY', 'medium', 'Hard']) {
        expect(
          GameContentValidation.validateMemoryPairItem(
            item: concept(difficulty: d),
            expectedSubjectId: subjectId,
          ),
          isNull,
          reason: d,
        );
      }
    });

    test('17. unknown difficulty never becomes EASY', () {
      expect(DifficultyUtils.tryParseBackend('EXTREME'), isNull);
      expect(DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME'), isNull);
      final resolved =
          DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME') ??
              GameDifficulty.medium;
      expect(resolved, GameDifficulty.medium);
      expect(resolved, isNot(GameDifficulty.easy));
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(difficulty: 'EXTREME'),
          expectedSubjectId: subjectId,
        ),
        contains('never defaulted'),
      );
    });

    test('18+24. malformed/empty sides skipped; shortage fails safely', () {
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(topicName: '  '),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(definition: ''),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [concept(definition: '  ')],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('19. empty backend content handled safely (no crash, no pairs)', () {
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: const [],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('23. duplicate topic names deduplicated first-wins', () {
      final pairs = GameContentAdapters.memoryPairsFromItems(
        items: [
          concept(definition: 'First definition wins here.'),
          concept(id: 'c-9', definition: 'Second definition loses here.'),
          concept(id: 'c-2', topicName: 'Other'),
        ],
        request: dbmsRequest(),
        gameType: 'memory_match',
      );
      expect(pairs.length, 2);
      expect(pairs[0].definition, contains('First'));
    });

    test('8. difficulty contract preserved (strict topic difficulty)', () {
      // Board sizing + timer + preview all key off the strict topic
      // difficulty: EASY/MEDIUM/HARD pass through, unknown falls back to
      // MEDIUM explicitly (screen-level), never EASY.
      expect(
        DifficultyUtils.timeLimitFor(GameDifficulty.easy, GameType.memoryMatch),
        120,
      );
      expect(
        DifficultyUtils.timeLimitFor(
            GameDifficulty.medium, GameType.memoryMatch),
        90,
      );
      expect(
        DifficultyUtils.timeLimitFor(GameDifficulty.hard, GameType.memoryMatch),
        60,
      );
      expect(
        DifficultyUtils.resolveStrict(topicDifficulty: 'EASY'),
        GameDifficulty.easy,
      );
    });

    test('26. existing result submission contract preserved', () {
      const submission = GameResultSubmission(
        clientRequestId: '11111111-2222-4333-8444-555555555555',
        gameType: 'memory_match',
        difficulty: 'EASY',
        completed: true,
        score: 80,
        durationSeconds: 45,
        bestCombo: 2,
      );
      final json = submission.toJson();
      expect(json['gameType'], 'memory_match');
      expect(json['clientRequestId'], isNotEmpty);
      expect(json.containsKey('xpEarned'), isFalse);
    });

    test('27. audio behavior intact via silent double', () {
      final container =
          testContainer(handler: (_) => {'body': <String, dynamic>{}});
      expect(container.read(audioManagerProvider).sfxEnabled, isA<bool>());
      container.dispose();
    });
  });

  group('adversarial semantics (unit)', () {
    test('S1. TCP options[0] is NEVER paired (QUESTION kind rejected)', () {
      final tcp = concept(
        id: 'q-tcp',
        kind: 'QUESTION',
        gameType: 'memory_match',
        topicName: 'What is TCP?',
        definition: null,
        questionText: 'What is TCP?',
        options: const [
          'Transmission Control Protocol',
          'HyperText Transfer Protocol',
          'User Datagram Protocol',
          'File Transfer Protocol',
        ],
      );
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: tcp,
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [tcp, concept(id: 'c-2', topicName: 'Other')],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('S2. same display text, different IDs: no Q&A pairing', () {
      GameContentItem q(String id) => concept(
            id: id,
            kind: 'QUESTION',
            gameType: 'memory_match',
            topicName: 'What is TCP?',
            definition: null,
            questionText: 'What is TCP?',
            options: const ['Transmission Control Protocol', 'Other'],
          );
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [q('q-1'), q('q-2')],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('S3. same topic name, different subjects: IDs decide', () {
      final local = concept(topic: topicA);
      final foreign = concept(
        id: 'c-f',
        subject: otherSubject,
        subjectName: 'Computer Networks',
        topic: topicB,
      );
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: local,
          expectedSubjectId: subjectId,
        ),
        isNull,
      );
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: foreign,
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('S4+S6. missing/empty pair sides rejected', () {
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(topicName: ''),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateMemoryPairItem(
          item: concept(definition: null),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('S5. duplicate valid topics collapse; shortage fails closed', () {
      expect(
        () => GameContentAdapters.memoryPairsFromItems(
          items: [
            concept(definition: 'Definition one is here.'),
            concept(id: 'c-9', definition: 'Definition two is here.'),
          ],
          request: dbmsRequest(),
          gameType: 'memory_match',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('S7. legacy parser danger documented; strict path used instead', () {
      expect(GameDifficulty.fromString('weird'), GameDifficulty.easy);
      expect(DifficultyUtils.tryParseBackend('weird'), isNull);
    });
  });
}
