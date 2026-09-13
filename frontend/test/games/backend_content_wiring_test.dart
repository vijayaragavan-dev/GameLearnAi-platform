import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/features/games/concept_builder/presentation/concept_builder_screen.dart';
import 'package:gamelearn_app/features/games/drag_drop/presentation/drag_drop_screen.dart';
import 'package:gamelearn_app/features/games/memory_match/presentation/memory_match_screen.dart';
import 'package:gamelearn_app/features/games/quiz_battle/presentation/quiz_battle_screen.dart';

import '../helpers/fake_backend.dart';

/// Phase 11 screen-wiring tests: backend-first content with explicit
/// fallback, hard-fail scope behavior, and Quiz Battle backend regression.
///
/// Subject/world used throughout: Programming (subjectId p1) + topic t1,
/// so world-attributed static banks and backend payloads agree.
void main() {
  const subjectId = '11111111-1111-1111-1111-111111111101';
  const subjectName = 'Programming';
  const topicId = 't1';

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

  Map<String, dynamic> lessonJson() => {
        'id': 'l1',
        'topicId': topicId,
        'title': 'Variables & Types',
        'content': '',
        'summary': '',
        'difficulty': 'EASY',
        'sourceType': 'SEEDED',
      };

  Map<String, dynamic> conceptItem({
    required String id,
    required String topicName,
    required String definition,
    String gameType = 'memory_match',
  }) =>
      {
        'kind': 'CONCEPT',
        'id': id,
        'subjectId': subjectId,
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

  Map<String, dynamic> structureItem({
    required String id,
    required String topicName,
    required String difficulty,
  }) =>
      {
        'kind': 'STRUCTURE',
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'topicId': topicId,
        'topicName': topicName,
        'unitId': null,
        'gameType': 'drag_drop',
        'difficulty': difficulty,
        'questionText': null,
        'options': [],
        'definition': null,
      };

  Map<String, dynamic> subjectPayload(List<Map<String, dynamic>> items) => {
        'mode': 'SUBJECT',
        'subjectId': subjectId,
        'items': items,
      };

  group('Memory Match backend-first wiring', () {
    testWidgets('plays backend CONCEPT pairs when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: fakeScope(
            child: const MemoryMatchScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
            handler: (request) {
              final path = request.url.path;
              if (path.endsWith('/api/v1/game-content')) {
                expect(
                  request.url.queryParameters['gameType'],
                  'memory_match',
                );
                expect(
                  request.url.queryParameters['subjectId'],
                  subjectId,
                );
                return {
                  'body': subjectPayload([
                    conceptItem(
                      id: 'c-1',
                      topicName: 'Variables',
                      definition:
                          'A variable names a storage location. Its value can change during execution.',
                    ),
                    conceptItem(
                      id: 'c-2',
                      topicName: 'Types',
                      definition:
                          'A type defines the values an expression may take. Static typing catches errors early.',
                    ),
                  ]),
                };
              }
              if (path.endsWith('/api/v1/topics/$topicId')) {
                return {'body': topicJson()};
              }
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Backend pairs built: 2 pairs → 4 cards showing TERM backs.
      expect(find.text('TERM'), findsNWidgets(2));
      // Flip one card → one authoritative backend term visible. (Card order
      // after the deterministic shuffle is fixed but position-agnostic here.)
      await tester.tap(find.text('TERM').first);
      await tester.pump(const Duration(milliseconds: 700));
      final backendTermVisible =
          find.text('Variables').evaluate().isNotEmpty ||
              find.text('Types').evaluate().isNotEmpty;
      expect(backendTermVisible, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to mapper when backend is empty (404)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: fakeScope(
            child: const MemoryMatchScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
            handler: (request) {
              final path = request.url.path;
              if (path.endsWith('/api/v1/game-content')) {
                return {
                  'status': 404,
                  'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
                };
              }
              if (path.endsWith('/api/v1/topics/$topicId/lesson')) {
                return {'body': lessonJson()};
              }
              if (path.endsWith('/api/v1/quiz/$topicId')) {
                return {
                  'status': 404,
                  'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
                };
              }
              if (path.endsWith('/api/v1/topics/$topicId')) {
                return {'body': topicJson()};
              }
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mapper fallback from the topic description (2 sentences → 2 pairs).
      expect(find.text('TERM'), findsNWidgets(2));
      await tester.tap(find.text('TERM').first);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('Variables & Types'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wrong-subject backend content fails hard (no fallback)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: fakeScope(
            child: const MemoryMatchScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
            handler: (request) {
              final path = request.url.path;
              if (path.endsWith('/api/v1/game-content')) {
                return {
                  'body': subjectPayload([
                    conceptItem(
                      id: 'c-1',
                      topicName: 'Variables',
                      definition:
                          'A variable names storage. Values change over time.',
                    ),
                  ]),
                };
              }
              if (path.endsWith('/api/v1/topics/$topicId')) {
                // Topic belongs to ANOTHER subject → mismatch.
                final t = topicJson();
                t['subjectId'] =
                    '22222222-2222-2222-2222-222222222202';
                return {'body': t};
              }
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Honest hard-failure message; no cards, no fallback play.
      expect(
        find.text('That learning content is not available for this topic.'),
        findsOneWidget,
      );
      expect(find.text('TERM'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Drag & Drop backend-first wiring', () {
    testWidgets('plays backend STRUCTURE zones/items when available',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: fakeScope(
            child: const DragDropScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
            handler: (request) {
              final path = request.url.path;
              if (path.endsWith('/api/v1/game-content')) {
                expect(
                  request.url.queryParameters['gameType'],
                  'drag_drop',
                );
                return {
                  'body': subjectPayload([
                    structureItem(
                      id: 's-1',
                      topicName: 'Variables',
                      difficulty: 'EASY',
                    ),
                    structureItem(
                      id: 's-2',
                      topicName: 'Loops',
                      difficulty: 'MEDIUM',
                    ),
                    structureItem(
                      id: 's-3',
                      topicName: 'Recursion',
                      difficulty: 'HARD',
                    ),
                  ]),
                };
              }
              if (path.endsWith('/api/v1/topics/$topicId')) {
                return {'body': topicJson()};
              }
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Backend zones in canonical order with authoritative topic labels.
      expect(find.text('EASY'), findsWidgets);
      expect(find.text('MEDIUM'), findsWidgets);
      expect(find.text('HARD'), findsWidgets);
      expect(find.text('Recursion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to mapper when backend is empty (404)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: fakeScope(
            child: const DragDropScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
            handler: (request) {
              final path = request.url.path;
              if (path.endsWith('/api/v1/game-content')) {
                return {
                  'status': 404,
                  'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
                };
              }
              if (path.endsWith('/api/v1/quiz/$topicId')) {
                // Three real questions → mapper quiz path (difficulty zones).
                return {
                  'body': {
                    'id': 'q1111111-1111-1111-1111-111111111101',
                    'topicId': topicId,
                    'title': 'Variables Challenge',
                    'description': 'Prove your knowledge',
                    'difficulty': 'MEDIUM',
                    'timeLimitSeconds': null,
                    'questionCount': 3,
                    'questions': [
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
                        'difficulty': 'MEDIUM',
                      },
                      {
                        'id': 'qq3',
                        'questionText': 'What is recursion?',
                        'options': ['self-call', 'loop'],
                        'difficulty': 'HARD',
                      },
                    ],
                  },
                };
              }
              if (path.endsWith('/api/v1/topics/$topicId/lesson')) {
                return {'body': lessonJson()};
              }
              if (path.endsWith('/api/v1/topics/$topicId')) {
                return {'body': topicJson()};
              }
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mapper fallback from the real quiz: difficulty zones + questions.
      expect(find.text('EASY'), findsWidgets);
      expect(
        find.textContaining('Which keyword declares a constant?'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Concept Builder backend-first wiring', () {
    testWidgets('plays backend CONCEPT definitions as blocks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: fakeScope(
            child: const ConceptBuilderScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
            handler: (request) {
              final path = request.url.path;
              if (path.endsWith('/api/v1/game-content')) {
                expect(
                  request.url.queryParameters['gameType'],
                  'concept_builder',
                );
                return {
                  'body': subjectPayload([
                    conceptItem(
                      id: 'c-1',
                      topicName: 'Variables',
                      definition:
                          'A variable names a storage location. Its value can change during execution. Types constrain the values allowed.',
                      gameType: 'concept_builder',
                    ),
                  ]),
                };
              }
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Backend challenge: topic title + definition sentence blocks.
      expect(find.text('Variables'), findsWidgets);
      expect(
        find.textContaining('A variable names a storage location'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to static bank when backend is empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: fakeScope(
            child: const ConceptBuilderScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
            handler: (request) {
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Static Programming-attributed bank renders (existing behavior).
      expect(find.text('CONCEPT BUILDER'), findsWidgets);
      expect(find.text('AVAILABLE BLOCKS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scope-violating backend content fails hard', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: fakeScope(
            child: const ConceptBuilderScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
            handler: (request) {
              final path = request.url.path;
              if (path.endsWith('/api/v1/game-content')) {
                return {
                  'body': {
                    'mode': 'SUBJECT',
                    'subjectId':
                        '22222222-2222-2222-2222-222222222202',
                    'items': [
                      conceptItem(
                        id: 'c-1',
                        topicName: 'Variables',
                        definition:
                          'A variable names storage. Values change over time.',
                        gameType: 'concept_builder',
                      ),
                    ],
                  },
                };
              }
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('That learning content is not available for this topic.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Quiz Battle backend regression (QUIZ-001/002)', () {
    testWidgets('loads backend questions, submits, reaches result',
        (tester) async {
      // NOTE: ProviderScope wraps MaterialApp (production shape) because
      // submit navigates to the result screen via pushReplacement.
      final postedGameResults = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: QuizBattleScreen(
              topicId: 't2',
              topicName: 'Control Flow',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
          handler: (request) {
              final path = request.url.path;
              if (request.url.path.endsWith('/api/v1/quiz/t2') &&
                  request.method == 'GET') {
                return {'body': Fixtures.quiz()};
              }
              if (path.endsWith('/api/v1/quiz/q1111111-1111-1111-1111-111111111101/submit')) {
                return {'body': Fixtures.quizResult()};
              }
              if (path.endsWith('/api/v1/gamification/summary')) {
                return {'body': Fixtures.gamificationSummary()};
              }
              if (path.endsWith('/api/v1/achievements')) {
                return {'body': Fixtures.achievements()};
              }
              if (path.endsWith('/api/v1/me/game-results') &&
                  request.method == 'POST') {
                postedGameResults.add({
                  'path': path,
                  'body': request.body,
                });
                return {
                  'body': {
                    'requestId': 'r1',
                    'xpEarned': 20,
                    'previousLevel': 3,
                    'currentLevel': 3,
                    'previousTotalXp': 325,
                    'currentTotalXp': 345,
                    'leveledUp': false,
                    'levelsGained': 0,
                    'playedAt': '2026-08-24T10:15:07Z',
                    'nextLevelThresholdXp': 600,
                    'xpToNextLevel': 255,
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
      // Backend question text renders (proves QUIZ-001 drives the engine).
      expect(
        find.text('Which keyword declares a constant?'),
        findsOneWidget,
      );
      // Answer Q1 → auto-advance; answer Q2 → auto-submit → result screen.
      await tester.tap(find.text('const'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('What does a loop require?'), findsOneWidget);
      await tester.tap(find.text('condition'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      // Backend-graded result screen (QUIZ-002 correctness + PROG-101 XP).
      expect(find.text('MISSION COMPLETE'), findsOneWidget);
      expect(find.text('Control Flow'), findsWidgets);
      // PROG-101 submission actually fired with the quiz_battle contract.
      expect(postedGameResults, hasLength(1));
      expect(postedGameResults.single['body'], contains('quiz_battle'));
      expect(postedGameResults.single['body'], contains('clientRequestId'));
      expect(tester.takeException(), isNull);
    });
  });
}
