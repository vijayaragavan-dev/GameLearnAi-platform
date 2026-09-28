import '../models/game_models.dart';

/// Centralized scoring logic for all games. Pure, deterministic.
/// Mirrors backend XpCalculator semantics where possible (base 10 + perf).
class GameScoring {
  const GameScoring._();

  /// Base points per correct answer/match.
  static const int basePerCorrect = 100;

  /// Fast-answer bonus thresholds (seconds remaining or response time).
  /// Response within fastThreshold awards bonus.
  static int speedBonus({required int responseTimeSeconds, int fastThreshold = 5}) {
    if (responseTimeSeconds <= 3) return 30;
    if (responseTimeSeconds <= fastThreshold) return 15;
    if (responseTimeSeconds <= 8) return 5;
    return 0;
  }

  /// Combo bonus: +10% per combo step beyond 1, capped at +50%.
  static int comboBonus({required int baseScore, required int combo}) {
    if (combo < 2) return 0;
    final pct = (combo - 1) * 10;
    final capped = pct > 50 ? 50 : pct;
    return (baseScore * capped) ~/ 100;
  }

  /// Difficulty multiplier applied to total.
  /// Easy 1.0x, Medium 1.2x, Hard 1.5x
  static double difficultyMultiplier(GameDifficulty d) => switch (d) {
        GameDifficulty.easy => 1.0,
        GameDifficulty.medium => 1.2,
        GameDifficulty.hard => 1.5,
      };

  /// Full score for one correct action.
  static int scoreForHit({
    required GameDifficulty difficulty,
    required int combo,
    required int responseTimeSeconds,
  }) {
    final base = basePerCorrect;
    final sBonus = speedBonus(responseTimeSeconds: responseTimeSeconds);
    final cBonus = comboBonus(baseScore: base, combo: combo);
    final raw = base + sBonus + cBonus;
    final mult = difficultyMultiplier(difficulty);
    return (raw * mult).round();
  }

  /// XP preview derived similarly to backend formula for display purposes.
  /// Returns honest preview: base 10 + performance scaled accuracy.
  /// For non-quiz games, we use accuracy as proxy for performance XP.
  static int xpPreview({required double accuracy}) {
    const base = 10;
    final perf = (accuracy * 0.15).round(); // mirrors XpCalculator 0.15 factor
    return base + perf;
  }

  /// Difficulty bonus XP additive.
  static int difficultyBonusXp(GameDifficulty d) => switch (d) {
        GameDifficulty.easy => 0,
        GameDifficulty.medium => 5,
        GameDifficulty.hard => 10,
      };

  /// Total XP including difficulty bonus.
  static int totalXpPreview({
    required double accuracy,
    required GameDifficulty difficulty,
    int comboMax = 0,
  }) {
    final base = xpPreview(accuracy: accuracy);
    final diff = difficultyBonusXp(difficulty);
    final combo = comboMax >= 5 ? 5 : (comboMax >= 3 ? 2 : 0);
    return base + diff + combo;
  }

  /// Utility to compute accuracy.
  static double accuracy({required int correct, required int total}) {
    if (total == 0) return 0;
    return (correct / total * 100);
  }
}
