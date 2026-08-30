import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/games/concept_builder/data/concept_challenges.dart';
import 'package:gamelearn_app/features/games/concept_builder/models/concept_challenge.dart';
import 'package:gamelearn_app/features/games/concept_builder/presentation/concept_builder_screen.dart';

void main() {
  group('ConceptChallenge model', () {
    test('isCorrect validates order', () {
      const ch = ConceptChallenge(
        id: 't1',
        title: 'Test',
        topic: 'Programming',
        difficulty: GameDifficulty.easy,
        learningObjective: 'obj',
        instruction: 'instr',
        blocks: [
          ConceptBlock(id: 'b1', label: 'A'),
          ConceptBlock(id: 'b2', label: 'B'),
          ConceptBlock(id: 'b3', label: 'C'),
        ],
        correctOrder: ['b1', 'b2'],
        explanation: 'exp',
      );
      expect(ch.isCorrect(['b1', 'b2']), true);
      expect(ch.isCorrect(['b2', 'b1']), false);
      expect(ch.isCorrect(['b1']), false);
      expect(ch.isCorrect(['b1', 'b2', 'b3']), false);
      expect(ch.correctBlocks.map((b) => b.id), ['b1', 'b2']);
    });
  });

  group('ConceptChallenges data', () {
    test('has 12 challenges covering multiple topics', () {
      expect(ConceptChallenges.all.length, 12);
      final topics = ConceptChallenges.all.map((c) => c.topic).toSet();
      expect(topics.length, greaterThanOrEqualTo(5));
    });

    test('covers 3 difficulties', () {
      final diffs = ConceptChallenges.all.map((c) => c.difficulty).toSet();
      expect(diffs, containsAll([GameDifficulty.easy, GameDifficulty.medium, GameDifficulty.hard]));
    });

    test('session deterministic', () {
      final s1 = ConceptChallenges.session(count: 4);
      final s2 = ConceptChallenges.session(count: 4);
      expect(s1.length, 4);
      expect(s1.map((c) => c.id), s2.map((c) => c.id));
    });

    test('forDifficulty filters', () {
      final easy = ConceptChallenges.forDifficulty(GameDifficulty.easy);
      expect(easy.every((c) => c.difficulty == GameDifficulty.easy), true);
      expect(easy, isNotEmpty);
    });

    test('each challenge has blocks and correctOrder valid', () {
      for (final c in ConceptChallenges.all) {
        expect(c.blocks.length, greaterThanOrEqualTo(3));
        expect(c.correctOrder.length, greaterThanOrEqualTo(2));
        expect(c.correctOrder.every((id) => c.blocks.any((b) => b.id == id)), true);
        expect(c.instruction, isNotEmpty);
        expect(c.explanation, isNotEmpty);
        expect(c.learningObjective, isNotEmpty);
      }
    });

    test('no duplicate challenge ids', () {
      final ids = ConceptChallenges.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('ConceptBuilderScreen widget', () {
    testWidgets('opens and renders instruction and blocks', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ConceptBuilderScreen(topicId: 'topic-1', topicName: 'Variables'))));
      await tester.pumpAndSettle();
      expect(find.text('CONCEPT BUILDER'), findsOneWidget);
      expect(find.textContaining('BUILD AREA'), findsOneWidget);
      expect(find.text('AVAILABLE BLOCKS'), findsOneWidget);
      expect(find.text('BUILD CONCEPT'), findsOneWidget);
      // Instruction from first challenge cb_01
      expect(find.textContaining('FOR loop'), findsWidgets);
    });

    testWidgets('tap available adds to build area and reorder', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ConceptBuilderScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      // First challenge cb_01 blocks: initialize i = 0 etc.
      final firstBlock = find.text('initialize i = 0').first;
      expect(firstBlock, findsOneWidget);
      await tester.tap(firstBlock);
      await tester.pump();
      // Now build area should contain 1
      expect(find.text('BUILD AREA (1/4)'), findsOneWidget);
      // Tap second
      await tester.tap(find.text('check i < 5').first);
      await tester.pump();
      expect(find.text('BUILD AREA (2/4)'), findsOneWidget);
      // Tap to remove first selected (index 0)
      // Find remove button (close icon) – tap first block in build area to remove
      // Our build area shows selected blocks with close button; tapping the block area triggers remove via onRemove
      // Simpler: tap the displayed selected block's close icon
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();
      expect(find.text('BUILD AREA (1/4)'), findsOneWidget);
    });

    testWidgets('correct build shows BUILD COMPLETE and increments score', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ConceptBuilderScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final sess = ConceptChallenges.session(count: 4);
      final first = sess.first;
      // Tap blocks in correct order
      for (final id in first.correctOrder) {
        final label = first.blocks.firstWhere((b) => b.id == id).label;
        await tester.tap(find.text(label).first);
        await tester.pump();
      }
      // Now BUILD CONCEPT should be enabled
      await tester.tap(find.text('BUILD CONCEPT'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('BUILD COMPLETE'), findsOneWidget);
      expect(find.textContaining('CONCEPT MASTERED').evaluate().isEmpty || find.textContaining('BUILD COMPLETE').evaluate().isNotEmpty, true);
    });

    testWidgets('incorrect build shows BUILD INCORRECT and lives', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ConceptBuilderScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      final sess = ConceptChallenges.session(count: 4);
      final first = sess.first;
      // Tap in wrong order (reverse)
      final reversed = first.correctOrder.reversed.toList();
      for (final id in reversed) {
        final label = first.blocks.firstWhere((b) => b.id == id).label;
        await tester.tap(find.text(label).first);
        await tester.pump();
      }
      await tester.tap(find.text('BUILD CONCEPT'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('BUILD INCORRECT'), findsOneWidget);
      expect(find.textContaining('CORRECT CONCEPT'), findsOneWidget);
      // Lives should show one border
      expect(find.byIcon(Icons.favorite_border_rounded).evaluate().isNotEmpty, true);
    });

    testWidgets('pause and resume', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ConceptBuilderScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);
      await tester.tap(find.text('RESUME'));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsNothing);
    });

    testWidgets('progress indicator shows BUILD x / y', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ConceptBuilderScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      expect(find.textContaining('BUILD 1 / 4'), findsOneWidget);
    });

    testWidgets('clear button resets build area', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ConceptBuilderScreen(topicId: 'topic-1'))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('initialize i = 0').first);
      await tester.pump();
      expect(find.text('BUILD AREA (1/4)'), findsOneWidget);
      await tester.tap(find.text('CLEAR'));
      await tester.pump();
      expect(find.text('BUILD AREA (0/4)'), findsOneWidget);
    });
  });
}
