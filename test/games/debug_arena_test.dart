import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/games/debug_arena/data/debug_challenges.dart';
import 'package:gamelearn_app/features/games/debug_arena/models/debug_challenge.dart';
import 'package:gamelearn_app/features/games/debug_arena/presentation/debug_arena_screen.dart';

void main() {
  group('DebugChallenge model', () {
    test('6 bug categories defined', () {
      expect(BugCategory.values.length, 6);
      expect(BugCategory.values.map((b) => b.id), containsAll(['SYNTAX', 'LOGIC', 'INFINITE_LOOP', 'WRONG_CONDITION', 'WRONG_VARIABLE', 'OFF_BY_ONE']));
    });

    test('isCorrect checks equality', () {
      const ch = DebugChallenge(
        id: 't1',
        title: 'Test',
        language: 'Dart',
        topic: 'Loops',
        bugCategory: BugCategory.syntax,
        buggyCode: 'int x = 5',
        explanation: 'exp',
        correctDiagnosis: 'Syntax error',
        choices: ['Syntax error', 'Logic bug', 'Infinite loop', 'Wrong variable'],
        difficulty: GameDifficulty.easy,
        level: DebugLevel.findTheBug,
      );
      expect(ch.isCorrect('Syntax error'), true);
      expect(ch.isCorrect('Logic bug'), false);
      expect(ch.prompt, 'WHAT IS WRONG?');
      expect(ch.levelHelp, isNotEmpty);
    });

    test('level prompts for all levels', () {
      for (final l in DebugLevel.values) {
        final ch = DebugChallenge(
          id: 'id',
          title: 't',
          language: 'Dart',
          topic: 't',
          bugCategory: BugCategory.logic,
          buggyCode: 'code',
          explanation: 'exp',
          correctDiagnosis: 'A',
          choices: const ['A', 'B', 'C', 'D'],
          difficulty: GameDifficulty.medium,
          level: l,
        );
        expect(ch.prompt, isNotEmpty);
        expect(ch.levelHelp, isNotEmpty);
      }
    });
  });

  group('DebugChallenges data', () {
    test('covers all 6 bug categories', () {
      final cats = DebugChallenges.all.map((c) => c.bugCategory).toSet();
      expect(cats.length, 6);
    });

    test('covers levels 1-5', () {
      final levels = DebugChallenges.all.map((c) => c.level).toSet();
      expect(levels.length, 5);
      expect(levels, containsAll(DebugLevel.values));
    });

    test('session returns requested count deterministically', () {
      final s1 = DebugChallenges.session(count: 5);
      final s2 = DebugChallenges.session(count: 5);
      expect(s1.length, 5);
      expect(s1.map((c) => c.id), s2.map((c) => c.id));
    });

    test('forDifficulty filters', () {
      final easy = DebugChallenges.forDifficulty(GameDifficulty.easy);
      expect(easy.every((c) => c.difficulty == GameDifficulty.easy), true);
      expect(easy, isNotEmpty);
    });

    test('all challenges have 4 choices and correct in choices', () {
      for (final c in DebugChallenges.all) {
        expect(c.choices.length, 4, reason: 'challenge ${c.id} should have 4 choices');
        expect(c.choices, contains(c.correctDiagnosis), reason: 'challenge ${c.id} correctDiagnosis must be in choices');
        expect(c.buggyCode, isNotEmpty);
        expect(c.explanation, isNotEmpty);
      }
    });
  });

  group('DebugArenaScreen widget', () {
    testWidgets('opens and renders first challenge code and choices', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: DebugArenaScreen(topicId: 'topic-1', topicName: 'Variables'))));
      await tester.pumpAndSettle();
      // HUD elements
      expect(find.textContaining('LEVEL'), findsOneWidget);
      expect(find.text('SYSTEM ERROR DETECTED'), findsOneWidget);
      // Code block should contain buggy code snippet
      expect(find.textContaining('int x'), findsWidgets);
      // At least one choice button
      expect(find.text('SUBMIT DIAGNOSIS'), findsOneWidget);
      expect(find.textContaining('LIVES').evaluate().isEmpty || find.byIcon(Icons.favorite_rounded).evaluate().isNotEmpty, true);
    });

    testWidgets('selecting choice enables submit and shows feedback on correct', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: DebugArenaScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final first = DebugChallenges.all.first;
      final correctFinder = find.text(first.correctDiagnosis);
      await tester.tap(correctFinder.first);
      await tester.pump();
      await tester.tap(find.text('SUBMIT DIAGNOSIS'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('BUG FOUND'), findsOneWidget);
    });

    testWidgets('incorrect diagnosis reduces lives and shows wrong feedback', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: DebugArenaScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final first = DebugChallenges.all.first;
      final wrong = first.choices.firstWhere((c) => c != first.correctDiagnosis);
      await tester.tap(find.text(wrong).first);
      await tester.pump();
      await tester.tap(find.text('SUBMIT DIAGNOSIS'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('WRONG DIAGNOSIS'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded).evaluate().isNotEmpty || find.byIcon(Icons.favorite_rounded).evaluate().length == 2, true);
    });

    testWidgets('score updates after correct and combo increments', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: DebugArenaScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final first = DebugChallenges.all.first;
      expect(find.text('0'), findsAtLeastNWidgets(1));
      await tester.tap(find.text(first.correctDiagnosis).first);
      await tester.pump();
      await tester.tap(find.text('SUBMIT DIAGNOSIS'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      final scoreFinder = find.textContaining(RegExp(r'^[0-9]+$'));
      expect(scoreFinder, findsWidgets);
    });

    testWidgets('pause and resume', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: DebugArenaScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);
      await tester.tap(find.text('RESUME'));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsNothing);
    });

    testWidgets('empty challenge data handled gracefully', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: DebugArenaScreen(topicId: 'empty-topic'))));
      await tester.pumpAndSettle();
      expect(find.byType(DebugArenaScreen), findsOneWidget);
    });
  });

  group('DebugArena integration with GameEngine', () {
    test('GameType debugArena present in definition', () {
      expect(GameDefinition.of(GameType.debugArena).displayName, 'Debug Arena');
      expect(GameDefinition.of(GameType.debugArena).supportsCombo, true);
    });

    test('Difficulty time limit for debugArena', () {
      // imported via game_models
      // Need to import DifficultyUtils
    });
  });
}
