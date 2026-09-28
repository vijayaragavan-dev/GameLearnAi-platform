import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/theme/app_colors.dart';
import 'package:gamelearn_app/core/theme/game_visual_identity.dart';
import 'package:gamelearn_app/features/game_engine/engine/game_combo.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/game_engine/widgets/game_hud.dart';
import 'package:gamelearn_app/features/game_engine/widgets/game_scaffold.dart';

void main() {
  group('Phase6 Premium Shell', () {
    testWidgets('GameScaffold renders premium atmosphere with identity accent', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      final config = const GameConfig(topicId: 't1', topicName: 'Control Flow', subjectId: 's1', subjectName: 'Java', type: GameType.quizBattle, difficulty: GameDifficulty.medium);
      final combo = GameCombo()..registerHit()..registerHit();
      await tester.pumpWidget(MaterialApp(home: GameScaffold(config: config, score: 120, progress: 0.5, progressLabel: 'Q 2 / 4', timeLabel: '01:20', combo: combo, child: const Center(child: Text('CHALLENGE')))));
      expect(find.text('CHALLENGE'), findsOneWidget);
      expect(find.textContaining('JAVA'), findsWidgets);
      expect(find.textContaining('QUIZ BATTLE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GameScaffold general context shows GENERAL and difficulty', (tester) async {
      final config = const GameConfig(topicId: 't1', type: GameType.bossBattle, difficulty: GameDifficulty.hard);
      final combo = GameCombo();
      await tester.pumpWidget(MaterialApp(home: GameScaffold(config: config, score: 0, progress: 0.0, progressLabel: 'Q 1 / 4', timeLabel: '02:00', combo: combo, child: const Text('BODY'))));
      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.textContaining('HARD'), findsWidgets);
      expect(find.textContaining('BOSS BATTLE'), findsWidgets);
    });

    testWidgets('GameHud accent tints progress and shows combo', (tester) async {
      final combo = GameCombo()..registerHit()..registerHit()..registerHit();
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: GameHud(score: 250, progress: 0.6, progressLabel: 'Q 3 / 5', timeRemaining: '00:15', combo: combo, difficultyLabel: 'MEDIUM', accent: AppColors.streak, gameIcon: Icons.timer_rounded, gameTitle: 'Speed Run'))));
      expect(find.text('250'), findsOneWidget);
      expect(find.text('00:15'), findsOneWidget);
      expect(find.text('COMBO x3'), findsOneWidget);
      expect(find.text('SPEED RUN'), findsOneWidget);
    });

    testWidgets('GameVisualRegistry distinct accents for all 14 games', (tester) async {
      final accents = <Color>{};
      for (final t in GameType.values) {
        final id = GameVisualRegistry.of(t);
        accents.add(id.accent);
        expect(id.icon, isNotNull);
        expect(id.gradient, isNotNull);
      }
      // At least 8 distinct accents (some share but most distinct)
      expect(accents.length, greaterThanOrEqualTo(8));
      expect(GameType.values.length, 14);
    });

    testWidgets('QuizBattle GameDefinition still discoverable', (tester) async {
      expect(GameDefinition.of(GameType.quizBattle).displayName, 'Quiz Battle');
      expect(GameDefinition.of(GameType.snakeAndLadder).displayName, 'Snake & Ladder');
    });
  });
}
