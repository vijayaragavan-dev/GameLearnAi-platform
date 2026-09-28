import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/shared/widgets/adaptive_next_action.dart';

void main() {
  group('Progress Analytics A8', () {
    testWidgets('AdaptiveNextActionCard renders with action', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdaptiveNextActionCard(
            title: 'Practice Arrays',
            reason: 'Mastery 25% needs practice',
            actionLabel: 'Practice',
            topicName: 'Arrays',
            difficulty: 'EASY',
            gameType: 'quiz_battle',
            onAction: () {},
          ),
        ),
      ));
      expect(find.text('Practice Arrays'), findsOneWidget);
      expect(find.textContaining('needs practice'), findsOneWidget);
      expect(find.text('PRACTICE'), findsOneWidget);
    });

    testWidgets('MasteryBadge renders labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MasteryBadge(score: 85))));
      expect(find.textContaining('MASTERED'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MasteryBadge(score: 30))));
      expect(find.textContaining('DEVELOPING'), findsOneWidget);
    });

    testWidgets('AdaptiveNextActionCard loading and error states', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdaptiveNextActionCard(title: '', reason: '', actionLabel: '', onAction: _noop, isLoading: true))));
      expect(find.textContaining('Loading'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdaptiveNextActionCard(title: '', reason: '', actionLabel: '', onAction: _noop, isError: true, errorMessage: 'Something went wrong'))));
      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('360 responsive no overflow for AdaptiveNextActionCard', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdaptiveNextActionCard(
              title: 'Practice Arrays with a very long topic name that should wrap correctly on tiny screens',
              reason: 'This is a very long reason text that should wrap correctly and not cause overflow on 360 width screens with multiple pills',
              actionLabel: 'Practice',
              topicName: 'Arrays',
              subjectName: 'Data Structures',
              gameType: 'quiz_battle',
              difficulty: 'EASY',
              onAction: () {},
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}

void _noop() {}
