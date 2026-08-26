import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/gamification_delta.dart';
import 'package:gamelearn_app/core/models/gamification_models.dart';
import 'package:gamelearn_app/core/utils/formatters.dart';

Achievement _ach(String code, {DateTime? unlockedAt}) => Achievement(
  code: code,
  name: code,
  description: '',
  iconKey: 'k',
  xpReward: 10,
  unlockedAt: unlockedAt,
);

void main() {
  group('Formatters', () {
    test('percent rounds', () {
      expect(Formatters.percent(87.5), '88%');
      expect(Formatters.percent(100), '100%');
      expect(Formatters.percent(0), '0%');
    });

    test('count groups thousands', () {
      expect(Formatters.count(1250), '1,250');
      expect(Formatters.count(999), '999');
      expect(Formatters.count(1234567), '1,234,567');
    });

    test('shortDate formats', () {
      expect(Formatters.shortDate(DateTime.utc(2026, 8, 24)), 'Aug 24');
    });
  });

  group('compareSnapshots', () {
    final pre = GamificationSnapshot(
      totalXp: 300,
      currentLevel: 2,
      unlocked: [_ach('FIRST_QUIZ', unlockedAt: DateTime.utc(2026, 8, 1))],
    );
    final post = GamificationSnapshot(
      totalXp: 345,
      currentLevel: 3,
      unlocked: [
        _ach('FIRST_QUIZ', unlockedAt: DateTime.utc(2026, 8, 1)),
        _ach('PERFECT_SCORE', unlockedAt: DateTime.utc(2026, 8, 24)),
      ],
    );

    test('derives xp gain, level-up and fresh unlocks from GAM reads', () {
      final d = compareSnapshots(pre, post);
      expect(d.xpGained, 45);
      expect(d.leveledUpTo, 3);
      expect(d.newAchievements.single.code, 'PERFECT_SCORE');
    });

    test('null snapshots degrade to empty delta', () {
      const d = GamificationDelta();
      expect(d.xpGained, 0);
      expect(compareSnapshots(null, post).xpGained, 0);
      expect(compareSnapshots(pre, null).leveledUpTo, isNull);
    });

    test('no regression produces zero xp delta', () {
      final d = compareSnapshots(post, pre);
      expect(d.xpGained, 0);
      expect(d.leveledUpTo, isNull);
      expect(d.newAchievements, isEmpty);
    });
  });
}
