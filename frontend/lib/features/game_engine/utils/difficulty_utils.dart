import '../models/game_models.dart';

/// Difficulty helpers: time limits, scoring labels, adaptation from mastery.
abstract final class DifficultyUtils {
  static int timeLimitFor(GameDifficulty d, GameType type) {
    // Per-game tuned time limits.
    switch (type) {
      case GameType.quizBattle:
        return switch (d) { GameDifficulty.easy => 25, GameDifficulty.medium => 18, GameDifficulty.hard => 12 };
      case GameType.memoryMatch:
        return switch (d) { GameDifficulty.easy => 120, GameDifficulty.medium => 90, GameDifficulty.hard => 60 };
      case GameType.dragDrop:
        return switch (d) { GameDifficulty.easy => 180, GameDifficulty.medium => 120, GameDifficulty.hard => 90 };
      case GameType.speedRun:
        return switch (d) { GameDifficulty.easy => 60, GameDifficulty.medium => 45, GameDifficulty.hard => 30 };
      case GameType.debugArena:
        return switch (d) { GameDifficulty.easy => 150, GameDifficulty.medium => 120, GameDifficulty.hard => 90 };
      case GameType.unlockCode:
        return switch (d) { GameDifficulty.easy => 180, GameDifficulty.medium => 150, GameDifficulty.hard => 120 };
      case GameType.conceptBuilder:
        return switch (d) { GameDifficulty.easy => 180, GameDifficulty.medium => 150, GameDifficulty.hard => 120 };
      case GameType.sequenceMaster:
        return switch (d) { GameDifficulty.easy => 200, GameDifficulty.medium => 160, GameDifficulty.hard => 120 };
      case GameType.targetChallenge:
        return switch (d) { GameDifficulty.easy => 180, GameDifficulty.medium => 150, GameDifficulty.hard => 120 };
      case GameType.mysteryCase:
        return switch (d) { GameDifficulty.easy => 180, GameDifficulty.medium => 150, GameDifficulty.hard => 120 };
      case GameType.bossBattle:
        return switch (d) { GameDifficulty.easy => 180, GameDifficulty.medium => 150, GameDifficulty.hard => 120 };
      case GameType.puzzleArena:
        return switch (d) { GameDifficulty.easy => 180, GameDifficulty.medium => 150, GameDifficulty.hard => 120 };
      case GameType.connectivityLab:
        return switch (d) { GameDifficulty.easy => 180, GameDifficulty.medium => 150, GameDifficulty.hard => 120 };
      case GameType.snakeAndLadder:
        return switch (d) { GameDifficulty.easy => 300, GameDifficulty.medium => 240, GameDifficulty.hard => 180 };
    }
  }

  static String label(GameDifficulty d) => d.displayName;

  static GameDifficulty fromMasteryLevel(String level) => switch (level.toUpperCase()) {
        'MASTERED' => GameDifficulty.hard,
        'PROFICIENT' => GameDifficulty.medium,
        _ => GameDifficulty.easy,
      };

  static GameDifficulty fromTopicDifficulty(String difficulty) =>
      GameDifficulty.fromString(difficulty);

  /// Deterministic rule documented per spec requirement.
  /// If adaptive difficulty is available from topic/progress, use it; otherwise
  /// use topic's static difficulty. No AI-driven adjustment in this phase.
  static GameDifficulty resolve({
    String? topicDifficulty,
    String? masteryLevel,
  }) {
    if (masteryLevel != null && masteryLevel.isNotEmpty) {
      return fromMasteryLevel(masteryLevel);
    }
    if (topicDifficulty != null) return fromTopicDifficulty(topicDifficulty);
    return GameDifficulty.medium;
  }
}
