import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/game_engine/engine/game_combo.dart';

void main() {
  group('GameCombo', () {
    test('initial state', () {
      final c = GameCombo();
      expect(c.current, 0);
      expect(c.max, 0);
      expect(c.isHot, false);
      expect(c.isOnFire, false);
    });

    test('hit increments and tracks max', () {
      final c = GameCombo();
      c.registerHit();
      expect(c.current, 1);
      expect(c.max, 1);
      c.registerHit();
      c.registerHit();
      expect(c.current, 3);
      expect(c.max, 3);
      expect(c.isHot, true);
      expect(c.label, contains('COMBO'));
    });

    test('miss resets current but retains max', () {
      final c = GameCombo();
      c.registerHit();
      c.registerHit();
      c.registerMiss();
      expect(c.current, 0);
      expect(c.max, 2);
    });

    test('onFire at 5', () {
      final c = GameCombo();
      for (var i = 0; i < 5; i++) c.registerHit();
      expect(c.isOnFire, true);
      expect(c.label, contains('ON FIRE'));
    });

    test('godlike at 10', () {
      final c = GameCombo();
      for (var i = 0; i < 10; i++) c.registerHit();
      expect(c.label, contains('GODLIKE'));
    });

    test('reset clears', () {
      final c = GameCombo();
      for (var i = 0; i < 4; i++) c.registerHit();
      c.reset();
      expect(c.current, 0);
      expect(c.max, 0);
    });
  });
}
