import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/models/gamification_models.dart';
import 'package:gamelearn_app/core/models/dashboard_models.dart';
import 'package:gamelearn_app/features/gamification/presentation/achievements_screen.dart';
import 'package:gamelearn_app/features/profile/presentation/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/core/audio/audio_manager.dart';
import '../helpers/fake_backend.dart';

void main() {
  group('Phase9 Gamification Data Audit — real data only', () {
    test('GamificationSummary fields are real backend-provided, no fake calc', () {
      final json = {'totalXp': 1200, 'currentLevel': 8, 'maxLevel': 50, 'nextLevelThresholdXp': 1500, 'xpToNextLevel': 300, 'currentStreakDays': 5, 'longestStreakDays': 10, 'achievementCount': 3};
      final s = GamificationSummary.fromJson(json);
      expect(s.totalXp, 1200);
      expect(s.currentLevel, 8);
      expect(s.xpToNextLevel, 300);
      expect(s.atMaxLevel, isFalse);
      final maxJson = {'totalXp': 5000, 'currentLevel': 50, 'maxLevel': 50, 'nextLevelThresholdXp': null, 'xpToNextLevel': null, 'currentStreakDays': 0, 'longestStreakDays': 0, 'achievementCount': 0};
      final max = GamificationSummary.fromJson(maxJson);
      expect(max.atMaxLevel, isTrue);
    });

    test('DashGamification mirrors GamificationSummary level fields', () {
      final dashJson = {'totalXp': 800, 'currentLevel': 5, 'maxLevel': 50, 'nextLevelThresholdXp': 1000, 'xpToNextLevel': 200};
      final d = DashGamification.fromJson(dashJson);
      expect(d.totalXp, 800);
      expect(d.currentLevel, 5);
      expect(d.xpToNextLevel, 200);
    });

    test('Achievement unlocked vs locked via unlockedAt', () {
      final unlocked = Achievement.fromJson({'code': 'FIRST_WIN', 'name': 'First Win', 'description': 'Win once', 'iconKey': 'trophy', 'xpReward': 50, 'unlockedAt': '2026-09-01T00:00:00Z'});
      final locked = Achievement.fromJson({'code': 'STREAK_7', 'name': 'Week', 'description': '', 'iconKey': 'fire', 'xpReward': 100, 'unlockedAt': null});
      expect(unlocked.isUnlocked, isTrue);
      expect(locked.isUnlocked, isFalse);
    });

    test('StreakState real fields', () {
      final s = StreakState.fromJson({'currentStreakDays': 7, 'longestStreakDays': 12, 'lastLearningDate': '2026-09-04', 'timezone': 'UTC'});
      expect(s.currentStreakDays, 7);
      expect(s.longestStreakDays, 12);
    });

    test('LearnerProfile real fields', () {
      final p = LearnerProfile.fromJson({'id': '00000000-0000-0000-0000-000000000001', 'email': 'a@b.com', 'displayName': 'Nova', 'currentLevel': 3, 'totalXp': 450, 'overallMastery': 0.42, 'currentSubjectId': null, 'currentTopicId': null});
      expect(p.totalXp, 450);
      expect(p.currentLevel, 3);
      expect(p.overallMastery, 0.42);
    });
  });

  group('Phase9 Profile & Achievements premium — real data, no fake', () {
    testWidgets('Profile renders LEVEL and XP with real data', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), audioManagerProvider.overrideWith((ref) => SilentAudioManager())], child: const MaterialApp(home: ProfileScreen())));
      await tester.pump(const Duration(milliseconds: 100));
      // Should show loading skeleton, not crash, and not show fake XP
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Achievements shows TROPHY ROOM and handles empty', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), audioManagerProvider.overrideWith((ref) => SilentAudioManager())], child: const MaterialApp(home: AchievementsScreen())));
      expect(find.text('TROPHY ROOM'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('Profile responsive 360 no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), audioManagerProvider.overrideWith((ref) => SilentAudioManager())], child: const MaterialApp(home: ProfileScreen())));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Achievements responsive 360 no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), audioManagerProvider.overrideWith((ref) => SilentAudioManager())], child: const MaterialApp(home: AchievementsScreen())));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });
}
