import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/core/theme/app_theme.dart';
import 'package:gamelearn_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gamelearn_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:gamelearn_app/features/leaderboard/providers/leaderboard_providers.dart';

import '../helpers/fake_backend.dart';

/// Null-data position state: exercises the honest unavailable teaser.
class _NullPosition extends MyPositionController {
  @override
  MyPositionState build() => const MyPositionState();
}

/// F6 dashboard finalization: section rendering, honest states, single
/// catalog fetch, tutor/world/offline context, responsive and theme.
void main() {
  Map<String, dynamic> activeDashboard() => {
    'learner': {
      'displayName': 'Nova Player',
      'overallMastery': 55,
      'currentSubjectId': '11111111-1111-1111-1111-111111111101',
      'currentTopicId': null,
    },
    'currentSubject': {
      'id': '11111111-1111-1111-1111-111111111101',
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

  List<Map<String, dynamic>> subjects() => [
    {
      'id': '11111111-1111-1111-1111-111111111101',
      'name': 'Computer Networks',
      'description': 'Packets and routing',
      'iconKey': 'subject_networks',
      'isActive': true,
      'displayOrder': 1,
    },
  ];

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  group('Dashboard finalization (F6)', () {
    testWidgets('active dashboard renders every home section', (tester) async {
      await setSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: DashboardScreen(),
            ),
          ),
          handler: (request) {
            if (request.url.path.endsWith('/dashboard')) {
              return {'body': activeDashboard()};
            }
            if (request.url.path.endsWith('/subjects')) {
              return {'body': subjects()};
            }
            return {'status': 404, 'body': {}};
          },
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);

      expect(find.text('GAME ZONE'), findsWidgets);
      // SectionHeader uppercases its titles.
      expect(find.text('TROPHY ROOM'), findsOneWidget);
      // Section header plus the teaser card title share this label.
      expect(find.text('CHAMPIONS ARENA'), findsWidgets);
      // Section header plus the floating tutor action share the label.
      expect(find.text('NOVA'), findsWidgets);
      expect(find.text('DAILY QUESTS'), findsOneWidget);
      expect(find.text('MASTERY RADAR'), findsOneWidget);
      expect(find.text('LEARNING INTELLIGENCE'), findsOneWidget);
      // Real gamification values, not placeholders.
      expect(find.text('7'), findsWidgets);
      expect(find.text('First Steps'), findsOneWidget);
    });

    testWidgets('arena teaser never renders a fabricated #0 rank', (
      tester,
    ) async {
      await setSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Null data, no error, not loading: the dishonest #0 path.
            myPositionProvider.overrideWith(_NullPosition.new),
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  final path = request.url.path;
                  if (path.endsWith('/dashboard')) {
                    return http.Response('{}', 200);
                  }
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await settle(tester);
      expect(find.text('Rank unavailable right now'), findsOneWidget);
      expect(find.text("YOU'RE #0"), findsNothing);
      expect(find.textContaining('#-1'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('subjects catalog is fetched exactly once', (tester) async {
      await setSize(tester, const Size(390, 844));
      var subjectCalls = 0;
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: DashboardScreen(),
            ),
          ),
          handler: (request) {
            if (request.url.path.endsWith('/dashboard')) {
              return {'body': activeDashboard()};
            }
            if (request.url.path.endsWith('/subjects')) {
              subjectCalls++;
              return {'body': subjects()};
            }
            return {'status': 404, 'body': {}};
          },
        ),
      );
      await settle(tester);
      // Shared cached provider serves worlds + new-worlds strip alike.
      expect(subjectCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nova entry keeps the recommended topic context', (
      tester,
    ) async {
      await setSize(tester, const Size(390, 844));
      final client = MockClient((request) async {
        final path = request.url.path;
        Object? body;
        if (path.endsWith('/dashboard')) {
          body = jsonEncode(activeDashboard());
        } else if (path.endsWith('/subjects')) {
          body = jsonEncode(subjects());
        } else {
          return http.Response('', 404);
        }
        return http.Response(
          body.toString(),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/tutor',
            builder: (context, state) => Text('TUTOR ${state.uri}'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);

      final nova = find.bySemanticsLabel('Open Nova tutor');
      expect(nova, findsOneWidget);
      await tester.ensureVisible(nova);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(nova);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('/tutor?topicId=t2'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation,
        '/tutor',
      );
    });

    testWidgets('stale content shows the offline banner with retry', (
      tester,
    ) async {
      await setSize(tester, const Size(390, 844));
      var dashboardCalls = 0;
      late ProviderContainer container;
      await tester.pumpWidget(
        fakeScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(home: DashboardScreen());
            },
          ),
          handler: (request) {
            if (request.url.path.endsWith('/dashboard')) {
              dashboardCalls++;
              if (dashboardCalls > 1) {
                throw http.ClientException('offline');
              }
              return {'body': activeDashboard()};
            }
            if (request.url.path.endsWith('/subjects')) {
              return {'body': subjects()};
            }
            return {'status': 404, 'body': {}};
          },
        ),
      );
      await settle(tester);
      expect(
        find.text("You're offline - showing cached state"),
        findsNothing,
      );

      await container.read(dashboardProvider.notifier).refresh();
      await settle(tester);
      // Exact banner copy (the arena's own 'Arena offline' card must not
      // satisfy this assertion).
      expect(
        find.text("You're offline - showing cached state"),
        findsOneWidget,
      );
      expect(find.text('GAME ZONE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive sweep: 320, 430, 1280', (tester) async {
      for (final size in const [
        Size(320, 844),
        Size(430, 932),
        Size(1280, 800),
      ]) {
        await setSize(tester, size);
        await tester.pumpWidget(
          fakeScope(
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: DashboardScreen(),
              ),
            ),
            handler: (request) {
              if (request.url.path.endsWith('/dashboard')) {
                return {'body': activeDashboard()};
              }
              if (request.url.path.endsWith('/subjects')) {
                return {'body': subjects()};
              }
              return {'status': 404, 'body': {}};
            },
          ),
        );
        await settle(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Dashboard overflowed at $size',
        );
        expect(find.text('GAME ZONE'), findsWidgets);
      }
    });

    testWidgets('dark theme renders without overflow', (tester) async {
      await setSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp(
            theme: buildGameLearnDarkTheme(),
            home: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: DashboardScreen(),
            ),
          ),
          handler: (request) {
            if (request.url.path.endsWith('/dashboard')) {
              return {'body': activeDashboard()};
            }
            if (request.url.path.endsWith('/subjects')) {
              return {'body': subjects()};
            }
            return {'status': 404, 'body': {}};
          },
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('GAME ZONE'), findsWidgets);
    });
  });
}
