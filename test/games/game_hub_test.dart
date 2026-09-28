import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/games/hub/presentation/game_hub_screen.dart';

void main() {
  group('GameHubScreen', () {
    testWidgets('renders all fourteen game cards incl Snake & Ladder', (tester) async {
      tester.view.physicalSize = const Size(1200, 5800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 'topic-1', topicName: 'Variables')));
      expect(find.text('GAME ARENA'), findsOneWidget);
      expect(find.text('QUIZ BATTLE'), findsOneWidget);
      expect(find.text('MEMORY MATCH'), findsOneWidget);
      expect(find.text('DRAG & DROP'), findsOneWidget);
      expect(find.text('SPEED RUN'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -2800));
      await tester.pumpAndSettle();
      expect(find.text('DEBUG ARENA'), findsOneWidget);
      expect(find.text('UNLOCK THE CODE'), findsOneWidget);
      expect(find.text('CONCEPT BUILDER'), findsOneWidget);
      expect(find.text('SEQUENCE MASTER'), findsOneWidget);
      expect(find.text('TARGET CHALLENGE'), findsOneWidget);
      expect(find.text('MYSTERY CASE'), findsOneWidget);
      expect(find.text('BOSS BATTLE'), findsOneWidget);
      expect(find.text('PUZZLE ARENA'), findsOneWidget);
      expect(find.text('CONNECTIVITY LAB'), findsOneWidget);
      expect(find.text('SNAKE & LADDER'), findsOneWidget);
    });

    testWidgets('shows topic name when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'My Topic')));
      expect(find.text('My Topic'), findsOneWidget);
    });

    testWidgets('shows info about XP', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1')));
      // Scroll to bottom to reveal info card
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.textContaining('real XP'), findsOneWidget);
    });
  });
}
