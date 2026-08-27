import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gamelearn_app/core/models/dashboard_models.dart';
import 'package:gamelearn_app/core/models/quiz_models.dart';
import 'package:gamelearn_app/features/challenge/quiz/presentation/quiz_result_arg.dart';
import 'package:gamelearn_app/features/challenge/quiz/presentation/quiz_result_screen.dart';
import 'package:gamelearn_app/features/challenge/recommendation/presentation/recommendation_screen.dart';
import 'package:gamelearn_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gamelearn_app/shared/widgets/recommendation_card.dart';

import '../helpers/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive recommendation UX', () {
    testWidgets('compact recommendation cards remain actionable', (
      tester,
    ) async {
      var opened = 0;
      const item = RecommendationItem(
        topicId: 't1',
        topicName: 'Normalization',
        activityType: 'REMEDIATION',
        recommendedDifficulty: 'EASY',
        priority: 1,
        reason: 'Backend reason',
        generatedAt: null,
      );
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp(
            home: Scaffold(
              body: RecommendationCard(
                item: item,
                compact: true,
                onStart: () => opened++,
              ),
            ),
          ),
          handler: (_) => {'status': 404, 'body': {}},
        ),
      );
      await tester.tap(find.text('P1'));

      expect(opened, 1);
    });

    testWidgets('dashboard shows the backend weakness-to-action brief', (
      tester,
    ) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: DashboardScreen()),
          handler: (request) {
            if (request.url.path == '/api/v1/dashboard') {
              return {'body': _adaptiveDashboard()};
            }
            return {'status': 404, 'body': {}};
          },
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('ADAPTIVE BRIEF'), findsOneWidget);
      expect(find.text('YOU ARE STRONG IN'), findsOneWidget);
      expect(find.text('NEEDS PRACTICE'), findsOneWidget);
      expect(find.text('NEXT RECOMMENDED MISSION'), findsOneWidget);
      expect(find.text('Normalization'), findsWidgets);
      expect(
        find.text('RECENT_DECLINE_REMEDIATION: Recent results dropped.'),
        findsWidgets,
      );
      expect(find.text('P1'), findsNWidgets(2));
      expect(find.text('P4'), findsOneWidget);
    });

    testWidgets('quiz result shows mastery transition when supplied', (
      tester,
    ) async {
      final result = QuizResult.fromJson({
        'attemptId': 'a1',
        'quizId': 'q1',
        'status': 'COMPLETED',
        'score': 75,
        'correctCount': 3,
        'totalQuestions': 4,
        'durationSeconds': 40,
        'results': [],
        'adaptive': {
          'topicId': 't1',
          'masteryScore': 62.50,
          'previousMasteryScore': 50.00,
          'masteryLevel': 'DEVELOPING',
          'trend': 'IMPROVING',
          'nextDifficulty': 'MEDIUM',
          'recommendedActivity': 'PRACTICE',
          'reasonCode': 'DEVELOPING_KEEP_PRACTICING',
        },
      });

      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp(
            home: QuizResultScreen(
              arg: QuizResultArg(result: result, topicName: 'Normalization'),
            ),
          ),
          handler: (_) => {'status': 404, 'body': {}},
        ),
      );
      await tester.pump();

      expect(find.text('BEFORE'), findsOneWidget);
      expect(find.text('50.00%'), findsOneWidget);
      expect(find.text('AFTER'), findsOneWidget);
      expect(find.text('62.50%'), findsNWidgets(2));
      expect(find.text('+12.50%'), findsOneWidget);
    });

    testWidgets('missing recommendation reason is not replaced with a claim', (
      tester,
    ) async {
      const item = RecommendationItem(
        topicId: 't1',
        topicName: 'Normalization',
        activityType: 'QUIZ',
        recommendedDifficulty: 'MEDIUM',
        priority: 3,
        reason: '',
        generatedAt: null,
      );
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: RecommendationScreen(item: item)),
          handler: (_) => {'status': 404, 'body': {}},
        ),
      );
      await tester.pump();

      expect(
        find.text('No explanation was provided for this recommendation.'),
        findsOneWidget,
      );
      expect(find.textContaining('growth zone'), findsNothing);
    });

    testWidgets('recommendation activity routes to its supported loader', (
      tester,
    ) async {
      const quizItem = RecommendationItem(
        topicId: 'quiz-topic',
        topicName: 'Quiz topic',
        activityType: 'REMEDIATION',
        recommendedDifficulty: 'EASY',
        priority: 1,
        reason: 'Backend reason',
        generatedAt: null,
      );
      final router = GoRouter(
        initialLocation: '/recommendation',
        routes: [
          GoRoute(
            path: '/recommendation',
            builder: (_, _) => const RecommendationScreen(item: quizItem),
          ),
          GoRoute(
            path: '/quiz/:topicId',
            builder: (_, _) => const Scaffold(body: Text('QUIZ DESTINATION')),
          ),
        ],
      );
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp.router(routerConfig: router),
          handler: (_) => {'status': 404, 'body': {}},
        ),
      );
      await tester.pump();
      await tester.tap(find.text('ACCEPT MISSION'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/quiz/quiz-topic',
      );
      expect(find.text('QUIZ DESTINATION'), findsOneWidget);
    });

    testWidgets('continue-lesson recommendation routes to lesson loader', (
      tester,
    ) async {
      const lessonItem = RecommendationItem(
        topicId: 'lesson-topic',
        topicName: 'Lesson topic',
        activityType: 'CONTINUE_LESSON',
        recommendedDifficulty: 'MEDIUM',
        priority: 2,
        reason: 'Backend reason',
        generatedAt: null,
      );
      final router = GoRouter(
        initialLocation: '/recommendation',
        routes: [
          GoRoute(
            path: '/recommendation',
            builder: (_, _) => const RecommendationScreen(item: lessonItem),
          ),
          GoRoute(
            path: '/lesson/:topicId',
            builder: (_, _) => const Scaffold(body: Text('LESSON DESTINATION')),
          ),
        ],
      );
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp.router(routerConfig: router),
          handler: (_) => {'status': 404, 'body': {}},
        ),
      );
      await tester.pump();
      await tester.tap(find.text('ACCEPT MISSION'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/lesson/lesson-topic',
      );
      expect(find.text('LESSON DESTINATION'), findsOneWidget);
    });
  });
}

