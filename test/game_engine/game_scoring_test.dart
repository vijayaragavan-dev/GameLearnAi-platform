import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/game_engine/engine/game_scoring.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';

void main() {
  group('GameScoring', () {
    test('basePerCorrect is 100', () => expect(GameScoring.basePerCorrect, 100));

    test('speedBonus fast thresholds', () {
      expect(GameScoring.speedBonus(responseTimeSeconds: 2), 30);
      expect(GameScoring.speedBonus(responseTimeSeconds: 3), 30);
      expect(GameScoring.speedBonus(responseTimeSeconds: 5), 15);
      expect(GameScoring.speedBonus(responseTimeSeconds: 8), 5);
      expect(GameScoring.speedBonus(responseTimeSeconds: 15), 0);
    });

    test('comboBonus scaling capped at 50%', () {
      expect(GameScoring.comboBonus(baseScore: 100, combo: 1), 0);
      expect(GameScoring.comboBonus(baseScore: 100, combo: 2), 10);
      expect(GameScoring.comboBonus(baseScore: 100, combo: 3), 20);
      expect(GameScoring.comboBonus(baseScore: 100, combo: 6), 50);
      expect(GameScoring.comboBonus(baseScore: 100, combo: 10), 50);
    });

    test('difficulty multiplier', () {
      expect(GameScoring.difficultyMultiplier(GameDifficulty.easy), 1.0);
      expect(GameScoring.difficultyMultiplier(GameDifficulty.medium), 1.2);
      expect(GameScoring.difficultyMultiplier(GameDifficulty.hard), 1.5);
    });

    test('scoreForHit combines base+speed+combo with multiplier', () {
      final s = GameScoring.scoreForHit(difficulty: GameDifficulty.easy, combo: 1, responseTimeSeconds: 10);
      expect(s, 100); // base only
      final s2 = GameScoring.scoreForHit(difficulty: GameDifficulty.medium, combo: 3, responseTimeSeconds: 2);
      // base 100 + speed 30 + combo 20% (20) =150 *1.2=180
      expect(s2, 180);
      final s3 = GameScoring.scoreForHit(difficulty: GameDifficulty.hard, combo: 6, responseTimeSeconds: 2);
      // 100+30+50=180*1.5=270
      expect(s3, 270);
    });

    test('xpPreview mirrors backend 0.15 factor', () {
      expect(GameScoring.xpPreview(accuracy: 0), 10);
      expect(GameScoring.xpPreview(accuracy: 100), 25); // 10+15
      expect(GameScoring.xpPreview(accuracy: 66.67), 20); // 10+10
    });

    test('totalXpPreview includes difficulty and combo', () {
      expect(GameScoring.totalXpPreview(accuracy: 100, difficulty: GameDifficulty.easy), 25);
      expect(GameScoring.totalXpPreview(accuracy: 100, difficulty: GameDifficulty.hard), 35);
      expect(GameScoring.totalXpPreview(accuracy: 100, difficulty: GameDifficulty.hard, comboMax: 5), 40);
    });

    test('accuracy helper', () {
      expect(GameScoring.accuracy(correct: 8, total: 12), closeTo(66.66, 0.01));
      expect(GameScoring.accuracy(correct: 0, total: 0), 0);
    });
  });
}
