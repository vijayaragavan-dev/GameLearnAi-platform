import 'package:flutter/material.dart';

/// GameLearn AI semantic palette.
///
/// Dark, futuristic, technical. Color always carries meaning:
/// purple = brand/primary action, cyan = intelligence/AI,
/// gold = XP, orange = streak, emerald = success, coral = error.
abstract final class AppColors {
  // Backgrounds.
  static const Color background = Color(0xFF070B17);
  static const Color surface = Color(0xFF10172A);
  static const Color surfaceElevated = Color(0xFF151E35);
  static const Color surfaceHigh = Color(0xFF1B2542);

  // Brand.
  static const Color primary = Color(0xFF8B5CF6); // electric purple
  static const Color primaryBright = Color(0xFFA78BFA);
  static const Color primaryDeep = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFF22D3EE); // cyan
  static const Color secondaryDeep = Color(0xFF0E7490);

  // Semantic states.
  static const Color success = Color(0xFF34D399); // emerald
  static const Color warning = Color(0xFFFBBF24); // amber
  static const Color error = Color(0xFFF87171); // coral

  // Reward accents.
  static const Color xp = Color(0xFFFACC15); // gold
  static const Color streak = Color(0xFFFB923C); // orange

  // Muted / locked.
  static const Color locked = Color(0xFF475569);
  static const Color lockedSurface = Color(0xFF1E293B);

  // Text.
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textOnColor = Color(0xFF0B1020);

  // Lines & overlays.
  static const Color border = Color(0xFF24304F);
  static const Color borderStrong = Color(0xFF334368);
  static const Color scrim = Color(0xD9060A14);
}
