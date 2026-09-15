import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/auth/presentation/onboarding_screen.dart';
import 'package:gamelearn_app/features/auth/presentation/register_screen.dart';
import 'package:gamelearn_app/features/challenge/quiz/presentation/quiz_screen.dart';
import 'package:gamelearn_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gamelearn_app/features/gamification/presentation/achievements_screen.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/game_engine/widgets/game_result_screen.dart';
import 'package:gamelearn_app/features/games/hub/presentation/game_hub_screen.dart';
import 'package:gamelearn_app/features/profile/presentation/settings_screen.dart';

import '../helpers/fake_backend.dart';

/// F2 focused responsive audit as executable sweeps: the most important
/// existing screens must render without overflow at compact width (390px)
/// and keep their desktop composition (1280px).
///
/// Screens with dedicated responsive suites already (subjects catalog,
/// world arena, champions arena, character collection) are covered by those
/// suites and intentionally not duplicated here.

const _compact = Size(390, 844);
const _desktop = Size(1280, 800);

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _calm(Widget child) => MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: child,
);

Future<SharedPreferences> _fakePrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void main() {
  group('Screens responsive sweep (F2 audit)', () {
    testWidgets('onboarding renders all panels without overflow at 390px',
        (tester) async {
      await _setSize(tester, _compact);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(await _fakePrefs()),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: MaterialApp(home: _calm(const OnboardingScreen())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome to GameLearnAI'), findsOneWidget);

      // Swipe through every panel; each must lay out without overflow.
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(-360, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull,
            reason: 'Onboarding panel ${i + 1} overflowed at $_compact');
      }
      expect(find.text('Level Up with Nova'), findsOneWidget);
    });

    testWidgets('dashboard zero-state has no overflow at 390px and 1280px',
        (tester) async {
      for (final size in [_compact, _desktop]) {
        await _setSize(tester, size);
        await tester.pumpWidget(
          fakeScope(
            child: MaterialApp(home: _calm(const DashboardScreen())),
            handler: (_) => {'body': Fixtures.dashboardZeroState()},
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull,
            reason: 'Dashboard zero-state overflowed at $size');
        expect(find.text('CURRENT ADVENTURE'), findsOneWidget);
      }
    });

    testWidgets('game hub renders all cards without overflow at 390px',
        (tester) async {
      await _setSize(tester, _compact);
      await tester.pumpWidget(
        MaterialApp(
          home: _calm(const GameHubScreen(topicId: 't1', topicName: 'Vars')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('GAME ARENA'), findsOneWidget);

      // Build the lazily-built tail of the long card list.
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull,
          reason: 'Game hub tail overflowed at $_compact');
      expect(find.text('SNAKE & LADDER'), findsOneWidget);
    });

    testWidgets('game hub keeps desktop composition at 1280px',
        (tester) async {
      await _setSize(tester, _desktop);
      await tester.pumpWidget(
        MaterialApp(
          home: _calm(const GameHubScreen(topicId: 't1', topicName: 'Vars')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('GAME ARENA'), findsOneWidget);
    });

    testWidgets('settings renders without overflow at 390px and 1280px',
        (tester) async {
      for (final size in [_compact, _desktop]) {
        await _setSize(tester, size);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(await _fakePrefs()),
              audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
            ],
            child: MaterialApp(home: _calm(const SettingsScreen())),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Settings overflowed at $size');
        expect(find.text('Background music'), findsOneWidget);
        expect(find.text('Music Volume'), findsOneWidget);
        expect(find.byType(Slider), findsWidgets);
      }
    });

    testWidgets('quiz question layout has no overflow at 390px',
        (tester) async {
      await _setSize(tester, _compact);
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp(home: _calm(const QuizScreen(topicId: 't2'))),
          handler: (request) {
            if (request.url.path.contains('/quiz/')) {
              return {'body': Fixtures.quiz()};
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
      expect(tester.takeException(), isNull,
          reason: 'Quiz question overflowed at $_compact');
      expect(find.text('Which keyword declares a constant?'), findsOneWidget);
    });

    testWidgets('register renders without overflow at 390px', (tester) async {
      await _setSize(tester, _compact);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(await _fakePrefs()),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: MaterialApp(home: _calm(const RegisterScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Register overflowed at $_compact');
      expect(find.text('Begin your journey'), findsOneWidget);
      expect(find.text('Display name'), findsOneWidget);
      // AppBar title plus the submit button share this label.
      expect(find.text('CREATE PLAYER'), findsWidgets);
    });

    testWidgets('game result controls fit without overflow at 390px',
        (tester) async {
      await _setSize(tester, _compact);
      final result = GameResult(
        config: const GameConfig(
          topicId: 't',
          type: GameType.puzzleArena,
          difficulty: GameDifficulty.medium,
        ),
        score: 420,
        accuracy: 85,
        correctCount: 3,
        totalQuestions: 4,
        timeElapsedSeconds: 92,
        comboMax: 3,
        xpEarned: 22,
        completedAt: DateTime.now(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(await _fakePrefs()),
          ],
          child: MaterialApp(
            home: _calm(
              GameResultScreen(result: result, onReplay: () {}, onContinue: () {}),
            ),
          ),
        ),
      );
      // Allow the animated counters to finish before asserting layout.
      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull,
          reason: 'Game result overflowed at $_compact');
      expect(find.text('MISSION COMPLETE'), findsOneWidget);
      expect(find.text('PLAY AGAIN'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('achievements list has no overflow at 390px', (tester) async {
      await _setSize(tester, _compact);
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp(home: _calm(const AchievementsScreen())),
          handler: (_) => {'body': Fixtures.achievements()},
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull,
          reason: 'Achievements overflowed at $_compact');
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Week Warrior'), findsOneWidget);
    });
  });
}
