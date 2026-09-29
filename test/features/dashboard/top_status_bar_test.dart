import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/models/dashboard_models.dart';
import 'package:gamelearn_app/core/models/gamification_models.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gamelearn_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDashboardController extends DashboardController {
  _FakeDashboardController(this._dashboard);
  final Dashboard _dashboard;

  @override
  DashboardState build() => DashboardState(data: _dashboard);

  @override
  Future<void> load() async {}
}

Dashboard _createTestDashboard({int totalXp = 9999, int currentStreakDays = 99}) {
  return Dashboard(
    learner: const LearnerOverview(
      displayName: 'Test Player',
      overallMastery: 75.0,
      currentSubjectId: null,
      currentTopicId: null,
    ),
    currentSubject: null,
    mastery: const MasterySummary(
      topicsAssessed: 5,
      topicsMastered: 3,
      recentTopics: [],
    ),
    gamification: DashGamification(
      totalXp: totalXp,
      currentLevel: 5,
      maxLevel: 50,
      nextLevelThresholdXp: 12000,
      xpToNextLevel: 2001,
    ),
    streak: StreakState(
      currentStreakDays: currentStreakDays,
      longestStreakDays: 100,
      lastLearningDate: null,
      timezone: 'UTC',
    ),
    achievements: const DashAchievements(
      unlockedCount: 10,
      recentUnlocks: [],
    ),
    recommendations: const [],
    learningPath: null,
    assessment: const AssessmentCoverage(assessedSubjects: []),
    recentActivity: const RecentActivityView(quizzes: []),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('Top status bar, Hero level/rank, and Game Zone render without RenderFlex overflow on 320px screen', (tester) async {
    // Narrow 320px screen constraint
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testDashboard = _createTestDashboard();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dashboardProvider.overrideWith(() => _FakeDashboardController(testDashboard)),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify streak and stats chips render
    expect(find.textContaining('99 DAYS'), findsOneWidget);
    expect(find.textContaining('9999 XP'), findsOneWidget);
    expect(find.textContaining('5/5'), findsOneWidget);

    // Verify Level & Rank buttons render in Hero card
    expect(find.textContaining('LEVEL 05'), findsWidgets);
    expect(find.textContaining('RANK'), findsWidgets);

    // Verify Game Zone button renders
    expect(find.text('EXPLORE ALL 14 GAMES'), findsOneWidget);

    // Verify no RenderFlex overflow exception occurred
    expect(tester.takeException(), isNull);
  });
}
