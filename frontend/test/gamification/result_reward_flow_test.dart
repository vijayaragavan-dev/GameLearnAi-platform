import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/gamification_delta.dart';
import 'package:gamelearn_app/core/models/gamification_models.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/core/theme/app_theme.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/game_engine/widgets/game_result_screen.dart';

import '../helpers/fake_backend.dart';

/// F5 result → reward flow regression: rendering, XP honesty, single
/// submission, level/streak standing, genuine unlocks, navigation contract,
/// responsive and theme coverage. All values come from the real models and
/// fake-backend fixtures — nothing is fabricated.
void main() {
  const topicId = 't1';
  const topicName = 'IP Addressing';
  const subjectId = 's-net';
  const subjectName = 'Computer Networks';

  GameResult result({int xpEarned = 22, int? bestScore = 400}) => GameResult(
    config: const GameConfig(
      topicId: topicId,
      topicName: topicName,
      subjectId: subjectId,
      subjectName: subjectName,
      type: GameType.quizBattle,
      difficulty: GameDifficulty.medium,
    ),
    score: 420,
    accuracy: 85,
    correctCount: 3,
    totalQuestions: 4,
    timeElapsedSeconds: 92,
    comboMax: 3,
    xpEarned: xpEarned,
    completedAt: DateTime.now(),
    bestScore: bestScore,
  );

  Map<String, dynamic> summaryJson() => {
    'totalXp': 345,
    'currentLevel': 3,
    'maxLevel': 50,
    'nextLevelThresholdXp': 600,
    'xpToNextLevel': 255,
    'currentStreakDays': 7,
    'longestStreakDays': 9,
    'achievementCount': 2,
  };

  Future<SharedPreferences> fakePrefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// Single ProviderScope carrying every override (prefs + fake backend).
  /// Nested scopes proved unreliable for provider resolution in this
  /// harness, so all overrides live in one scope above MaterialApp.
  Widget wrap({
    required GameResult result,
    required Map<String, dynamic> Function(http.Request) handler,
    required SharedPreferences prefs,
    GamificationDelta? delta,
    VoidCallback? onReplay,
    ThemeData? theme,
  }) {
    final client = MockClient((request) async {
      final result = handler(request);
      final status = (result['status'] as num?)?.toInt() ?? 200;
      Object? body = result['body'];
      if (body is Map || body is List) body = jsonEncode(body);
      return http.Response(
        body?.toString() ?? '',
        status,
        headers: {'content-type': 'application/json'},
      );
    });
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
        audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
      ],
      child: MaterialApp(
        theme: theme,
        home: GameResultScreen(
          result: result,
          gamificationDelta: delta,
          onReplay: onReplay,
        ),
      ),
    );
  }

  Map<String, dynamic> Function(http.Request) okHandler(
    List<String> posts, {
    bool summaryOk = true,
  }) {
    return (request) {
      final path = request.url.path;
      if (path.endsWith('/api/v1/me/game-results')) {
        posts.add(path);
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
      if (path.endsWith('/api/v1/gamification/summary')) {
        if (!summaryOk) return {'status': 500, 'body': {}};
        return {'body': summaryJson()};
      }
      return {'status': 404, 'body': {}};
    };
  }

  group('Result reward flow (F5)', () {
    testWidgets('renders score, context, XP delta and standing', (tester) async {
      await setSize(tester, const Size(390, 844));
      final posts = <String>[];
      final prefs = await fakePrefs();
      await tester.pumpWidget(
        wrap(
          prefs: prefs,
          result: result(),
          handler: okHandler(posts),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull);

      expect(find.text('MISSION COMPLETE'), findsOneWidget);
      expect(find.text('420'), findsWidgets);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('IP Addressing'), findsWidgets);
      // Local earned value (no delta passed here), never invented.
      expect(find.text('+22 XP'), findsOneWidget);
      expect(find.text('NEW PERSONAL BEST!'), findsOneWidget);
      // Level + streak standing from the gamification summary.
      expect(find.text('LEVEL 03'), findsOneWidget);
      expect(find.text('255 XP TO NEXT'), findsOneWidget);
      expect(find.text('7-DAY STREAK'), findsOneWidget);
      // Mastery insight hides honestly without dashboard data.
      expect(find.textContaining('Overall mastery'), findsNothing);
    });

    testWidgets('honest zero-XP and hidden standing on failure', (
      tester,
    ) async {
      await setSize(tester, const Size(390, 844));
      final posts = <String>[];
      final prefs = await fakePrefs();
      await tester.pumpWidget(
        wrap(
          prefs: prefs,
          result: result(xpEarned: 0, bestScore: null),
          handler: okHandler(posts, summaryOk: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull);

      expect(find.text('No XP this run'), findsOneWidget);
      expect(find.text('NEW PERSONAL BEST!'), findsNothing);
      // Failed standing read invents nothing.
      expect(find.textContaining('LEVEL'), findsNothing);
      expect(find.textContaining('STREAK'), findsNothing);
      // The completion itself still submits exactly once.
      expect(posts, hasLength(1));
    });

    testWidgets('rebuilds never duplicate the reward submission', (
      tester,
    ) async {
      await setSize(tester, const Size(390, 844));
      final posts = <String>[];
      final prefs = await fakePrefs();
      final widget = wrap(
        prefs: prefs,
        result: result(),
        handler: okHandler(posts),
      );
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 1100));
      // Rebuilds, animation frames and a second pump must not resubmit.
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(posts, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('genuine achievement unlock is presented', (tester) async {
      await setSize(tester, const Size(390, 844));
      final posts = <String>[];
      final prefs = await fakePrefs();
      await tester.pumpWidget(
        wrap(
          prefs: prefs,
          result: result(),
          handler: okHandler(posts),
          delta: GamificationDelta(
            xpGained: 20,
            newAchievements: [
              Achievement(
                code: 'FIRST_QUIZ',
                name: 'First Steps',
                description: 'Complete your first quiz.',
                iconKey: 'ach_first_quiz',
                xpReward: 20,
                unlockedAt: DateTime.utc(2026, 8, 24, 10, 15, 7),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('ACHIEVEMENT UNLOCKED'), findsOneWidget);
      expect(find.text('First Steps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('level-up overlay is presented', (tester) async {
      await setSize(tester, const Size(390, 844));
      final posts = <String>[];
      final prefs = await fakePrefs();
      await tester.pumpWidget(
        wrap(
          prefs: prefs,
          result: result(),
          handler: okHandler(posts),
          delta: const GamificationDelta(xpGained: 120, leveledUpTo: 4),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('LEVEL UP'), findsOneWidget);
      expect(find.text('Level up! → 4'), findsOneWidget);
      // Dismiss via the dialog's own continue control (the exit
      // transition needs frames after the tap to remove the route).
      await tester.tap(find.widgetWithText(FilledButton, 'CONTINUE'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('LEVEL UP'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('replay fires, world continue returns to the arena',
        (tester) async {
      await setSize(tester, const Size(390, 844));
      var replays = 0;
      final prefs = await fakePrefs();
      final posts = <String>[];
      final client = MockClient((request) async {
        final result = okHandler(posts)(request);
        final status = (result['status'] as num?)?.toInt() ?? 200;
        Object? body = result['body'];
        if (body is Map || body is List) body = jsonEncode(body);
        return http.Response(
          body?.toString() ?? '',
          status,
          headers: {'content-type': 'application/json'},
        );
      });
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => GameResultScreen(
              result: result(),
              onReplay: () => replays++,
            ),
          ),
          GoRoute(
            path: '/games/:topicId',
            builder: (context, state) => Text('ARENA ${state.uri}'),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Text('HOME'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));

      final replay = find.text('PLAY AGAIN');
      await tester.ensureVisible(replay);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(replay);
      await tester.pump(const Duration(milliseconds: 300));
      expect(replays, 1);

      final cont = find.text('CONTINUE');
      await tester.ensureVisible(cont);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(cont);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('/games/t1'), findsOneWidget);
      expect(find.textContaining('subjectId=s-net'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation,
        startsWith('/games/'),
      );
    });

    testWidgets('global result continues home, base always returns home',
        (tester) async {
      await setSize(tester, const Size(390, 844));
      GameResult global() => GameResult(
        config: const GameConfig(
          topicId: topicId,
          topicName: topicName,
          type: GameType.quizBattle,
          difficulty: GameDifficulty.medium,
        ),
        score: 100,
        accuracy: 60,
        correctCount: 1,
        totalQuestions: 2,
        timeElapsedSeconds: 30,
        comboMax: 1,
        xpEarned: 5,
        completedAt: DateTime.now(),
      );
      final prefs = await fakePrefs();
      final posts = <String>[];
      final client = MockClient((request) async {
        final result = okHandler(posts)(request);
        final status = (result['status'] as num?)?.toInt() ?? 200;
        Object? body = result['body'];
        if (body is Map || body is List) body = jsonEncode(body);
        return http.Response(
          body?.toString() ?? '',
          status,
          headers: {'content-type': 'application/json'},
        );
      });
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => GameResultScreen(result: global()),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Text('HOME'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      // No subject: no arena shortcut, Continue goes home.
      expect(find.text('BACK TO ARENA'), findsNothing);

      final cont = find.text('CONTINUE');
      await tester.ensureVisible(cont);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(cont);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('responsive sweep with standing: 320, 390, 1280', (
      tester,
    ) async {
      for (final size in const [
        Size(320, 844),
        Size(390, 844),
        Size(1280, 800),
      ]) {
        await setSize(tester, size);
        final posts = <String>[];
        final prefs = await fakePrefs();
        await tester.pumpWidget(
          wrap(
            prefs: prefs,
            result: result(),
            handler: okHandler(posts),
          ),
        );
        await tester.pump(const Duration(milliseconds: 1100));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Result overflowed at $size',
        );
        expect(find.text('MISSION COMPLETE'), findsOneWidget);
        expect(find.text('7-DAY STREAK'), findsOneWidget);
      }
    });

    testWidgets('dark theme renders without overflow', (tester) async {
      await setSize(tester, const Size(390, 844));
      final posts = <String>[];
      final prefs = await fakePrefs();
      await tester.pumpWidget(
        wrap(
          prefs: prefs,
          result: result(),
          handler: okHandler(posts),
          theme: buildGameLearnDarkTheme(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull);
      expect(find.text('MISSION COMPLETE'), findsOneWidget);
      expect(find.text('7-DAY STREAK'), findsOneWidget);
    });
  });
}
