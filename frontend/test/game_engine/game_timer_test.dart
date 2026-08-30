import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/game_engine/engine/game_timer.dart';

void main() {
  group('GameTimer', () {
    test('initial remaining equals total', () {
      final t = GameTimer(totalSeconds: 30);
      expect(t.totalSeconds, 30);
      expect(t.remaining, 30);
      t.dispose();
    });

    test('progress calculation', () {
      final t = GameTimer(totalSeconds: 20);
      expect(t.progress, 1.0);
      t.dispose();
    });

    test('start sets remaining and elapsed', () async {
      final t = GameTimer(totalSeconds: 5);
      t.start();
      expect(t.remaining, 5);
      expect(t.elapsedSeconds, 0);
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(t.remaining, 4);
      expect(t.elapsedSeconds, 1);
      t.dispose();
    });

    test('pause and resume', () async {
      final t = GameTimer(totalSeconds: 10);
      t.start();
      await Future.delayed(const Duration(milliseconds: 1100));
      t.pause();
      final pausedRem = t.remaining;
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(t.remaining, pausedRem);
      t.resume();
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(t.remaining, pausedRem - 1);
      t.dispose();
    });

    test('addSeconds caps at total', () {
      final t = GameTimer(totalSeconds: 10);
      t.start();
      t.deductSeconds(5);
      expect(t.remaining, 5);
      t.addSeconds(10);
      expect(t.remaining, 10);
      t.dispose();
    });

    test('deduct triggers completion when reaches zero', () async {
      final t = GameTimer(totalSeconds: 10);
      var completed = false;
      t.onComplete = () => completed = true;
      t.start();
      t.deductSeconds(10);
      expect(t.remaining, 0);
      expect(completed, true);
      t.dispose();
    });

    test('reset restores', () {
      final t = GameTimer(totalSeconds: 15);
      t.start();
      t.deductSeconds(5);
      t.reset();
      expect(t.remaining, 15);
      expect(t.elapsedSeconds, 0);
      t.dispose();
    });
  });

  group('GameStopwatch', () {
    test('counts up', () async {
      final s = GameStopwatch();
      s.start();
      expect(s.elapsed, 0);
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(s.elapsed, 1);
      s.dispose();
    });

    test('pause holds', () async {
      final s = GameStopwatch();
      s.start();
      await Future.delayed(const Duration(milliseconds: 1100));
      s.pause();
      final e = s.elapsed;
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(s.elapsed, e);
      s.resume();
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(s.elapsed, e + 1);
      s.dispose();
    });
  });
}
