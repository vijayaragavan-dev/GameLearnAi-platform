import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized haptic feedback - meaningful interactions only, never
/// continuous. Configurable via settings.
class Haptics {
  bool enabled = true;

  void tap() => _run(HapticFeedback.lightImpact);
  void select() => _run(HapticFeedback.selectionClick);
  void success() => _run(() async {
    await HapticFeedback.mediumImpact();
  });
  void celebrate() => _run(() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.mediumImpact();
  });
  void error() => _run(HapticFeedback.vibrate);

  void _run(Future<void> Function() pattern) {
    if (!enabled) return;
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      pattern();
    }
  }
}
