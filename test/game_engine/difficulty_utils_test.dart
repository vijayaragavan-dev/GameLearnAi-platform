import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/game_engine/utils/difficulty_utils.dart';

void main() {
  group('DifficultyUtils', () {
    test('timeLimitFor per game and difficulty', () {
      expect(DifficultyUtils.timeLimitFor(GameDifficulty.easy, GameType.quizBattle), 25);
      expect(DifficultyUtils.timeLimitFor(GameDifficulty.hard, GameType.quizBattle), 12);
      expect(DifficultyUtils.timeLimitFor(GameDifficulty.easy, GameType.memoryMatch), 120);
      expect(DifficultyUtils.timeLimitFor(GameDifficulty.medium, GameType.speedRun), 45);
    });

    test('fromMasteryLevel mapping', () {
      expect(DifficultyUtils.fromMasteryLevel('MASTERED'), GameDifficulty.hard);
      expect(DifficultyUtils.fromMasteryLevel('PROFICIENT'), GameDifficulty.medium);
      expect(DifficultyUtils.fromMasteryLevel('BEGINNER'), GameDifficulty.easy);
      expect(DifficultyUtils.fromMasteryLevel('unknown'), GameDifficulty.easy);
    });

    test('resolve deterministic rule', () {
      // mastery takes precedence
      expect(DifficultyUtils.resolve(masteryLevel: 'MASTERED', topicDifficulty: 'EASY'), GameDifficulty.hard);
      expect(DifficultyUtils.resolve(topicDifficulty: 'HARD'), GameDifficulty.hard);
      expect(DifficultyUtils.resolve(topicDifficulty: 'MEDIUM'), GameDifficulty.medium);
      expect(DifficultyUtils.resolve(), GameDifficulty.medium);
    });

    test('fromString parsing', () {
      expect(GameDifficulty.fromString('EASY'), GameDifficulty.easy);
      expect(GameDifficulty.fromString('medium'), GameDifficulty.medium);
      expect(GameDifficulty.fromString('HARD'), GameDifficulty.hard);
      expect(GameDifficulty.fromString('unknown'), GameDifficulty.easy);
    });
  });
}
