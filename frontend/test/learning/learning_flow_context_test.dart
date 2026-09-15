import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gamelearn_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gamelearn_app/features/games/hub/presentation/game_hub_screen.dart';
import 'package:gamelearn_app/features/learning/lesson/presentation/lesson_screen.dart';
import 'package:gamelearn_app/features/subjects/presentation/subjects_screen.dart';

import '../helpers/fake_backend.dart';

/// F3 learning-flow context regression: world/topic context must survive
/// every hop of Dashboard → World → Path → Topic → Arena → Game → Result,
/// global entries must stay global, and recommendations must never point a
/// learner at a guessed world.

/// Exposed for debug harnesses.
Map<String, dynamic> debugActiveDashboard() => _activeDashboard();

Map<String, dynamic> _activeDashboard() => {
      'learner': {
        'displayName': 'Nova Player',
        'overallMastery': 55,
        'currentSubjectId': '11111111-1111-1111-1111-111111111102',
        'currentTopicId': null,
      },
      'currentSubject': {
        'id': '11111111-1111-1111-1111-111111111102',
        'name': 'Computer Networks',
    'iconKey': 'subject_networks',
    'currentTopic': null,
  },
  'mastery': {
    'topicsAssessed': 3,
    'topicsMastered': 1,
    'recentTopics': [
      {
        'topicId': 't1',
        'topicName': 'IP Addressing',
        'masteryScore': 70,
        'masteryLevel': 'PROFICIENT',
        'currentDifficulty': 'MEDIUM',
        'trend': 'IMPROVING',
        'lastAssessedAt': '2026-08-24T09:00:00Z',
      },
    ],
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
  'achievements': {
    'unlockedCount': 2,
    'recentUnlocks': [
      {
        'code': 'FIRST_QUIZ',
        'name': 'First Steps',
        'iconKey': 'ach_first_quiz',
        'unlockedAt': '2026-08-24T10:15:07Z',
      },
    ],
  },
  'recommendations': [
    {
      'topicId': 't2',
      'topicName': 'Control Flow',
      'activityType': 'QUIZ',
      'recommendedDifficulty': 'MEDIUM',
      'priority': 1,
      'reason': 'Ready for a challenge.',
      'generatedAt': '2026-08-24T09:30:05Z',
    },
  ],
  'learningPath': {
    'id': 'p1',
    'subjectId': '11111111-1111-1111-1111-111111111101',
    'subjectName': 'Computer Networks',
    'title': 'Networks Sprint',
    'status': 'ACTIVE',
    'generatedBy': 'AI',
    'createdAt': '2026-08-20T08:00:00Z',
    'nodes': [
      {
        'id': 'n1',
        'topicId': 't1',
        'topicName': 'IP Addressing',
        'sequenceNumber': 1,
        'requiredMastery': 0,
        'status': 'COMPLETED',
      },
    ],
  },
  'assessment': {
    'assessedSubjects': [
      {'subjectId': 's1', 'subjectName': 'Computer Networks'},
    ],
  },
  'recentActivity': {'quizzes': []},
};

List<Map<String, dynamic>> _subjects() => [
  {
    'id': '11111111-1111-1111-1111-111111111101',
    'name': 'Programming',
    'description': 'Code worlds',
    'iconKey': 'subject_programming',
    'isActive': true,
    'displayOrder': 1,
  },
  {
    'id': '11111111-1111-1111-1111-111111111102',
    'name': 'Computer Networks',
    'description': 'Packets and routing',
    'iconKey': 'subject_networks',
    'isActive': true,
    'displayOrder': 2,
  },
];

/// Hub builder mirroring the production router: path topicId + subject
/// query + topic-name extra.
Widget _hubFromState(GoRouterState s) => GameHubScreen(
  topicId: s.pathParameters['topicId'] ?? 't?',
  topicName: s.extra is String ? s.extra as String : null,
  subjectId: s.uri.queryParameters['subjectId'],
  subjectName: s.uri.queryParameters['subjectName'],
);

void main() {
  group('Learning flow context (F3)', () {
    testWidgets(
      'world hub: subject cards stay world-scoped, general cards stay global',
      (tester) async {
        // Tall viewport: the hub lazily builds cards, so give every
        // section room. Width stays compact; navigation scope is the point.
        tester.view.physicalSize = const Size(390, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const GameHubScreen(
                topicId: 't1',
                topicName: 'IP Addressing',
                subjectId: 's-net',
                subjectName: 'Computer Networks',
              ),
            ),
            GoRoute(
              // Echo marker: the pushed URI (path + query) is the assertion.
              path: '/games/:topicId/quiz-battle',
              builder: (_, s) => Text('PUSHED-URI ${s.uri}'),
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);

        Future<String> tappedUri(Finder card) async {
          // Cards live in a long scrollable hub; bring each into view first.
          await tester.ensureVisible(card);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(card);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          final marker = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .firstWhere((d) => d.startsWith('PUSHED-URI '));
          router.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          return marker;
        }

        final cards = find.text('QUIZ BATTLE');
        expect(cards, findsWidgets);
        // Tree order: featured card, subject-grid card, general-grid card.
        final subjectUri = await tappedUri(cards.first);
        expect(subjectUri, contains('quiz-battle'));
        expect(subjectUri, contains('subjectId=s-net'),
            reason: 'Subject-section launch must keep the world scope');

        final generalUri = await tappedUri(cards.last);
        expect(generalUri, contains('quiz-battle'));
        expect(generalUri.contains('subjectId'), isFalse,
            reason:
                'General-section launch must stay global even in a world hub');
      },
    );

    testWidgets(
      'dashboard game zone enters the global arena labelled with the topic',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
            GoRoute(path: '/subjects', builder: (context, state) => const Text('WORLDS')),
            GoRoute(path: '/games/:topicId', builder: (_, s) => _hubFromState(s)),
          ],
        );
        await tester.pumpWidget(
          fakeScope(
            child: MaterialApp.router(routerConfig: router),
            handler: (request) {
              if (request.url.path.endsWith('/dashboard')) {
                return {'body': _activeDashboard()};
              }
              return {'status': 404, 'body': {}};
            },
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);
        expect(find.text('GAME ZONE'), findsWidgets);

        final gameCard = find.text('Quiz Battle').first;
        await tester.ensureVisible(gameCard);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(gameCard);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(
          router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation,
          startsWith('/games/'),
        );
        // The hub topic pill must name the topic, never the subject.
        expect(find.text('IP Addressing'), findsOneWidget);
        expect(find.text('Computer Networks'), findsNothing);
      },
    );

    testWidgets('lesson tutor entry keeps the lesson topic context',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const LessonScreen(topicId: 't2')),
          GoRoute(
            path: '/tutor',
            builder: (_, s) => Text('TUTOR ${s.uri.queryParameters['topicId']}'),
          ),
        ],
      );
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp.router(routerConfig: router),
          handler: (request) {
            if (request.url.path.endsWith('/lesson')) {
              return {
                'body': {
                  'id': 'l1',
                  'topicId': 't2',
                  'title': 'Control Flow',
                  'content': 'Branching logic basics.',
                  'summary': 'Branching.',
                  'difficulty': 'EASY',
                  'sourceType': 'backend',
                },
              };
            }
            return {'status': 404, 'body': {}};
          },
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
      expect(find.text('Control Flow'), findsOneWidget);

      final askNova = find.byTooltip('Ask Nova');
      expect(askNova, findsOneWidget);
      await tester.ensureVisible(askNova);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(askNova);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation,
        '/tutor',
      );
      // The marker echoes the tutor query: the topic context must survive.
      expect(find.text('TUTOR t2'), findsOneWidget);
    });

    testWidgets(
      'recommended world strip hides when no current world resolves',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        Map<String, dynamic> dashboardWithoutSubject() {
          final d = _activeDashboard();
          d['currentSubjectId'] = null;
          d['currentSubject'] = null;
          return d;
        }

        await tester.pumpWidget(
          fakeScope(
            child: const MaterialApp(home: SubjectsScreen()),
            handler: (request) {
              if (request.url.path.endsWith('/subjects')) {
                return {'body': _subjects()};
              }
              return {'body': dashboardWithoutSubject()};
            },
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);
        // A recommendation exists, but with no resolved current world the
        // strip must not guess (previously fell back to the first world).
        expect(find.text('RECOMMENDED FOR YOU'), findsNothing);
      },
    );

    testWidgets('recommended world strip shows for the resolved current world',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: SubjectsScreen()),
          handler: (request) {
            if (request.url.path.endsWith('/subjects')) {
              return {'body': _subjects()};
            }
            return {'body': _activeDashboard()};
          },
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
      expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
      expect(find.text('Continue with Computer Networks'), findsOneWidget);
    });
  });
}
