import 'package:flutter/animation.dart';

/// Centralized motion constants. Every animation must communicate a state
/// change, interaction, progress, reward or navigation - never decoration
/// for its own sake.
abstract final class AppMotion {
  // Durations.
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration feature = Duration(milliseconds: 500);
  static const Duration celebration = Duration(milliseconds: 950);
  static const Duration staggerUnit = Duration(milliseconds: 55);

  // Curves.
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve standard = Curves.fastOutSlowIn;
  static const Curve spring = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
}
