import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/games/hub/presentation/game_hub_screen.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';

void main() {
  group('Phase5 Premium Arcade', () {
    testWidgets('all 14 games discoverable in All filter', (tester) async {
      tester.view.physicalSize = const Size(1200, 5800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'Variables')));
      // All filter is default, all games grid shows 14
      expect(find.text('QUIZ BATTLE'), findsWidgets);
      expect(find.text('MEMORY MATCH'), findsWidgets);
      expect(find.text('SNAKE & LADDER'), findsWidgets);
      // Check 14 definitions
      expect(GameDefinition.all.length, 14);
      // Featured card present
      expect(find.text('FEATURED'), findsOneWidget);
      expect(find.text('PLAY FEATURED'), findsOneWidget);
    });

    testWidgets('category filtering works - Battle shows only battle games', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1')));
      expect(find.text('ALL'), findsOneWidget);
      // Tap Battle filter chip specifically (avoid card BATTLE pills)
      await tester.tap(find.widgetWithText(ChoiceChip, 'BATTLE'));
      await tester.pumpAndSettle();
      // Should show filtered count pill
      expect(find.textContaining('BATTLE'), findsWidgets);
      // At least Quiz Battle and Boss Battle are battle category
      expect(find.text('QUIZ BATTLE'), findsWidgets);
      expect(find.text('BOSS BATTLE'), findsWidgets);
      // Memory Match (memory category) should be filtered out
      expect(find.text('MEMORY MATCH'), findsNothing);
    });

    testWidgets('Arcade header shows energetic subtitle and 14 count', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'Control Flow', subjectId: 's1', subjectName: 'Java')));
      expect(find.text('ARCADE'), findsWidgets);
      expect(find.text('14 GAMES'), findsWidgets);
      expect(find.text('Train your skills through challenges, puzzles and battles.'), findsOneWidget);
      expect(find.textContaining('JAVA'), findsWidgets);
    });

    testWidgets('subject vs general context preserved in card semantics', (tester) async {
      tester.view.physicalSize = const Size(1200, 5800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'Control Flow', subjectId: 's1', subjectName: 'Java')));
      expect(find.bySemanticsLabel(RegExp(r'subject Java')), findsWidgets);
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'Variables')));
      expect(find.bySemanticsLabel(RegExp(r'general game')), findsWidgets);
    });

    testWidgets('responsive 360 filter does not overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'A very long topic name that should not overflow on tiny screens', subjectId: 's1', subjectName: 'A very long subject name')) );
      expect(tester.takeException(), isNull);
      // Filters single scroll view should be present, not overflow
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('light and dark theme header renders', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData.light(), home: const GameHubScreen(topicId: 't1')));
      expect(find.text('GAME ARENA'), findsOneWidget);
      await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: const GameHubScreen(topicId: 't1')));
      expect(find.text('GAME ARENA'), findsOneWidget);
    });
  });
}
