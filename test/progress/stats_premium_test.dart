// F13 — premium stats/analytics visual upgrade: real-data rendering,
// tier/distribution/delta presentation, states, themes, responsiveness.
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
import 'package:gamelearn_app/shared/widgets/badges.dart';
import 'package:gamelearn_app/shared/widgets/xp_bar.dart';

import '../helpers/fake_backend.dart';

List<Map<String, dynamic>> _topics() => [
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
    'masteryScore': 90,
    'masteryLevel': 'PROFICIENT',
    'currentDifficulty': 'MEDIUM',
    'trend': 'STABLE',
    'lastAssessedAt': '2026-08-24T10:00:00Z',
  },
  {
    'topicId': '22222222-2222-2222-2222-222222222213',
    'topicName': 'Functions',
    'masteryScore': 70,
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

/// Latest-first backend order: 90, 70, 80.
List<Map<String, dynamic>> _quizzes() => [
  {
    'quizAttemptId': '33333333-3333-3333-3333-333333333331',
    'topicId': '22222222-2222-2222-2222-222222222212',
    'topicName': 'Control Flow',
    'score': 90,
    'correctCount': 9,
    'totalQuestions': 10,
    'submittedAt': '2026-08-24T10:00:00Z',
  },
  {
    'quizAttemptId': '33333333-3333-3333-3333-333333333332',
    'topicId': '22222222-2222-2222-2222-222222222213',
    'topicName': 'Functions',
    'score': 70,
    'correctCount': 7,
    'totalQuestions': 10,
    'submittedAt': '2026-08-23T10:00:00Z',
  },
  {
    'quizAttemptId': '33333333-3333-3333-3333-333333333333',
    'topicId': '22222222-2222-2222-2222-222222222211',
    'topicName': 'Variables & Types',
    'score': 80,
    'correctCount': 8,
    'totalQuestions': 10,
    'submittedAt': '2026-08-22T10:00:00Z',
  },
];

Map<String, dynamic> _dashboard({
  List<Map<String, dynamic>>? topics,
  List<Map<String, dynamic>>? quizzes,
  double overallMastery = 72,
}) => {
  'learner': {
    'displayName': 'Nova Player',
    'overallMastery': overallMastery,
    'currentSubjectId': null,
    'currentTopicId': null,
  },
  'currentSubject': null,
  'mastery': {
    'topicsAssessed': (topics ?? []).length,
    'topicsMastered': (topics ?? [])
        .where((t) => t['masteryLevel'] == 'MASTERED')
        .length,
    'recentTopics': topics ?? [],
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
  'recentActivity': {'quizzes': quizzes ?? []},
};

Widget _wrap(
  Widget child,
  MockClient Function() clientFactory, {
  ThemeMode mode = ThemeMode.dark,
}) {
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
    child: MaterialApp(
      themeMode: mode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: child,
    ),
  );
}

MockClient _client({
  List<Map<String, dynamic>>? topics,
  List<Map<String, dynamic>>? quizzes,
  double overallMastery = 72,
}) => MockClient((request) async {
  final path = request.url.path;
  if (path.contains('/profile')) {
    return http.Response(
      jsonEncode({
        'id': '11111111-1111-1111-1111-111111111111',
        'email': 'a@b.co',
        'displayName': 'Nova',
        'currentLevel': 4,
        'totalXp': 480,
        'overallMastery': overallMastery,
        'currentSubjectId': null,
        'currentTopicId': null,
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  if (path.contains('/summary')) {
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
      jsonEncode(
        _dashboard(
          topics: topics,
          quizzes: quizzes,
          overallMastery: overallMastery,
        ),
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  return http.Response('', 404);
});

Future<void> _pumpLoaded(
  WidgetTester tester,
  MockClient Function() factory,
) async {
  await tester.pumpWidget(_wrap(const ProgressScreen(), factory));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F13 premium stats analytics', () {
    testWidgets('hero shows level badge, XP progression and identity chips',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpLoaded(
        tester,
        () => _client(topics: _topics(), quizzes: _quizzes()),
      );
      expect(find.byType(LevelBadge), findsOneWidget);
      expect(find.byType(XPBar), findsOneWidget);
      expect(find.text('LEVEL 04'), findsOneWidget);
      expect(find.text('120 XP TO NEXT'), findsOneWidget);
      expect(find.text('7-DAY STREAK'), findsOneWidget);
      expect(find.text('2 BADGES'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mastery core shows tier band from real overall mastery',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpLoaded(
        tester,
        () => _client(topics: _topics(), quizzes: _quizzes()),
      );
      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      // Tier suffix keeps the band distinct from backend level pills.
      expect(find.text('PROFICIENT TIER'), findsOneWidget);
      expect(find.text('4 TRACKED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'topic mastery renders filtered list with comic cards and progress',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpLoaded(
        tester,
        () => _client(topics: _topics(), quizzes: _quizzes()),
      );
      expect(find.text('TOPIC MASTERY'), findsOneWidget);
      expect(
        find.text('Variables & Types', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Control Flow', skipOffstage: false), findsOneWidget);
      expect(find.text('92%', skipOffstage: false), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'learn streak renders current streak, best streak, and animated flame',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpLoaded(
        tester,
        () => _client(topics: _topics(), quizzes: _quizzes()),
      );
      expect(find.text('LEARN STREAK'), findsOneWidget);
      expect(find.text('7'), findsWidgets);
      expect(find.text('DAYS STREAK'), findsOneWidget);
      expect(find.text('BEST: 9'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('learn streak weekday tracker renders 7-day indicators',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpLoaded(
        tester,
        () => _client(topics: _topics(), quizzes: _quizzes()),
      );
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('learn streak interactive tap toggles selection state',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpLoaded(
        tester,
        () => _client(topics: _topics(), quizzes: _quizzes()),
      );
      final monFinder = find.text('Mon');
      expect(monFinder, findsOneWidget);
      await tester.ensureVisible(monFinder);
      await tester.tap(monFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('deprecated sections are absent from progress screen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpLoaded(
        tester,
        () => _client(topics: _topics(), quizzes: _quizzes()),
      );
      expect(find.text('SCORE TRAJECTORY'), findsNothing);
      expect(find.text('MASTERY DISTRIBUTION'), findsNothing);
      expect(find.text('GAME PERFORMANCE'), findsNothing);
      expect(find.text('FOCUS MISSION'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty states stay honest without data', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpLoaded(tester, () => _client(topics: [], quizzes: []));
      expect(find.textContaining('reveal your mastery radar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('light theme renders without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        _wrap(
          const ProgressScreen(),
          () => _client(topics: _topics(), quizzes: _quizzes()),
          mode: ThemeMode.light,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px narrow renders without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await _pumpLoaded(
        tester,
        () => _client(topics: _topics(), quizzes: _quizzes()),
      );
      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion renders the same truth', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: _client(topics: _topics(), quizzes: _quizzes()),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const ProgressScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('PROFICIENT TIER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
