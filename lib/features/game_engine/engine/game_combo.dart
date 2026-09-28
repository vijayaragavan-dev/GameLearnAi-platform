/// Combo/streak tracker within a single game session.
class GameCombo {
  GameCombo();

  int _current = 0;
  int _max = 0;

  int get current => _current;
  int get max => _max;

  /// Call on correct answer/match/placement.
  void registerHit() {
    _current++;
    if (_current > _max) _max = _current;
  }

  /// Call on incorrect answer/mismatch. Resets streak.
  void registerMiss() {
    _current = 0;
  }

  void reset() {
    _current = 0;
    _max = 0;
  }

  bool get isHot => _current >= 3;
  bool get isOnFire => _current >= 5;

  String get label {
    if (_current >= 10) return 'GODLIKE x$_current';
    if (_current >= 7) return 'UNSTOPPABLE x$_current';
    if (_current >= 5) return 'ON FIRE x$_current';
    if (_current >= 3) return 'COMBO x$_current';
    if (_current >= 2) return 'x$_current';
    return '';
  }
}
