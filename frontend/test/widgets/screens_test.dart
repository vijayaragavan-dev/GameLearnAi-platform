import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gamelearn_app/features/auth/providers/session_controller.dart';
import 'package:gamelearn_app/features/auth/presentation/login_screen.dart';
import 'package:gamelearn_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gamelearn_app/features/gamification/presentation/achievements_screen.dart';
import 'package:gamelearn_app/shared/widgets/badges.dart';
import 'package:gamelearn_app/shared/widgets/feedback.dart';
import 'package:gamelearn_app/shared/widgets/game_button.dart';
import 'package:gamelearn_app/shared/widgets/nova_companion.dart';
import 'package:gamelearn_app/shared/widgets/quiz_option.dart';
import 'package:gamelearn_app/shared/widgets/xp_bar.dart';

import '../helpers/fake_backend.dart';

Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Component widgets', () {
    testWidgets('PrimaryGameButton fires tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(PrimaryGameButton(label: 'Go', onTap: () => taps++)),
      );
      await tester.tap(find.text('GO'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('QuizOption shows selected state', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: QuizOption(
              label: 'const',
              index: 0,
              state: QuizOptionState.selected,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('const'), findsOneWidget);
    });

    testWidgets('XPBar renders level and remaining labels', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: XPBar(currentLevel: 3, totalXp: 325, xpToNextLevel: 276),
          ),
        ),
      );
      expect(find.text('LEVEL 03'), findsOneWidget);
      expect(find.text('276 XP TO NEXT'), findsOneWidget);
    });

    testWidgets('ErrorState retry callback', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrap(
          ErrorState(
            title: "You're offline",
            message: 'Check your connection.',
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.tap(find.text('TRY AGAIN'));
      expect(retried, isTrue);
    });

    testWidgets('StreakChip renders zero state', (tester) async {
      await tester.pumpWidget(wrap(const Scaffold(body: StreakChip(days: 0))));
      expect(find.text('DAYS'), findsOneWidget);
    });

    testWidgets('NovaCompanion builds in all moods', (tester) async {
      for (final mood in NovaMood.values) {
        await tester.pumpWidget(wrap(NovaCompanion(size: 40, mood: mood)));
        await tester.pump(const Duration(milliseconds: 16));
      }
    });
  });

  group('LoginScreen', () {
    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: LoginScreen()),
          handler: (_) => {'body': {}},
        ),
      );
      await tester.tap(find.textContaining('SIGN IN'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('surfaces backend error message', (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: LoginScreen()),
          handler: (_) => {
            'status': 401,
            'body': {
              'errorCode': 'UNAUTHORIZED',
              'message': 'Invalid credentials',
            },
          },
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email').first,
        'a@b.co',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password').first,
        'wrongpass',
      );
      await tester.tap(find.textContaining('SIGN IN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final state = ProviderScope.containerOf(
        tester.element(find.byType(LoginScreen)),
      ).read(sessionProvider);
      expect(state.phase, SessionPhase.unauthenticated);
      expect(state.error, isNotNull);
    });

    testWidgets('successful login reaches authenticated phase', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
        ],
      );
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp.router(routerConfig: router),
          handler: (request) {
            if (request.url.path == '/api/v1/auth/login') {
              return {'body': Fixtures.authSession()};
            }
            return {'status': 404, 'body': {}};
          },
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email').first,
        'a@b.co',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password').first,
        'password1',
      );
      await tester.tap(find.textContaining('SIGN IN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // The backend accepted the credentials and the session controller
      // reached the authenticated phase (navigation itself is covered by
      // the router redirect logic).
      final state = ProviderScope.containerOf(
        tester.element(find.byType(LoginScreen)),
      ).read(sessionProvider);
      expect(state.phase, SessionPhase.authenticated);
      expect(state.user!.displayName, 'Nova Player');
    });
  });

  group('DashboardScreen', () {
    testWidgets('renders zero-state dashboard from DASH-001 shape', (
      tester,
    ) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: DashboardScreen()),
          handler: (_) => {'body': Fixtures.dashboardZeroState()},
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.textContaining('Nova'), findsOneWidget);
      expect(find.text('CURRENT ADVENTURE'), findsOneWidget);
      expect(find.text('Choose your first world'), findsOneWidget);
      expect(find.textContaining('Knowledge scan available'), findsOneWidget);
    });

    testWidgets('renders error state when DASH-001 fails', (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: DashboardScreen()),
          handler: (_) => {
            'status': 500,
            'body': {'errorCode': 'INTERNAL_ERROR', 'message': 'boom'},
          },
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.text('Something interrupted your adventure'), findsOneWidget);
    });

    testWidgets('renders streak chip and recommendations when active', (
      tester,
    ) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: DashboardScreen()),
          handler: (request) {
            if (request.url.path == '/api/v1/dashboard') {
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
      expect(find.text('7'), findsOneWidget); // streak chip
      expect(find.textContaining('IP Addressing'), findsOneWidget);
      expect(find.text('NOVA RECOMMENDS'), findsOneWidget);
    });
  });

  group('AchievementsScreen', () {
    testWidgets('unlocked and locked entries render distinctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: AchievementsScreen()),
          handler: (_) => {'body': Fixtures.achievements()},
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Week Warrior'), findsOneWidget);
      expect(find.text('1/2 UNLOCKED'), findsOneWidget);
    });

    testWidgets('error state with retry', (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(home: AchievementsScreen()),
          handler: (_) => {
            'status': 500,
            'body': {'errorCode': 'INTERNAL_ERROR', 'message': 'x'},
          },
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });
  });
}

Map<String, dynamic> _activeDashboard() => {
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
