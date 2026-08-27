// ignore_for_file: prefer_const_constructors, curly_braces_in_flow_control_structures
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/progress/presentation/progress_screen.dart';
import 'package:gamelearn_app/features/progress/presentation/topic_performance_screen.dart';
import 'package:gamelearn_app/shared/widgets/feedback.dart';

import '../helpers/fake_backend.dart';

Map<String, dynamic> _dashboardWithTopics(
  List<Map<String, dynamic>> topics, {
  List<Map<String, dynamic>> quizzes = const [],
}) => {
  'learner': {
    'displayName': 'Nova Player',
    'overallMastery': 62.5,
    'currentSubjectId': null,
    'currentTopicId': null,
  },
  'currentSubject': null,
  'mastery': {
    'topicsAssessed': topics.length,
    'topicsMastered': topics
        .where((t) => t['masteryLevel'] == 'MASTERED')
        .length,
    'recentTopics': topics,
  },
  'gamification': {
    'totalXp': 480,
    'currentLevel': 4,
    'maxLevel': 50,
    'nextLevelThresholdXp': 600,
    'xpToNextLevel': 120,
  },
  'streak': {
    'currentStreakDays': 7,
    'longestStreakDays': 9,
    'lastLearningDate': '2026-08-24',
    'timezone': 'UTC',
  },
  'achievements': {'unlockedCount': 2, 'recentUnlocks': []},
  'recommendations': [],
  'learningPath': null,
  'assessment': {'assessedSubjects': []},
  'recentActivity': {'quizzes': quizzes},
};

List<Map<String, dynamic>> _mixedTopics() => [
  {
    'topicId': '22222222-2222-2222-2222-222222222211',
    'topicName': 'Variables & Types',
    'masteryScore': 92,
    'masteryLevel': 'MASTERED',
    'currentDifficulty': 'HARD',
    'trend': 'IMPROVING',
    'lastAssessedAt': '2026-08-24T09:00:00Z',
  },
  {
    'topicId': '22222222-2222-2222-2222-222222222212',
    'topicName': 'Control Flow',
    'masteryScore': 78,
    'masteryLevel': 'PROFICIENT',
    'currentDifficulty': 'MEDIUM',
    'trend': 'STABLE',
    'lastAssessedAt': '2026-08-24T10:00:00Z',
  },
  {
    'topicId': '22222222-2222-2222-2222-222222222213',
    'topicName': 'Functions',
    'masteryScore': 55,
    'masteryLevel': 'DEVELOPING',
    'currentDifficulty': 'EASY',
    'trend': 'DECLINING',
    'lastAssessedAt': '2026-08-24T11:00:00Z',
  },
  {
    'topicId': '22222222-2222-2222-2222-222222222221',
    'topicName': 'SQL & Transactions',
    'masteryScore': 32,
    'masteryLevel': 'BEGINNER',
    'currentDifficulty': 'EASY',
    'trend': 'INSUFFICIENT_DATA',
    'lastAssessedAt': '2026-08-24T12:00:00Z',
  },
];