Map<String, dynamic> _adaptiveDashboard() => {
  'learner': {
    'displayName': 'Nova Player',
    'overallMastery': 51,
    'currentSubjectId': 'subject-1',
    'currentTopicId': 'weak-topic',
  },
  'currentSubject': {
    'id': 'subject-1',
    'name': 'Databases',
    'iconKey': 'subject_databases',
    'currentTopic': null,
  },
  'mastery': {
    'topicsAssessed': 2,
    'topicsMastered': 0,
    'recentTopics': [
      {
        'topicId': 'strong-topic',
        'topicName': 'SQL',
        'masteryScore': 82,
        'masteryLevel': 'PROFICIENT',
        'currentDifficulty': 'HARD',
        'trend': 'IMPROVING',
        'lastAssessedAt': '2026-08-27T10:00:00Z',
      },
      {
        'topicId': 'weak-topic',
        'topicName': 'Normalization',
        'masteryScore': 22,
        'masteryLevel': 'BEGINNER',
        'currentDifficulty': 'EASY',
        'trend': 'DECLINING',
        'lastAssessedAt': '2026-08-27T09:00:00Z',
      },
    ],
  },
  'gamification': {
    'totalXp': 100,
    'currentLevel': 2,
    'maxLevel': 50,
    'nextLevelThresholdXp': 150,
    'xpToNextLevel': 50,
  },
  'streak': {
    'currentStreakDays': 2,
    'longestStreakDays': 2,
    'lastLearningDate': '2026-08-27',
    'timezone': 'UTC',
  },
  'achievements': {'unlockedCount': 0, 'recentUnlocks': []},
  'recommendations': [
    {
      'topicId': 'weak-topic',
      'topicName': 'Normalization',
      'activityType': 'REMEDIATION',
      'recommendedDifficulty': 'EASY',
      'priority': 1,
      'reason': 'RECENT_DECLINE_REMEDIATION: Recent results dropped.',
      'generatedAt': '2026-08-27T10:01:00Z',
    },
    {
      'topicId': 'strong-topic',
      'topicName': 'SQL',
      'activityType': 'ADVANCE',
      'recommendedDifficulty': 'HARD',
      'priority': 4,
      'reason': 'MASTERED_ADVANCE_CHALLENGE: Ready to advance.',
      'generatedAt': '2026-08-27T10:00:00Z',
    },
  ],
  'learningPath': null,
  'assessment': {
    'assessedSubjects': [
      {'subjectId': 'subject-1', 'subjectName': 'Databases'},
    ],
  },
  'recentActivity': {'quizzes': []},
};
