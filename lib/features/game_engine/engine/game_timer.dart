import 'dart:async';

/// Reusable countdown timer for games. Supports start/pause/resume/reset.
/// Emits remaining seconds via stream and callback. Handles completion.
class GameTimer {
  GameTimer({required this.totalSeconds}) : _remaining = totalSeconds;

  final int totalSeconds;
  Timer? _timer;
  int _remaining;
  bool _paused = false;
  bool _completed = false;

  int get remaining => _remaining;
  bool get isPaused => _paused;
  bool get isCompleted => _completed;
  bool get isRunning => _timer?.isActive ?? false;
  double get progress => totalSeconds == 0 ? 0 : _remaining / totalSeconds;

  final StreamController<int> _controller =
      StreamController<int>.broadcast();

  Stream<int> get stream => _controller.stream;

  void Function()? onTick;
  void Function()? onComplete;
  void Function(int remaining)? onTickValue;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  void start() {
    _remaining = totalSeconds;
    _elapsedSeconds = 0;
    _paused = false;
    _completed = false;
    _timer?.cancel();
    _controller.add(_remaining);
    onTickValue?.call(_remaining);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_paused || _completed) return;
    _elapsedSeconds++;
    _remaining--;
    if (_remaining < 0) _remaining = 0;
    _controller.add(_remaining);
    onTick?.call();
    onTickValue?.call(_remaining);
    if (_remaining <= 0) {
      _completed = true;
      _timer?.cancel();
      onComplete?.call();
    }
  }

  void pause() {
    _paused = true;
  }

  void resume() {
    if (_completed) return;
    _paused = false;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Add bonus seconds (e.g., time reward for correct answer).
  void addSeconds(int seconds) {
    _remaining += seconds;
    if (_remaining > totalSeconds) _remaining = totalSeconds;
    _controller.add(_remaining);
    onTickValue?.call(_remaining);
  }

  /// Deduct seconds (penalty).
  void deductSeconds(int seconds) {
    _remaining -= seconds;
    if (_remaining < 0) _remaining = 0;
    _controller.add(_remaining);
    onTickValue?.call(_remaining);
    if (_remaining <= 0 && !_completed) {
      _completed = true;
      _timer?.cancel();
      onComplete?.call();
    }
  }

  void reset() {
    stop();
    _remaining = totalSeconds;
    _elapsedSeconds = 0;
    _paused = false;
    _completed = false;
    _controller.add(_remaining);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Stopwatch-style elapsed timer (counts up) for untimed games that still
/// track duration for scoring/result.
class GameStopwatch {
  GameStopwatch();

  Timer? _timer;
  int _elapsed = 0;
  bool _paused = false;

  int get elapsed => _elapsed;
  bool get isPaused => _paused;

  final StreamController<int> _controller = StreamController<int>.broadcast();
  Stream<int> get stream => _controller.stream;

  void start() {
    _elapsed = 0;
    _paused = false;
    _controller.add(_elapsed);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      _elapsed++;
      _controller.add(_elapsed);
    });
  }

  void pause() => _paused = true;
  void resume() => _paused = false;

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
