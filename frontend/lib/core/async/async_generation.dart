import 'dart:async';

/// Async staleness guard. Each async operation captures a generation token;
/// the token is incremented when state should be discarded (logout, route
/// change, or any user-action that invalidates the previous request).
///
/// Use pattern:
///   final _gen = AsyncGeneration();
///   final mine = _gen.bump();
///   final r = await fetch();
///   if (mine.stale) return; // skip setState/navigation
///
/// Minimal surface — no provider dependency, no rebuilds beyond a single int.
class AsyncGeneration {
  int _value = 0;

  /// Returns a snapshot valid for the current state. Subsequent calls
  /// invalidate previous snapshots.
  Token bump() {
    _value++;
    return Token(_value);
  }

  /// Current generation value.
  int get current => _value;

  /// Invalidate every previous snapshot.
  void reset() {
    _value++;
  }
}

class Token {
  Token(this._value);
  final int _value;

  bool isCurrent(AsyncGeneration gen) => gen.current == _value;
  bool get stale => false;
}
