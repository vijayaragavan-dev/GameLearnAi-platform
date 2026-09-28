import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_adapters.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_validation.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/game_engine/utils/difficulty_utils.dart';
import 'package:gamelearn_app/features/games/concept_builder/presentation/concept_builder_screen.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';

import '../helpers/fake_backend.dart';

/// Phase 11 — Gate 6: Concept Builder backend-content adapter verification.
///
/// Semantic contract under test: blocks are the backend definition's own
/// sentences in the definition's own order (correctOrder = definition
/// order) — never MCQ options or question text repurposed as blocks.
void main() {
  const subjectId = '11111111-1111-1111-1111-111111111101';
  const otherSubject = '11111111-1111-1111-1111-111111111102';
  const subjectName = 'Programming';
  const topicId = 't1';
  const topicA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01';
  const topicB = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02';
  const definition =
      'A transaction groups database operations together. '
      'All operations commit as one unit always. '
      'Failures roll every change back safely.';
  const s1 = 'A transaction groups database operations together';
  const s2 = 'All operations commit as one unit always';
  const s3 = 'Failures roll every change back safely';

  GameContentItem concept({
    String id = 'cc-1',
    String subject = subjectId,
    String? topic = topicA,
    String topicName = 'Transactions',
    String? definition = definition,
    String gameType = 'concept_builder',
    String difficulty = 'MEDIUM',
    String kind = 'CONCEPT',
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
        questionText: null,
        options: const [],
        definition: definition,
      );

  GameContentRequest progRequest() => GameContentRequest.world(
        worldId: WorldId.programming,
        subjectId: subjectId,
        subjectName: subjectName,
      );

  Map<String, dynamic> conceptJson({
    required String id,
    String? definition = definition,
    String subject = subjectId,
    String gameType = 'concept_builder',
  }) =>
      {
        'kind': 'CONCEPT',
        'id': id,
        'subjectId': subject,
        'subjectName': subjectName,
        'topicId': topicId,
        'topicName': 'Transactions',
        'unitId': null,
        'gameType': gameType,
        'difficulty': 'MEDIUM',
        'questionText': null,
        'options': [],
        'definition': definition,
      };

  Widget board(List<Map<String, dynamic>> items) => fakeScope(
        child: const MaterialApp(
          home: ConceptBuilderScreen(
            topicId: topicId,
            topicName: 'Transactions',
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
        handler: (http.Request request) {
          final path = request.url.path;
          if (path.endsWith('/api/v1/game-content')) {
            expect(request.url.queryParameters['gameType'], 'concept_builder');
            return {
              'body': {'mode': 'SUBJECT', 'subjectId': subjectId, 'items': items},
            };
          }
          return {
            'status': 404,
            'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
          };
        },
      );

  group('backend-first challenge (widget)', () {
    testWidgets('valid backend definition builds the challenge first',
        (tester) async {
      await tester.pumpWidget(board([conceptJson(id: 'cc-1')]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Transactions'), findsWidgets);
      expect(find.text('BUILD 1 / 1'), findsOneWidget);
      expect(find.text('AVAILABLE BLOCKS'), findsOneWidget);
      expect(find.text('BUILD CONCEPT'), findsOneWidget);
      expect(find.text(s1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping blocks in definition order solves the build',
        (tester) async {
      await tester.pumpWidget(board([conceptJson(id: 'cc-1')]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      for (final sentence in [s1, s2, s3]) {
        await tester.ensureVisible(find.text(sentence));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text(sentence));
        await tester.pump();
      }
      await tester.ensureVisible(find.text('BUILD CONCEPT'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('BUILD CONCEPT'));
      await tester.pump();
      expect(find.text('BUILD COMPLETE ✓'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scope violation fails hard, never substituted',
        (tester) async {
      await tester.pumpWidget(
        board([conceptJson(id: 'cc-x', subject: otherSubject)]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Unable to start'), findsOneWidget);
      expect(find.text('Transactions'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('insufficient backend falls back to explicit static bank',
        (tester) async {
      await tester.pumpWidget(
        board([conceptJson(id: 'cc-1', definition: 'Too short.')]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Explicit world-scoped static fallback (deterministic first session).
      expect(find.text('Build a FOR loop'), findsOneWidget);
      expect(find.text('Transactions'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('adapter semantics (unit)', () {
    test('blocks are definition sentences in definition order', () {
      final challenge = GameContentAdapters.conceptChallengeFromItem(
        item: concept(),
        request: progRequest(),
        gameType: 'concept_builder',
      );
      expect(challenge.title, 'Transactions');
      expect(challenge.blocks.map((b) => b.label), [s1, s2, s3]);
      expect(
        challenge.correctOrder,
        challenge.blocks.map((b) => b.id).toList(),
      );
      expect(challenge.explanation, definition);
      expect(challenge.difficulty, GameDifficulty.medium);
    });

    test('assembly semantics: exact order correct, anything else wrong', () {
      final challenge = GameContentAdapters.conceptChallengeFromItem(
        item: concept(),
        request: progRequest(),
        gameType: 'concept_builder',
      );
      expect(challenge.isCorrect(challenge.correctOrder), isTrue);
      expect(
        challenge.isCorrect(challenge.correctOrder.reversed.toList()),
        isFalse,
      );
      expect(
        challenge.isCorrect(challenge.correctOrder.sublist(0, 2)),
        isFalse,
      );
    });

    test('subject/topic/gameType agreement enforced by ID', () {
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(),
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNull,
      );
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(subject: otherSubject),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(topic: topicB),
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(gameType: 'memory_match'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(kind: 'STRUCTURE'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('same topic name under another subject fails ID validation', () {
      final foreign = concept(subject: otherSubject, topic: topicB);
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: foreign,
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNotNull,
      );
    });

    test('EASY/MEDIUM/HARD accepted; unknown never EASY', () {
      for (final d in ['EASY', 'medium', 'Hard']) {
        final challenge = GameContentAdapters.conceptChallengeFromItem(
          item: concept(difficulty: d),
          request: progRequest(),
          gameType: 'concept_builder',
        );
        expect(challenge.difficulty.apiValue, d.toUpperCase());
      }
      expect(DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME'), isNull);
      expect(
        () => GameContentAdapters.conceptChallengeFromItem(
          item: concept(difficulty: 'EXTREME'),
          request: progRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('malformed/empty/insufficient content fails safely', () {
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(topicName: '  '),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      // Single-sentence definition yields < 2 blocks -> rejected.
      expect(
        () => GameContentAdapters.conceptChallengeFromItem(
          item: concept(definition: 'Only one sentence here.'),
          request: progRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
      // Empty definition -> rejected.
      expect(
        () => GameContentAdapters.conceptChallengeFromItem(
          item: concept(definition: '  '),
          request: progRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
      // Empty batch -> rejected safely.
      expect(
        () => GameContentAdapters.conceptChallengesFromItems(
          items: const [],
          request: progRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('batch preserves backend order up to the cap', () {
      final challenges = GameContentAdapters.conceptChallengesFromItems(
        items: [
          concept(id: 'cc-1', topicName: 'Alpha'),
          concept(id: 'cc-2', topicName: 'Beta'),
        ],
        request: progRequest(),
        gameType: 'concept_builder',
      );
      expect(challenges.map((c) => c.id), ['cc-1', 'cc-2']);
      expect(challenges.map((c) => c.title), ['Alpha', 'Beta']);
    });

    test('result submission contract preserved', () {
      const submission = GameResultSubmission(
        clientRequestId: '11111111-2222-4333-8444-555555555555',
        gameType: 'concept_builder',
        difficulty: 'MEDIUM',
        completed: true,
        score: 70,
        durationSeconds: 90,
        bestCombo: 1,
      );
      final json = submission.toJson();
      expect(json['gameType'], 'concept_builder');
      expect(json['clientRequestId'], isNotEmpty);
      expect(json.containsKey('xpEarned'), isFalse);
    });

    test('timer contract intact', () {
      expect(
        DifficultyUtils.timeLimitFor(
            GameDifficulty.medium, GameType.conceptBuilder),
        150,
      );
    });

    test('audio behavior intact via silent double', () {
      final container =
          testContainer(handler: (_) => {'body': <String, dynamic>{}});
      expect(container.read(audioManagerProvider).sfxEnabled, isA<bool>());
      container.dispose();
    });
  });

  group('adversarial semantics (unit)', () {
    test('MCQ options never become blocks', () {
      const mcq = GameContentItem(
        kind: 'QUESTION',
        id: 'q-tcp',
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicA,
        topicName: 'What is TCP?',
        unitId: null,
        gameType: 'concept_builder',
        difficulty: 'MEDIUM',
        questionText: 'What is TCP?',
        options: ['Transmission Control Protocol', 'HTTP'],
        definition: null,
      );
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: mcq,
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        () => GameContentAdapters.conceptChallengesFromItems(
          items: [mcq],
          request: progRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('question text never becomes a block or title', () {
      const mcq = GameContentItem(
        kind: 'QUESTION',
        id: 'q-1',
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicA,
        topicName: 'Topic',
        unitId: null,
        gameType: 'concept_builder',
        difficulty: 'EASY',
        questionText: 'Sneaky question text here?',
        options: ['A', 'B'],
        definition: null,
      );
      expect(
        () => GameContentAdapters.conceptChallengeFromItem(
          item: mcq,
          request: progRequest(),
          gameType: 'concept_builder',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('same topic name, different subjects: IDs decide', () {
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(),
          expectedSubjectId: subjectId,
        ),
        isNull,
      );
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(subject: otherSubject, topic: topicB),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('unknown kind rejected', () {
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(kind: 'VIDEO'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('empty content ID rejected', () {
      expect(
        GameContentValidation.validateConceptBuilderItem(
          item: concept(id: ''),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });
  });
}
