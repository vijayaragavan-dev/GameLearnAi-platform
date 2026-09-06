import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/async/async_generation.dart';

void main() {
  group('A11 State Consistency', () {
    test('AsyncGeneration bump creates current token', () {
      final g = AsyncGeneration();
      final t = g.bump();
      expect(t.isCurrent(g), isTrue);
    });

    test('AsyncGeneration bump invalidates previous', () {
      final g = AsyncGeneration();
      final a = g.bump();
      g.bump();
      expect(a.isCurrent(g), isFalse);
    });

    test('AsyncGeneration reset invalidates all', () {
      final g = AsyncGeneration();
      g.bump();
      g.bump();
      g.reset();
      // After reset, current increased; future bumps are current
      final after = g.bump();
      expect(after.isCurrent(g), isTrue);
    });
  });
}
