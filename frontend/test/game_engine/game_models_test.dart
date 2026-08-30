import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';

void main() {
  group('GameModels', () {
    test('GameResult performance labels', () {
      GameResult r(double acc) => GameResult(
            config: const GameConfig(topicId: 't', type: GameType.quizBattle, difficulty: GameDifficulty.medium),
            score: 100,
            accuracy: acc,
            correctCount: 5,
            totalQuestions: 10,
            timeElapsedSeconds: 30,
            comboMax: 2,
            xpEarned: 10,
            completedAt: DateTime.now(),
          );
      expect(r(95).performanceLabel, 'LEGENDARY');
      expect(r(80).performanceLabel, 'EXCELLENT');
      expect(r(60).performanceLabel, 'GOOD');
      expect(r(40).performanceLabel, 'FAIR');
      expect(r(10).performanceLabel, 'KEEP TRYING');
    });

    test('GameResult isPerfect and isSuccess', () {
      final perfect = GameResult(
        config: const GameConfig(topicId: 't', type: GameType.memoryMatch, difficulty: GameDifficulty.easy),
        score: 500,
        accuracy: 100,
        correctCount: 6,
        totalQuestions: 6,
        timeElapsedSeconds: 60,
        comboMax: 3,
        xpEarned: 20,
        completedAt: DateTime.now(),
      );
      expect(perfect.isPerfect, true);
      expect(perfect.isSuccess, true);

      final fail = GameResult(
        config: const GameConfig(topicId: 't', type: GameType.dragDrop, difficulty: GameDifficulty.easy),
        score: 50,
        accuracy: 30,
        correctCount: 1,
        totalQuestions: 6,
        timeElapsedSeconds: 60,
        comboMax: 0,
        xpEarned: 10,
        completedAt: DateTime.now(),
      );
      expect(fail.isPerfect, false);
      expect(fail.isSuccess, false);
    });

    test('GameDefinition all contains fourteen approved games (incl Snake & Ladder)', () {
      expect(GameDefinition.all.length, 14);
      expect(GameDefinition.all.map((d) => d.type), containsAll([GameType.quizBattle, GameType.memoryMatch, GameType.dragDrop, GameType.speedRun, GameType.debugArena, GameType.unlockCode, GameType.conceptBuilder, GameType.sequenceMaster, GameType.targetChallenge, GameType.mysteryCase, GameType.bossBattle, GameType.puzzleArena, GameType.connectivityLab, GameType.snakeAndLadder]));
    });

    test('GameDifficulty apiValue', () {
      expect(GameDifficulty.easy.apiValue, 'EASY');
      expect(GameDifficulty.hard.displayName, 'Hard');
    });
  });
}
