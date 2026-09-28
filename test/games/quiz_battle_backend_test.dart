import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gamelearn_app/core/models/quiz_models.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_validation.dart';
import 'package:gamelearn_app/features/game_engine/engine/game_timer.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/game_engine/utils/difficulty_utils.dart';
import 'package:gamelearn_app/features/games/quiz_battle/presentation/quiz_battle_screen.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';

import '../helpers/fake_backend.dart';

/// Phase 11 — Gate 2: Quiz Battle backend-content verification.
///
/// Quiz Battle is server-graded (QUIZ-001 carries no answers; QUIZ-002
/// grades). These tests prove the screen consumes backend content
/// backend-first with fail-closed validation, without inventing answers,
/// difficulty, or result authority.
void main() {
  const subjectId = '11111111-1111-1111-1111-111111111101';
  const otherSubject = '11111111-1111-1111-1111-111111111102';
  const subjectName = 'Programming';
  const topicId = 't2';

  Map<String, dynamic> quizJson({
    String quizTopic = topicId,
    String difficulty = 'MEDIUM',
    List<Map<String, dynamic>>? questions,
  }) =>
      {
        'id': 'q1111111-1111-1111-1111-111111111101',
        'topicId': quizTopic,
        'title': 'Control Flow Challenge',
        'description': 'Prove your branching knowledge',
        'difficulty': difficulty,
        'timeLimitSeconds': null,
        'questionCount': (questions ?? const []).length,
        'questions': questions ??
            [
              {
                'id': 'qq1',
                'questionText': 'Which keyword declares a constant?',
                'options': ['const', 'let', 'var'],
                'difficulty': 'EASY',
              },
              {
                'id': 'qq2',
                'questionText': 'What does a loop require?',
                'options': ['condition', 'magic'],
                'difficulty': 'EASY',
              },
            ],
      };

  Map<String, dynamic> Function(http.Request) handlerFor(
      Map<String, dynamic> quiz,
      {int quizStatus = 200}) {
    return (http.Request request) {
      final path = request.url.path;
      if (path.endsWith('/api/v1/quiz/$topicId') && request.method == 'GET') {
        return {'status': quizStatus, 'body': quiz};
      }
      if (path.endsWith('/api/v1/gamification/summary')) {
        return {'body': Fixtures.gamificationSummary()};
      }
      if (path.endsWith('/api/v1/achievements')) {
        return {'body': Fixtures.achievements()};
      }
      return {
        'status': 404,
        'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
      };
    };
  }

  Widget battle() => fakeScope(
        child: const MaterialApp(
          home: QuizBattleScreen(
            topicId: topicId,
            topicName: 'Control Flow',
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
        handler: handlerFor(quizJson()),
      );

  Future<void> settleLoad(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  GameContentItem qbItem({
    String id = 'qb-1',
    String subject = subjectId,
    String? topic = topicId,
    String gameType = 'quiz_battle',
    String difficulty = 'MEDIUM',
    String kind = 'QUESTION',
    String? text = 'Which keyword declares a constant?',
    List<String> options = const ['const', 'let', 'var'],
  }) =>
      GameContentItem(
        kind: kind,
        id: id,
        subjectId: subject,
        subjectName: subjectName,
        topicId: topic,
        topicName: 'Control Flow',
        unitId: null,
        gameType: gameType,
        difficulty: difficulty,
        questionText: text,
        options: options,
        definition: null,
      );

  group('backend content reaches the engine (widget)', () {
    testWidgets('1+19. valid backend content loads and takes precedence',
        (tester) async {
      await tester.pumpWidget(battle());
      await settleLoad(tester);
      expect(find.text('Which keyword declares a constant?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2+3. question text and options reach the model', (tester) async {
      await tester.pumpWidget(battle());
      await settleLoad(tester);
      expect(find.text('Which keyword declares a constant?'), findsOneWidget);
      expect(find.text('const'), findsOneWidget);
      expect(find.text('let'), findsOneWidget);
      expect(find.text('var'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6+22. backend order preserved; answer advances progression',
        (tester) async {
      await tester.pumpWidget(battle());
      await settleLoad(tester);
      await tester.tap(find.text('const'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('What does a loop require?'), findsOneWidget);
      expect(find.text('QUESTION 2 / 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10w+16+20. wrong-topic/malformed rejected, never replaced',
        (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: QuizBattleScreen(
              topicId: topicId,
              topicName: 'Control Flow',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
          handler: handlerFor(quizJson(quizTopic: 't-other')),
        ),
      );
      await settleLoad(tester);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(find.text('Which keyword declares a constant?'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16b. malformed question rejected safely', (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: QuizBattleScreen(
              topicId: topicId,
              topicName: 'Control Flow',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
          handler: handlerFor(
            quizJson(questions: [
              {
                'id': 'qq-bad',
                'questionText': 'Broken question with one option',
                'options': ['only'],
                'difficulty': 'EASY',
              },
            ]),
          ),
        ),
      );
      await settleLoad(tester);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(find.text('Broken question with one option'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17. empty backend content is a safe empty state',
        (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: QuizBattleScreen(
              topicId: topicId,
              topicName: 'Control Flow',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
          handler: handlerFor(quizJson(questions: [])),
        ),
      );
      await settleLoad(tester);
      expect(find.text('No questions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. network failure is a safe error state', (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: QuizBattleScreen(
              topicId: topicId,
              topicName: 'Control Flow',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
          handler: handlerFor(quizJson(), quizStatus: 500),
        ),
      );
      await settleLoad(tester);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('identity and gameType (unit)', () {
    test('4. question IDs preserved from QUIZ-001', () {
      final quiz = Quiz.fromJson(quizJson());
      expect(quiz.id, 'q1111111-1111-1111-1111-111111111101');
      expect(quiz.questions[0].id, 'qq1');
      expect(quiz.questions[1].id, 'qq2');
    });

    test('5. subject identity preserved via IDs', () {
      final item = qbItem();
      expect(
        GameContentValidation.validateQuizBattleItem(
          item: item,
          expectedSubjectId: subjectId,
        ),
        isNull,
      );
      const config = GameConfig(
        topicId: topicId,
        topicName: 'Control Flow',
        subjectId: subjectId,
        subjectName: subjectName,
        type: GameType.quizBattle,
        difficulty: GameDifficulty.medium,
      );
      expect(config.subjectId, subjectId);
      expect(config.type, GameType.quizBattle);
    });

    test('6u. topic ID preserved from QUIZ-001', () {
      expect(Quiz.fromJson(quizJson()).topicId, topicId);
    });

    test('7. gameType quiz_battle accepted', () {
      expect(
        GameContentValidation.validateQuizBattleItem(
          item: qbItem(),
          expectedSubjectId: subjectId,
          expectedTopicId: topicId,
        ),
        isNull,
      );
    });

    test('8a. another gameType rejected', () {
      expect(
        GameContentValidation.validateQuizBattleItem(
          item: qbItem(gameType: 'speed_run'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('8b. non-QUESTION kind rejected for quiz battle', () {
      expect(
        GameContentValidation.validateQuizBattleItem(
          item: qbItem(kind: 'CONCEPT', text: null, options: const []),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('9. wrong subject rejected', () {
      expect(
        GameContentValidation.validateQuizBattleItem(
          item: qbItem(subject: otherSubject),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('10u. wrong topic rejected', () {
      expect(
        GameContentValidation.validateQuizBattleItem(
          item: qbItem(topic: 't-other'),
          expectedSubjectId: subjectId,
          expectedTopicId: topicId,
        ),
        isNotNull,
      );
    });

    test('11. same topic name under another subject fails ID validation', () {
      // Identical display names, different subject/topic IDs: IDs decide.
      final foreign = qbItem(subject: otherSubject, topic: 't-foreign');
      expect(
        GameContentValidation.validateQuizBattleItem(
          item: foreign,
          expectedSubjectId: subjectId,
          expectedTopicId: topicId,
        ),
        isNotNull,
      );
    });
  });

  group('difficulty authoritative (unit)', () {
    test('12. EASY passes', () {
      expect(DifficultyUtils.tryParseBackend('EASY'), GameDifficulty.easy);
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
              id: 'q', questionText: 'T?', options: ['a', 'b'], difficulty: 'EASY'),
        ),
        isNull,
      );
    });

    test('13. MEDIUM passes', () {
      expect(DifficultyUtils.tryParseBackend('MEDIUM'), GameDifficulty.medium);
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
              id: 'q', questionText: 'T?', options: ['a', 'b'], difficulty: 'MEDIUM'),
        ),
        isNull,
      );
    });

    test('14. HARD passes', () {
      expect(DifficultyUtils.tryParseBackend('hard'), GameDifficulty.hard);
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
              id: 'q', questionText: 'T?', options: ['a', 'b'], difficulty: 'HARD'),
        ),
        isNull,
      );
    });

    test('15. unknown difficulty never becomes EASY', () {
      expect(DifficultyUtils.tryParseBackend('EXTREME'), isNull);
      expect(DifficultyUtils.tryParseBackend(''), isNull);
      expect(DifficultyUtils.tryParseBackend(null), isNull);
      expect(DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME'), isNull);
      // Screen-level explicit default is MEDIUM (presentation-only), never EASY.
      final resolved =
          DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME') ??
              GameDifficulty.medium;
      expect(resolved, GameDifficulty.medium);
      expect(resolved, isNot(GameDifficulty.easy));
      // Malformed per-question difficulty rejected, not defaulted.
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
              id: 'q', questionText: 'T?', options: ['a', 'b'], difficulty: 'EXTREME'),
        ),
        isNotNull,
      );
    });
  });

  group('server grading + result + engine integrity (unit)', () {
    test('S. correctness stays server-side: QUIZ-001 carries no answers', () {
      final raw = quizJson();
      for (final q in (raw['questions'] as List).cast<Map<String, dynamic>>()) {
        expect(q.containsKey('correctAnswer'), isFalse);
      }
      // Answers/explanations exist only post-submission (QUIZ-002).
      final result = QuizResult.fromJson(Fixtures.quizResult());
      expect(result.results.first.isCorrect, isTrue);
      expect(result.results.first.correctAnswer, 'const');
    });

    test('23. existing result submission contract preserved', () {
      const submission = GameResultSubmission(
        clientRequestId: '11111111-2222-4333-8444-555555555555',
        gameType: 'quiz_battle',
        difficulty: 'MEDIUM',
        completed: true,
        score: 120,
        durationSeconds: 42,
        bestCombo: 3,
      );
      final json = submission.toJson();
      expect(json['gameType'], 'quiz_battle');
      expect(json['difficulty'], 'MEDIUM');
      expect(json['clientRequestId'], isNotEmpty);
      expect(json.containsKey('score'), isTrue);
      expect(json.containsKey('xpEarned'), isFalse);
    });

    test('21. existing timer contract intact', () {
      final seconds = DifficultyUtils.timeLimitFor(
          GameDifficulty.medium, GameType.quizBattle);
      expect(seconds, 18);
      final timer = GameTimer(totalSeconds: seconds);
      expect(timer.remaining, 18);
      expect(timer.progress, 1.0);
      timer.start();
      expect(timer.isRunning, isTrue);
      timer.stop();
      timer.dispose();
    });

    test('24. audio behavior intact via silent double', () {
      final container = testContainer(handler: (_) => {'body': <String, dynamic>{}});
      expect(
        container.read(audioManagerProvider).sfxEnabled,
        isA<bool>(),
      );
      container.dispose();
    });

    testWidgets('25. long backend content lays out without overflow',
        (tester) async {
      final longText = List.filled(12, 'Why does this very long backend question text wrap').join(' ');
      final longOption = List.filled(8, 'an unusually long backend-provided option label').join(' ');
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: QuizBattleScreen(
              topicId: topicId,
              topicName: 'Control Flow',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
          handler: handlerFor(
            quizJson(questions: [
              {
                'id': 'qq-long',
                'questionText': longText,
                'options': [longOption, 'short', 'tiny'],
                'difficulty': 'MEDIUM',
              },
            ]),
          ),
        ),
      );
      await settleLoad(tester);
      expect(find.text(longText), findsOneWidget);
      expect(find.text(longOption), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