Widget _wrap(Widget child, MockClient Function() clientFactory) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(
        FakeTokenStorage()..stored = 'tok',
      ),
      apiClientProvider.overrideWith(
        (ref) => ApiClient(client: clientFactory()),
      ),
      audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressScreen Phase 4 — mastery visualization', () {
    testWidgets('loading state shows skeletons', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // Use a pending completer (no timer) to keep FutureBuilder in loading
      final pending = Completer<http.Response>();
      await tester.pumpWidget(
        _wrap(const ProgressScreen(), () => MockClient((_) => pending.future)),
      );
      await tester.pump();
      // ProgressScreen uses SkeletonList while loading
      expect(find.byType(SkeletonList), findsOneWidget);
      // Complete pending to avoid timer assertion after dispose
      pending.complete(
        http.Response(
          jsonEncode(_dashboardWithTopics([])),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('success renders overall mastery and topic mastery cards', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        _wrap(
          const ProgressScreen(),
          () => MockClient((request) async {
            final path = request.url.path;
            if (path.contains('/profile')) {
              return http.Response(
                jsonEncode({
                  'id': '11111111-1111-1111-1111-111111111111',
                  'email': 'a@b.co',
                  'displayName': 'Nova',
                  'currentLevel': 4,
                  'totalXp': 480,
                  'overallMastery': 62.5,
                  'currentSubjectId': null,
                  'currentTopicId': null,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (path.contains('/gamification/summary')) {
              return http.Response(
                jsonEncode({
                  'totalXp': 480,
                  'currentLevel': 4,
                  'maxLevel': 50,
                  'nextLevelThresholdXp': 600,
                  'xpToNextLevel': 120,
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'achievementCount': 2,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (path.contains('/streak')) {
              return http.Response(
                jsonEncode({
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'lastLearningDate': '2026-08-24',
                  'timezone': 'UTC',
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (path.contains('/dashboard')) {
              return http.Response(
                jsonEncode(_dashboardWithTopics(_mixedTopics())),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response('', 404);
          }),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      expect(find.text('63%'), findsOneWidget); // 62.5 rounded
      expect(
        find.text('Variables & Types', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Control Flow', skipOffstage: false), findsOneWidget);
      expect(
        find.text('SQL & Transactions', skipOffstage: false),
        findsWidgets,
      );
      // Mastery levels rendered
      expect(find.text('MASTERED', skipOffstage: false), findsOneWidget);
      expect(find.text('BEGINNER', skipOffstage: false), findsOneWidget);
      // Trends
      expect(find.text('Improving', skipOffstage: false), findsOneWidget);
      expect(find.text('Stable', skipOffstage: false), findsOneWidget);
      expect(find.text('Needs attention', skipOffstage: false), findsOneWidget);
      expect(find.text('New', skipOffstage: false), findsOneWidget);
    });

    testWidgets('empty mastery shows honest empty state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        _wrap(
          const ProgressScreen(),
          () => MockClient((request) async {
            final path = request.url.path;
            if (path.contains('/profile')) {
              return http.Response(
                jsonEncode({
                  'id': '11111111-1111-1111-1111-111111111111',
                  'email': 'a@b.co',
                  'displayName': 'Nova',
                  'currentLevel': 1,
                  'totalXp': 0,
                  'overallMastery': 0,
                  'currentSubjectId': null,
                  'currentTopicId': null,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (path.contains('/gamification/summary')) {
              return http.Response(
                jsonEncode({
                  'totalXp': 0,
                  'currentLevel': 1,
                  'maxLevel': 50,
                  'nextLevelThresholdXp': 100,
                  'xpToNextLevel': 100,
                  'currentStreakDays': 0,
                  'longestStreakDays': 0,
                  'achievementCount': 0,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (path.contains('/streak')) {
              return http.Response(
                jsonEncode({
                  'currentStreakDays': 0,
                  'longestStreakDays': 0,
                  'lastLearningDate': null,
                  'timezone': 'UTC',
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (path.contains('/dashboard')) {
              return http.Response(
                jsonEncode(_dashboardWithTopics([])),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response('', 404);
          }),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.textContaining('reveal your mastery radar'), findsOneWidget);
      expect(
        find.textContaining('Complete a few missions'),
        findsOneWidget,
      ); // recent accuracy empty
    });

    testWidgets('error state with retry', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        _wrap(
          const ProgressScreen(),
          () => MockClient(
            (_) async => http.Response(
              jsonEncode({'errorCode': 'INTERNAL_ERROR', 'message': 'down'}),
              500,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('filter chips filter topics presentationally', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        _wrap(
          const ProgressScreen(),
          () => MockClient((request) async {
            final path = request.url.path;
            if (path.contains('/profile') ||
                path.contains('/gamification') ||
                path.contains('/streak')) {
              if (path.contains('/profile'))
                return http.Response(
                  jsonEncode({
                    'id': '11111111-1111-1111-1111-111111111111',
                    'email': 'a@b.co',
                    'displayName': 'Nova',
                    'currentLevel': 4,
                    'totalXp': 480,
                    'overallMastery': 62.5,
                    'currentSubjectId': null,
                    'currentTopicId': null,
                  }),
                  200,
                  headers: {'content-type': 'application/json'},
                );
              if (path.contains('/summary'))
                return http.Response(
                  jsonEncode({
                    'totalXp': 480,
                    'currentLevel': 4,
                    'maxLevel': 50,
                    'nextLevelThresholdXp': 600,
                    'xpToNextLevel': 120,
                    'currentStreakDays': 7,
                    'longestStreakDays': 9,
                    'achievementCount': 2,
                  }),
                  200,
                  headers: {'content-type': 'application/json'},
                );
              return http.Response(
                jsonEncode({
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'lastLearningDate': '2026-08-24',
                  'timezone': 'UTC',
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (path.contains('/dashboard')) {
              return http.Response(
                jsonEncode(_dashboardWithTopics(_mixedTopics())),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response('', 404);
          }),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      // All filter should show 4 topics
      expect(find.textContaining('All (4)'), findsOneWidget);
      expect(find.textContaining('Strong (2)'), findsOneWidget);
      expect(find.textContaining('Needs Practice (1)'), findsOneWidget);
      // Tap Strong — mastery list shows 2, focus card still shows weak SQL (total SQL =1 from focus)
      await tester.tap(find.textContaining('Strong (2)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Should show only MASTERED + PROFICIENT = 2 in mastery list; SQL remains only in focus card
      expect(
        find.text('Variables & Types', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Control Flow', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Functions', skipOffstage: false),
        findsNothing,
      ); // DEVELOPING filtered out
      expect(
        find.text('SQL & Transactions', skipOffstage: false),
        findsOneWidget,
      ); // focus card
      // Tap Needs Practice — list shows 1 SQL, focus also SQL => total 2
      await tester.tap(find.textContaining('Needs Practice (1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.text('SQL & Transactions', skipOffstage: false),
        findsWidgets,
      ); // list + focus
      expect(find.text('Variables & Types', skipOffstage: false), findsNothing);
      // Tap Developing
      await tester.tap(find.textContaining('Developing (1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Functions', skipOffstage: false), findsOneWidget);
      expect(
        find.text('SQL & Transactions', skipOffstage: false),
        findsOneWidget,
      ); // still in focus card
    });

    testWidgets('weak-area emphasis shows focus mission for BEGINNER', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        _wrap(
          const ProgressScreen(),
          () => MockClient((request) async {
            final path = request.url.path;
            if (path.contains('/profile'))
              return http.Response(
                jsonEncode({
                  'id': '11111111-1111-1111-1111-111111111111',
                  'email': 'a@b.co',
                  'displayName': 'Nova',
                  'currentLevel': 4,
                  'totalXp': 480,
                  'overallMastery': 62.5,
                  'currentSubjectId': null,
                  'currentTopicId': null,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/summary'))
              return http.Response(
                jsonEncode({
                  'totalXp': 480,
                  'currentLevel': 4,
                  'maxLevel': 50,
                  'nextLevelThresholdXp': 600,
                  'xpToNextLevel': 120,
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'achievementCount': 2,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/streak'))
              return http.Response(
                jsonEncode({
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'lastLearningDate': '2026-08-24',
                  'timezone': 'UTC',
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/dashboard'))
              return http.Response(
                jsonEncode(_dashboardWithTopics(_mixedTopics())),
                200,
                headers: {'content-type': 'application/json'},
              );
            return http.Response('', 404);
          }),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('FOCUS MISSION', skipOffstage: false), findsOneWidget);
      expect(
        find.text('SQL & Transactions', skipOffstage: false),
        findsWidgets,
      ); // in mastery list + focus card
      expect(
        find.textContaining(
          'Your next mission can strengthen',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('no fabricated mastery — values come from backend verbatim', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      const backendScore = 77.0;
      await tester.pumpWidget(
        _wrap(
          const ProgressScreen(),
          () => MockClient((request) async {
            final path = request.url.path;
            if (path.contains('/profile'))
              return http.Response(
                jsonEncode({
                  'id': '11111111-1111-1111-1111-111111111111',
                  'email': 'a@b.co',
                  'displayName': 'Nova',
                  'currentLevel': 4,
                  'totalXp': 480,
                  'overallMastery': backendScore,
                  'currentSubjectId': null,
                  'currentTopicId': null,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/summary'))
              return http.Response(
                jsonEncode({
                  'totalXp': 480,
                  'currentLevel': 4,
                  'maxLevel': 50,
                  'nextLevelThresholdXp': 600,
                  'xpToNextLevel': 120,
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'achievementCount': 2,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/streak'))
              return http.Response(
                jsonEncode({
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'lastLearningDate': '2026-08-24',
                  'timezone': 'UTC',
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/dashboard')) {
              return http.Response(
                jsonEncode(
                  _dashboardWithTopics([
                    {
                      'topicId': '22222222-2222-2222-2222-222222222211',
                      'topicName': 'Variables & Types',
                      'masteryScore': backendScore,
                      'masteryLevel': 'PROFICIENT',
                      'currentDifficulty': 'MEDIUM',
                      'trend': 'IMPROVING',
                      'lastAssessedAt': '2026-08-24T09:00:00Z',
                    },
                  ]),
                ),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response('', 404);
          }),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('77%'), findsWidgets); // overall + topic
      expect(find.text('PROFICIENT'), findsOneWidget);
    });

    testWidgets('subject-agnostic — different topic names render', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final dbTopics = [
        {
          'topicId': '22222222-2222-2222-2222-222222222214',
          'topicName': 'Networking Fundamentals',
          'masteryScore': 88,
          'masteryLevel': 'PROFICIENT',
          'currentDifficulty': 'MEDIUM',
          'trend': 'IMPROVING',
          'lastAssessedAt': '2026-08-24T09:00:00Z',
        },
        {
          'topicId': '22222222-2222-2222-2222-222222222231',
          'topicName': 'OS Fundamentals',
          'masteryScore': 45,
          'masteryLevel': 'DEVELOPING',
          'currentDifficulty': 'EASY',
          'trend': 'STABLE',
          'lastAssessedAt': '2026-08-24T09:00:00Z',
        },
      ];
      await tester.pumpWidget(
        _wrap(
          const ProgressScreen(),
          () => MockClient((request) async {
            final path = request.url.path;
            if (path.contains('/profile'))
              return http.Response(
                jsonEncode({
                  'id': '11111111-1111-1111-1111-111111111111',
                  'email': 'a@b.co',
                  'displayName': 'Nova',
                  'currentLevel': 4,
                  'totalXp': 480,
                  'overallMastery': 62.5,
                  'currentSubjectId': null,
                  'currentTopicId': null,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/summary'))
              return http.Response(
                jsonEncode({
                  'totalXp': 480,
                  'currentLevel': 4,
                  'maxLevel': 50,
                  'nextLevelThresholdXp': 600,
                  'xpToNextLevel': 120,
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'achievementCount': 2,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/streak'))
              return http.Response(
                jsonEncode({
                  'currentStreakDays': 7,
                  'longestStreakDays': 9,
                  'lastLearningDate': '2026-08-24',
                  'timezone': 'UTC',
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            if (path.contains('/dashboard'))
              return http.Response(
                jsonEncode(_dashboardWithTopics(dbTopics)),
                200,
                headers: {'content-type': 'application/json'},
              );
            return http.Response('', 404);
          }),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(
        find.text('Networking Fundamentals', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('OS Fundamentals', skipOffstage: false), findsOneWidget);
    });
  });

  group('TopicPerformance Phase 4 — sparkline and mastery', () {
    testWidgets(
      'shows mastery and empty trajectory when insufficient history',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        const topicId = '22222222-2222-2222-2222-222222222211';
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tokenStorageProvider.overrideWithValue(
                FakeTokenStorage()..stored = 'tok',
              ),
              apiClientProvider.overrideWith(
                (ref) => ApiClient(
                  client: MockClient((request) async {
                    final path = request.url.path;
                    if (path.contains('/topics/$topicId') &&
                        !path.contains('/lesson')) {
                      return http.Response(
                        jsonEncode({
                          'id': topicId,
                          'subjectId': '11111111-1111-1111-1111-111111111101',
                          'subjectName': 'Programming',
                          'name': 'Variables & Types',
                          'description': 'desc',
                          'difficulty': 'EASY',
                          'displayOrder': 1,
                        }),
                        200,
                        headers: {'content-type': 'application/json'},
                      );
                    }
                    if (path.contains('/progress/$topicId')) {
                      return http.Response(
                        jsonEncode({
                          'errorCode': 'RESOURCE_NOT_FOUND',
                          'message': 'Progress not found',
                        }),
                        404,
                        headers: {'content-type': 'application/json'},
                      );
                    }
                    if (path.contains('/dashboard')) {
                      return http.Response(
                        jsonEncode(
                          _dashboardWithTopics(
                            [
                              {
                                'topicId': topicId,
                                'topicName': 'Variables & Types',
                                'masteryScore': 85,
                                'masteryLevel': 'PROFICIENT',
                                'currentDifficulty': 'MEDIUM',
                                'trend': 'IMPROVING',
                                'lastAssessedAt': '2026-08-24T09:00:00Z',
                              },
                            ],
                            quizzes: [
                              {
                                'quizAttemptId': 'qa1',
                                'topicId': topicId,
                                'topicName': 'Variables & Types',
                                'score': 80,
                                'correctCount': 4,
                                'totalQuestions': 5,
                                'submittedAt': '2026-08-24T10:00:00Z',
                              },
                            ],
                          ),
                        ),
                        200,
                        headers: {'content-type': 'application/json'},
                      );
                    }
                    return http.Response('', 404);
                  }),
                ),
              ),
              audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
            ],
            child: const MaterialApp(
              home: TopicPerformanceScreen(
                topicId: '22222222-2222-2222-2222-222222222211',
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(
          find.text('Variables & Types', skipOffstage: false),
          findsWidgets,
        );
        expect(find.text('85%'), findsOneWidget);
        // 1 attempt → honest empty "One attempt recorded..."
        expect(find.textContaining('One attempt recorded'), findsOneWidget);
      },
    );

    testWidgets('shows sparkline when at least 2 attempts', (tester) async {
      SharedPreferences.setMockInitialValues({});
      const topicId = '22222222-2222-2222-2222-222222222211';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  final path = request.url.path;
                  if (path.contains('/topics/$topicId') &&
                      !path.contains('/lesson')) {
                    return http.Response(
                      jsonEncode({
                        'id': topicId,
                        'subjectId': '11111111-1111-1111-1111-111111111101',
                        'subjectName': 'Programming',
                        'name': 'Variables & Types',
                        'description': 'desc',
                        'difficulty': 'EASY',
                        'displayOrder': 1,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  if (path.contains('/progress/$topicId')) {
                    return http.Response(
                      jsonEncode({
                        'id': 'p1',
                        'topicId': topicId,
                        'learningPathNodeId': null,
                        'completionPercentage': 50,
                        'status': 'IN_PROGRESS',
                        'lastActivityAt': '2026-08-24T10:00:00Z',
                        'completedAt': null,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  if (path.contains('/dashboard')) {
                    return http.Response(
                      jsonEncode(
                        _dashboardWithTopics(
                          [
                            {
                              'topicId': topicId,
                              'topicName': 'Variables & Types',
                              'masteryScore': 85,
                              'masteryLevel': 'PROFICIENT',
                              'currentDifficulty': 'MEDIUM',
                              'trend': 'IMPROVING',
                              'lastAssessedAt': '2026-08-24T09:00:00Z',
                            },
                          ],
                          quizzes: [
                            {
                              'quizAttemptId': 'qa1',
                              'topicId': topicId,
                              'topicName': 'Variables & Types',
                              'score': 60,
                              'correctCount': 3,
                              'totalQuestions': 5,
                              'submittedAt': '2026-08-24T09:00:00Z',
                            },
                            {
                              'quizAttemptId': 'qa2',
                              'topicId': topicId,
                              'topicName': 'Variables & Types',
                              'score': 80,
                              'correctCount': 4,
                              'totalQuestions': 5,
                              'submittedAt': '2026-08-24T10:00:00Z',
                            },
                            {
                              'quizAttemptId': 'qa3',
                              'topicId': topicId,
                              'topicName': 'Variables & Types',
                              'score': 85,
                              'correctCount': 4,
                              'totalQuestions': 5,
                              'submittedAt': '2026-08-24T11:00:00Z',
                            },
                          ],
                        ),
                      ),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(
            home: TopicPerformanceScreen(
              topicId: '22222222-2222-2222-2222-222222222211',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('PERFORMANCE TRAJECTORY'), findsOneWidget);
      // Should show CustomPaint sparkline (find by type)
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles different subjects — DBMS topic', (tester) async {
      SharedPreferences.setMockInitialValues({});
      const topicId = '22222222-2222-2222-2222-222222222221';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  final path = request.url.path;
                  if (path.contains('/topics/$topicId') &&
                      !path.contains('/lesson')) {
                    return http.Response(
                      jsonEncode({
                        'id': topicId,
                        'subjectId': '11111111-1111-1111-1111-111111111103',
                        'subjectName': 'DBMS',
                        'name': 'Database Fundamentals',
                        'description': 'desc',
                        'difficulty': 'EASY',
                        'displayOrder': 1,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  if (path.contains('/progress/$topicId')) {
                    return http.Response(
                      jsonEncode({
                        'errorCode': 'RESOURCE_NOT_FOUND',
                        'message': 'Progress not found',
                      }),
                      404,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  if (path.contains('/dashboard')) {
                    return http.Response(
                      jsonEncode(
                        _dashboardWithTopics([
                          {
                            'topicId': topicId,
                            'topicName': 'Database Fundamentals',
                            'masteryScore': 42,
                            'masteryLevel': 'DEVELOPING',
                            'currentDifficulty': 'EASY',
                            'trend': 'STABLE',
                            'lastAssessedAt': '2026-08-24T09:00:00Z',
                          },
                        ]),
                      ),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(
            home: TopicPerformanceScreen(
              topicId: '22222222-2222-2222-2222-222222222221',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(
        find.text('Database Fundamentals', skipOffstage: false),
        findsWidgets,
      );
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('DEVELOPING'), findsOneWidget);
    });
  });

  group('Responsive — Phase 4', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size,
      Widget widget,
    ) async {
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }

    testWidgets('ProgressScreen responsive at 360', (tester) async {
      await pumpAtSize(
        tester,
        const Size(360, 800),
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  final path = request.url.path;
                  if (path.contains('/profile'))
                    return http.Response(
                      jsonEncode({
                        'id': '11111111-1111-1111-1111-111111111111',
                        'email': 'a@b.co',
                        'displayName': 'Nova',
                        'currentLevel': 4,
                        'totalXp': 480,
                        'overallMastery': 62.5,
                        'currentSubjectId': null,
                        'currentTopicId': null,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/summary'))
                    return http.Response(
                      jsonEncode({
                        'totalXp': 480,
                        'currentLevel': 4,
                        'maxLevel': 50,
                        'nextLevelThresholdXp': 600,
                        'xpToNextLevel': 120,
                        'currentStreakDays': 7,
                        'longestStreakDays': 9,
                        'achievementCount': 2,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/streak'))
                    return http.Response(
                      jsonEncode({
                        'currentStreakDays': 7,
                        'longestStreakDays': 9,
                        'lastLearningDate': '2026-08-24',
                        'timezone': 'UTC',
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/dashboard'))
                    return http.Response(
                      jsonEncode(_dashboardWithTopics(_mixedTopics())),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      expect(find.text('PLAYER STATS'), findsOneWidget);
      expect(
        find.text('Overall Mastery'),
        findsNothing,
      ); // case is OVERALL MASTERY
      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('ProgressScreen responsive at 768', (tester) async {
      await pumpAtSize(
        tester,
        const Size(768, 1024),
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  final path = request.url.path;
                  if (path.contains('/profile'))
                    return http.Response(
                      jsonEncode({
                        'id': '11111111-1111-1111-1111-111111111111',
                        'email': 'a@b.co',
                        'displayName': 'Nova',
                        'currentLevel': 4,
                        'totalXp': 480,
                        'overallMastery': 62.5,
                        'currentSubjectId': null,
                        'currentTopicId': null,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/summary'))
                    return http.Response(
                      jsonEncode({
                        'totalXp': 480,
                        'currentLevel': 4,
                        'maxLevel': 50,
                        'nextLevelThresholdXp': 600,
                        'xpToNextLevel': 120,
                        'currentStreakDays': 7,
                        'longestStreakDays': 9,
                        'achievementCount': 2,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/streak'))
                    return http.Response(
                      jsonEncode({
                        'currentStreakDays': 7,
                        'longestStreakDays': 9,
                        'lastLearningDate': '2026-08-24',
                        'timezone': 'UTC',
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/dashboard'))
                    return http.Response(
                      jsonEncode(_dashboardWithTopics(_mixedTopics())),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('ProgressScreen responsive at 1440', (tester) async {
      await pumpAtSize(
        tester,
        const Size(1440, 900),
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  final path = request.url.path;
                  if (path.contains('/profile'))
                    return http.Response(
                      jsonEncode({
                        'id': '11111111-1111-1111-1111-111111111111',
                        'email': 'a@b.co',
                        'displayName': 'Nova',
                        'currentLevel': 4,
                        'totalXp': 480,
                        'overallMastery': 62.5,
                        'currentSubjectId': null,
                        'currentTopicId': null,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/summary'))
                    return http.Response(
                      jsonEncode({
                        'totalXp': 480,
                        'currentLevel': 4,
                        'maxLevel': 50,
                        'nextLevelThresholdXp': 600,
                        'xpToNextLevel': 120,
                        'currentStreakDays': 7,
                        'longestStreakDays': 9,
                        'achievementCount': 2,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/streak'))
                    return http.Response(
                      jsonEncode({
                        'currentStreakDays': 7,
                        'longestStreakDays': 9,
                        'lastLearningDate': '2026-08-24',
                        'timezone': 'UTC',
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/dashboard'))
                    return http.Response(
                      jsonEncode(_dashboardWithTopics(_mixedTopics())),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('ProgressScreen responsive at 1920', (tester) async {
      await pumpAtSize(
        tester,
        const Size(1920, 1080),
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  final path = request.url.path;
                  if (path.contains('/profile'))
                    return http.Response(
                      jsonEncode({
                        'id': '11111111-1111-1111-1111-111111111111',
                        'email': 'a@b.co',
                        'displayName': 'Nova',
                        'currentLevel': 4,
                        'totalXp': 480,
                        'overallMastery': 62.5,
                        'currentSubjectId': null,
                        'currentTopicId': null,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/summary'))
                    return http.Response(
                      jsonEncode({
                        'totalXp': 480,
                        'currentLevel': 4,
                        'maxLevel': 50,
                        'nextLevelThresholdXp': 600,
                        'xpToNextLevel': 120,
                        'currentStreakDays': 7,
                        'longestStreakDays': 9,
                        'achievementCount': 2,
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/streak'))
                    return http.Response(
                      jsonEncode({
                        'currentStreakDays': 7,
                        'longestStreakDays': 9,
                        'lastLearningDate': '2026-08-24',
                        'timezone': 'UTC',
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  if (path.contains('/dashboard'))
                    return http.Response(
                      jsonEncode(_dashboardWithTopics(_mixedTopics())),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      expect(tester.takeException(), isNull);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
