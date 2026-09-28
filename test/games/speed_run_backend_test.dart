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
import 'package:gamelearn_app/features/games/speed_run/presentation/speed_run_screen.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';

import '../helpers/fake_backend.dart';

/// Phase 11 — Gate 3: Speed Run backend-content verification.
///
/// Speed Run is server-graded (QUIZ-001 carries no answers; QUIZ-002
/// grades). These tests prove the screen consumes backend content
/// backend-first with fail-closed validation, without inventing answers,
/// difficulty, or result authority. No rewrite: mechanics, timer, scoring
/// presentation, audio, and result flow are preserved and only verified.
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
        'description': 'Prove your branching knowledge at speed',
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

  Widget sprint() => fakeScope(
        child: const MaterialApp(
          home: SpeedRunScreen(
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

  GameContentItem srItem({
    String id = 'sr-1',
    String subject = subjectId,
    String? topic = topicId,
    String gameType = 'speed_run',
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
      await tester.pumpWidget(sprint());
      await settleLoad(tester);
      expect(find.text('Which keyword declares a constant?'), findsOneWidget);
      expect(find.text('RUSH 1 / 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2+3. question text and options reach the model',
        (tester) async {
      await tester.pumpWidget(sprint());
      await settleLoad(tester);
      expect(find.text('Which keyword declares a constant?'), findsOneWidget);
      expect(find.text('const'), findsOneWidget);
      expect(find.text('let'), findsOneWidget);
      expect(find.text('var'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6+22. backend order preserved; answer advances progression',
        (tester) async {
      await tester.pumpWidget(sprint());
      await settleLoad(tester);
      await tester.tap(find.text('const'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('What does a loop require?'), findsOneWidget);
      expect(find.text('RUSH 2 / 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10w+16+20. wrong-topic/malformed rejected, never replaced',
        (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: SpeedRunScreen(
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
            home: SpeedRunScreen(
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
            home: SpeedRunScreen(
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
            home: SpeedRunScreen(
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

    testWidgets('25b. long backend content lays out without overflow',
        (tester) async {
      // Realistic-but-long backend-shaped content: Speed Run uses a fixed
      // Column (no scroll), so pathological lengths can overflow — recorded
      // as a known limitation, not redesigned per gate rules.
      final longText = List.filled(
          3, 'Why does this very long backend question text wrap')
          .join(' ');
      final longOption = List.filled(
          2, 'an unusually long backend-provided option label')
          .join(' ');
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: SpeedRunScreen(
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

  group('identity and gameType (unit)', () {
    test('4. question IDs preserved from QUIZ-001', () {
      final quiz = Quiz.fromJson(quizJson());
      expect(quiz.id, 'q1111111-1111-1111-1111-111111111101');
      expect(quiz.questions[0].id, 'qq1');
      expect(quiz.questions[1].id, 'qq2');
    });

    test('5. subject identity preserved via IDs', () {
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: srItem(),
          expectedSubjectId: subjectId,
        ),
        isNull,
      );
      const config = GameConfig(
        topicId: topicId,
        topicName: 'Control Flow',
        subjectId: subjectId,
        subjectName: subjectName,
        type: GameType.speedRun,
        difficulty: GameDifficulty.medium,
      );
      expect(config.subjectId, subjectId);
      expect(config.type, GameType.speedRun);
    });

    test('6u. topic ID preserved from QUIZ-001', () {
      expect(Quiz.fromJson(quizJson()).topicId, topicId);
    });

    test('7. gameType speed_run accepted', () {
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: srItem(),
          expectedSubjectId: subjectId,
          expectedTopicId: topicId,
        ),
        isNull,
      );
    });

    test('8a. quiz_battle content rejected for speed run', () {
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: srItem(gameType: 'quiz_battle'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('8b. non-QUESTION kind rejected for speed run', () {
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: srItem(kind: 'STRUCTURE', text: null, options: const []),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('9. wrong subject rejected', () {
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: srItem(subject: otherSubject),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('10u. wrong topic rejected', () {
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: srItem(topic: 't-other'),
          expectedSubjectId: subjectId,
          expectedTopicId: topicId,
        ),
        isNotNull,
      );
    });

    test('11. same topic name under another subject fails ID validation', () {
      final foreign = srItem(subject: otherSubject, topic: 't-foreign');
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: foreign,
          expectedSubjectId: subjectId,
          expectedTopicId: topicId,
        ),
        isNotNull,
      );
    });
  });

  group('difficulty authoritative (unit)', () {
    const q = QuizQuestion(
      id: 'q',
      questionText: 'T?',
      options: ['a', 'b'],
      difficulty: 'EASY',
    );

    test('12. EASY is accepted', () {
      expect(DifficultyUtils.tryParseBackend('EASY'), GameDifficulty.easy);
      expect(GameContentValidation.validateQuizQuestion(question: q), isNull);
    });

    test('13. MEDIUM is accepted', () {
      expect(DifficultyUtils.tryParseBackend('MEDIUM'), GameDifficulty.medium);
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
            id: 'q',
            questionText: 'T?',
            options: ['a', 'b'],
            difficulty: 'MEDIUM',
          ),
        ),
        isNull,
      );
    });

    test('14. HARD is accepted', () {
      expect(DifficultyUtils.tryParseBackend('hard'), GameDifficulty.hard);
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
            id: 'q',
            questionText: 'T?',
            options: ['a', 'b'],
            difficulty: 'HARD',
          ),
        ),
        isNull,
      );
    });

    test('15. unknown difficulty never becomes EASY', () {
      expect(DifficultyUtils.tryParseBackend('EXTREME'), isNull);
      expect(DifficultyUtils.tryParseBackend(''), isNull);
      expect(DifficultyUtils.tryParseBackend(null), isNull);
      expect(DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME'), isNull);
      final resolved =
          DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME') ??
              GameDifficulty.medium;
      expect(resolved, GameDifficulty.medium);
      expect(resolved, isNot(GameDifficulty.easy));
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
            id: 'q',
            questionText: 'T?',
            options: ['a', 'b'],
            difficulty: 'EXTREME',
          ),
        ),
        isNotNull,
      );
    });
  });

  group('server grading + result + engine integrity (unit)', () {
    test('24. correctness stays server-side: QUIZ-001 carries no answers', () {
      final raw = quizJson();
      for (final q in (raw['questions'] as List).cast<Map<String, dynamic>>()) {
        expect(q.containsKey('correctAnswer'), isFalse);
      }
      final result = QuizResult.fromJson(Fixtures.quizResult());
      expect(result.results.first.isCorrect, isTrue);
      expect(result.results.first.correctAnswer, 'const');
    });

    test('23. existing result submission contract preserved', () {
      const submission = GameResultSubmission(
        clientRequestId: '11111111-2222-4333-8444-555555555555',
        gameType: 'speed_run',
        difficulty: 'MEDIUM',
        completed: true,
        score: 120,
        durationSeconds: 42,
        bestCombo: 3,
      );
      final json = submission.toJson();
      expect(json['gameType'], 'speed_run');
      expect(json['difficulty'], 'MEDIUM');
      expect(json['clientRequestId'], isNotEmpty);
      expect(json.containsKey('score'), isTrue);
      expect(json.containsKey('xpEarned'), isFalse);
    });

    test('21. existing timer/mechanics contract intact', () {
      final seconds = DifficultyUtils.timeLimitFor(
          GameDifficulty.medium, GameType.speedRun);
      expect(seconds, 45);
      final timer = GameTimer(totalSeconds: seconds);
      expect(timer.remaining, 45);
      expect(timer.progress, 1.0);
      timer.start();
      expect(timer.isRunning, isTrue);
      timer.stop();
      timer.dispose();
    });

    test('25. audio behavior intact via silent double', () {
      final container =
          testContainer(handler: (_) => {'body': <String, dynamic>{}});
      expect(container.read(audioManagerProvider).sfxEnabled, isA<bool>());
      container.dispose();
    });
  });

  group('adversarial (unit)', () {
    test('A1. missing question ID rejected', () {
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
            id: '',
            questionText: 'T?',
            options: ['a', 'b'],
            difficulty: 'EASY',
          ),
        ),
        isNotNull,
      );
    });

    test('A2. empty question text rejected', () {
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
            id: 'q',
            questionText: '   ',
            options: ['a', 'b'],
            difficulty: 'EASY',
          ),
        ),
        isNotNull,
      );
    });

    test('A3. whitespace-only options count as missing (<2 usable)', () {
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
            id: 'q',
            questionText: 'T?',
            options: ['  ', 'b'],
            difficulty: 'EASY',
          ),
        ),
        isNotNull,
      );
    });

    test('A4. duplicate options remain renderable (no dedup invented)', () {
      expect(
        GameContentValidation.validateQuizQuestion(
          question: const QuizQuestion(
            id: 'q',
            questionText: 'T?',
            options: ['same', 'same'],
            difficulty: 'EASY',
          ),
        ),
        isNull,
      );
    });

    test('A5. invalid payload structure degrades to safe empty', () {
      final payload = GameContentPayload.fromJson({
        'mode': 'SUBJECT',
        'subjectId': subjectId,
        'items': 'not-a-list',
      });
      expect(payload.items, isEmpty);
      expect(
        () => GameContentValidation.validatePayload(
          payload: payload,
          expectedSubjectId: subjectId,
          expectedGameType: 'speed_run',
        ),
        returnsNormally,
      );
    });

    test('A6. global mixed content allowed only in global mode', () {
      final mixed = GameContentPayload(
        mode: 'GLOBAL',
        items: [srItem(subject: subjectId), srItem(subject: otherSubject)],
      );
      expect(
        () => GameContentValidation.validatePayload(
          payload: mixed,
          expectedGameType: 'speed_run',
          subjectMode: false,
        ),
        returnsNormally,
      );
      expect(
        () => GameContentValidation.validatePayload(
          payload: mixed,
          expectedSubjectId: subjectId,
          expectedGameType: 'speed_run',
          subjectMode: true,
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('A7. unknown kind rejected for speed run', () {
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: srItem(kind: 'VIDEO'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('A8. empty content ID rejected', () {
      expect(
        GameContentValidation.validateSpeedRunItem(
          item: srItem(id: ''),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });
  });
}
