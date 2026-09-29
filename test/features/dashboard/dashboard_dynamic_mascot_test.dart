import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/models/dashboard_models.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/avatar/providers/active_mascot_provider.dart';
import 'package:gamelearn_app/features/avatar/widgets/cartoon_mascot_view.dart';
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

Dashboard _createTestDashboard() {
  return Dashboard.fromJson({
    'learner': {
      'displayName': 'Vijay Dev',
      'overallMastery': 80.0,
      'currentSubjectId': '11111111-1111-1111-1111-111111111101',
      'currentTopicId': '22222222-2222-2222-2222-222222222201',
    },
    'currentSubject': {
      'id': '11111111-1111-1111-1111-111111111101',
      'name': 'Object-Oriented Programming',
      'iconKey': 'oop',
      'currentTopic': {
        'topicId': '22222222-2222-2222-2222-222222222201',
        'topicName': 'Classes & Inheritance',
        'difficulty': 'MEDIUM',
      },
    },
    'mastery': {
      'topicsAssessed': 5,
      'topicsMastered': 4,
      'recentTopics': [],
    },
    'gamification': {
      'totalXp': 3450,
      'currentLevel': 8,
      'maxLevel': 50,
      'nextLevelThresholdXp': 5000,
      'xpToNextLevel': 1550,
    },
    'streak': {
      'currentStreakDays': 14,
      'longestStreakDays': 30,
      'lastLearningDate': null,
      'timezone': 'UTC',
    },
    'achievements': {
      'unlockedCount': 8,
      'recentUnlocks': [],
    },
    'recommendations': [],
    'learningPath': {
      'id': '44444444-4444-4444-4444-444444444401',
      'subjectId': '11111111-1111-1111-1111-111111111101',
      'subjectName': 'Object-Oriented Programming',
      'progressPercent': 40.0,
      'nodes': [
        {
          'id': '33333333-3333-3333-3333-333333333301',
          'topicId': '22222222-2222-2222-2222-222222222201',
          'topicName': 'Classes & Inheritance',
          'nodeType': 'LESSON',
          'status': 'IN_PROGRESS',
          'orderIndex': 0,
        },
      ],
    },
    'assessment': {'assessedSubjects': []},
    'recentActivity': {'quizzes': []},
  });
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('Dashboard dynamically updates character in Hero Card and My Journey Card when changed in Character Studio', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

    // Initially, verify CartoonMascotView is present in both Hero and Journey cards
    final mascotsInitial = tester.widgetList<CartoonMascotView>(find.byType(CartoonMascotView)).toList();
    expect(mascotsInitial.length, greaterThanOrEqualTo(2));

    // Get the element / container to trigger character selection
    final element = tester.element(find.byType(DashboardScreen));
    final container = ProviderScope.containerOf(element);

    // 1. Switch character to Bao Panda
    await container.read(activeMascotProvider.notifier).selectCharacter('bao_panda');
    await tester.pump(const Duration(milliseconds: 100));

    final mascotsBao = tester.widgetList<CartoonMascotView>(find.byType(CartoonMascotView)).toList();
    expect(mascotsBao.length, greaterThanOrEqualTo(2));
    expect(mascotsBao[0].character.id, equals('bao_panda'));
    expect(mascotsBao[1].character.id, equals('bao_panda'));
    expect(find.text('ASK BAO'), findsOneWidget);

    // 2. Switch character to Milo Cat
    await container.read(activeMascotProvider.notifier).selectCharacter('milo_cat');
    await tester.pump(const Duration(milliseconds: 100));

    final mascotsMilo = tester.widgetList<CartoonMascotView>(find.byType(CartoonMascotView)).toList();
    expect(mascotsMilo.length, greaterThanOrEqualTo(2));
    expect(mascotsMilo[0].character.id, equals('milo_cat'));
    expect(mascotsMilo[1].character.id, equals('milo_cat'));
    expect(find.text('ASK MILO'), findsOneWidget);

    // 3. Switch character to Spark Fox
    await container.read(activeMascotProvider.notifier).selectCharacter('spark_fox');
    await tester.pump(const Duration(milliseconds: 100));

    final mascotsSpark = tester.widgetList<CartoonMascotView>(find.byType(CartoonMascotView)).toList();
    expect(mascotsSpark.length, greaterThanOrEqualTo(2));
    expect(mascotsSpark[0].character.id, equals('spark_fox'));
    expect(mascotsSpark[1].character.id, equals('spark_fox'));
    expect(find.text('ASK SPARK'), findsOneWidget);

    // 4. Verify no RenderFlex or visual layout exceptions occurred
    expect(tester.takeException(), isNull);
  });
}
