import 'dart:async';

import 'audio_manager.dart';

/// Controls typing SFX with throttling, overlap prevention, and lifecycle
/// safety. Attach to a TextEditingController, call onChanged, and dispose
/// when leaving the screen.
class TypingSoundController {
  TypingSoundController({
    required this.audioManager,
    this.throttle = const Duration(milliseconds: 120),
    this.inactivityReset = const Duration(milliseconds: 800),
  });

  final AudioManager audioManager;
  final Duration throttle;
  final Duration inactivityReset;

  Timer? _inactivityTimer;
  DateTime _lastPlay = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastText = '';
  bool _disposed = false;

  /// Call from TextField.onChanged with the current text.
  void onChanged(String text) {
    if (_disposed) return;
    if (text.isEmpty) {
      _reset();
      return;
    }
    // Detect actual typing: text length changed (not just selection)
    if (text == _lastText) return;
    final isInsert = text.length > _lastText.length;
    _lastText = text;
    if (!isInsert) {
      // Deletion - still consider as typing but don't spam
      _scheduleReset();
      return;
    }
    // Throttle
    final now = DateTime.now();
    if (now.difference(_lastPlay) < throttle) {
      _scheduleReset();
      return;
    }
    _lastPlay = now;
    // Respect SFX settings inside AudioManager
    unawaited(audioManager.playTyping());
    _scheduleReset();
  }

  void _scheduleReset() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityReset, () {
      _lastText = '';
    });
  }

  void _reset() {
    _lastText = '';
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void dispose() {
    _disposed = true;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}

void unawaited(Future<void> future) {}
