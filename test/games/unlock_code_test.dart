import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/games/unlock_code/data/unlock_challenges.dart';
import 'package:gamelearn_app/features/games/unlock_code/models/unlock_challenge.dart';
import 'package:gamelearn_app/features/games/unlock_code/presentation/unlock_code_screen.dart';

void main() {
  group('VaultCode', () {
    test('creates and reports length/display', () {
      const vault = VaultCode(fragments: ['7', '2', '9', '4']);
      expect(vault.length, 4);
      expect(vault.display, '7 2 9 4');
      expect(vault.codeString, '7294');
    });

    test('revealed and isUnlocked', () {
      const vault = VaultCode(fragments: ['7', '2', '9', '4']);
      expect(vault.revealed(0), [null, null, null, null]);
      expect(vault.revealed(2), ['7', '2', null, null]);
      expect(vault.revealed(4), ['7', '2', '9', '4']);
      expect(vault.isUnlocked(3), false);
      expect(vault.isUnlocked(4), true);
      expect(vault.isUnlocked(5), true);
    });
  });

  group('UnlockChallenge model', () {
    test('isCorrect checks equality', () {
      const ch = UnlockChallenge(
        id: 't1',
        title: 'Test',
        topic: 'Programming',
        difficulty: GameDifficulty.easy,
        prompt: 'What?',
        choices: ['A', 'B', 'C', 'D'],
        correctAnswer: 'B',
        explanation: 'exp',
        codeReward: '7',
      );
      expect(ch.isCorrect('B'), true);
      expect(ch.isCorrect('A'), false);
    });
  });

  group('UnlockChallenges data', () {
    test('covers multiple topics and difficulties', () {
      final topics = UnlockChallenges.all.map((c) => c.topic).toSet();
      expect(topics.length, greaterThanOrEqualTo(3));
      final diffs = UnlockChallenges.all.map((c) => c.difficulty).toSet();
      expect(diffs, containsAll([GameDifficulty.easy, GameDifficulty.medium, GameDifficulty.hard]));
    });

    test('vault code is 7 2 9 4', () {
      expect(UnlockChallenges.vaultCode.display, '7 2 9 4');
      expect(UnlockChallenges.vaultCode.length, 4);
    });

    test('session deterministic and correct length', () {
      final s1 = UnlockChallenges.session(count: 4);
      final s2 = UnlockChallenges.session(count: 4);
      expect(s1.length, 4);
      expect(s1.map((c) => c.id), s2.map((c) => c.id));
    });

    test('forDifficulty filters', () {
      final easy = UnlockChallenges.forDifficulty(GameDifficulty.easy);
      expect(easy.every((c) => c.difficulty == GameDifficulty.easy), true);
      expect(easy, isNotEmpty);
    });

    test('all challenges have 4 choices and codeReward in vault', () {
      for (final c in UnlockChallenges.all) {
        expect(c.choices.length, 4, reason: 'challenge ${c.id} choices');
        expect(c.choices, contains(c.correctAnswer));
        expect(c.codeReward, isNotEmpty);
        expect(c.codeReward.length, 1);
        expect(UnlockChallenges.vaultCode.fragments, contains(c.codeReward));
      }
    });

    test('vaultForSession aligns with session length', () {
      final sess = UnlockChallenges.session(count: 4);
      final vault = UnlockChallenges.vaultForSession(sess);
      expect(vault.length, 4);
      expect(vault.display, UnlockChallenges.vaultCode.display);
    });
  });

  group('UnlockCodeScreen widget', () {
    testWidgets('opens and renders vault and first challenge', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: UnlockCodeScreen(topicId: 'topic-1', topicName: 'Variables'))));
      await tester.pumpAndSettle();
      expect(find.text('LOCKED VAULT'), findsOneWidget);
      expect(find.text('UNLOCK THE CODE'), findsOneWidget);
      // Code progress shows ?
      expect(find.text('?'), findsWidgets);
      expect(find.textContaining('CHALLENGE 1'), findsOneWidget);
      expect(find.text('UNLOCK FRAGMENT'), findsOneWidget);
    });

    testWidgets('correct answer reveals code fragment', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: UnlockCodeScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final first = UnlockChallenges.session(count: 4).first;
      // Tap correct choice
      await tester.tap(find.text(first.correctAnswer).first);
      await tester.pump();
      await tester.tap(find.text('UNLOCK FRAGMENT'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('CORRECT!'), findsOneWidget);
      expect(find.textContaining('Fragment ${first.codeReward} unlocked'), findsOneWidget);
      // Vault should now show revealed fragment '7'
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('wrong answer does not reveal fragment and shows access denied', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: UnlockCodeScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final first = UnlockChallenges.session(count: 4).first;
      final wrong = first.choices.firstWhere((c) => c != first.correctAnswer);
      await tester.tap(find.text(wrong).first);
      await tester.pump();
      await tester.tap(find.text('UNLOCK FRAGMENT'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('ACCESS DENIED'), findsOneWidget);
      expect(find.text('Code fragment remains locked.'), findsOneWidget);
      // Should still show ? for first fragment, not 7
      // Check that vault still shows ? (at least 3 ? remain)
      expect(find.text('?'), findsWidgets);
    });

    testWidgets('progression: correct reveals increments challenged index after delay', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: UnlockCodeScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final sess = UnlockChallenges.session(count: 4);
      // Complete first correctly
      await tester.tap(find.text(sess[0].correctAnswer).first);
      await tester.pump();
      await tester.tap(find.text('UNLOCK FRAGMENT'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('CORRECT!'), findsOneWidget);
      // Wait for auto-advance 1500ms
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.textContaining('CHALLENGE 2'), findsOneWidget);
    });

    testWidgets('final unlock shows vault unlocked dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: UnlockCodeScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final sess = UnlockChallenges.session(count: 4);
      for (var i = 0; i < sess.length; i++) {
        await tester.tap(find.text(sess[i].correctAnswer).first);
        await tester.pump();
        await tester.tap(find.text('UNLOCK FRAGMENT'));
        await tester.pump(const Duration(milliseconds: 400));
        if (i < sess.length - 1) {
          await tester.pump(const Duration(milliseconds: 1600));
          await tester.pumpAndSettle();
        }
      }
      // After last correct, feedback then unlock dialog should appear after finishing
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      // Dialog shows VAULT UNLOCKED!
      expect(find.text('VAULT UNLOCKED!'), findsOneWidget);
      expect(find.text('CODE: 7 2 9 4'), findsWidgets);
    });

    testWidgets('lives indicator shows 3 hearts initially and decreases on wrong', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: UnlockCodeScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
      final first = UnlockChallenges.session(count: 4).first;
      final wrong = first.choices.firstWhere((c) => c != first.correctAnswer);
      await tester.tap(find.text(wrong).first);
      await tester.pump();
      await tester.tap(find.text('UNLOCK FRAGMENT'));
      await tester.pump(const Duration(milliseconds: 400));
      // One heart should be border
      expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
    });

    testWidgets('timer displays and pause works', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: UnlockCodeScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);
      await tester.tap(find.text('RESUME'));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsNothing);
    });
  });
}
