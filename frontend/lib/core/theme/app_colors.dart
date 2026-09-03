import 'package:flutter/material.dart';

/// GameLearn AI semantic palette.
///
/// Dark is the original futuristic identity (deep navy surfaces, neon
/// purple/cyan, gold XP). Light is a genuine light theme — not an inverted
/// dark — with white surfaces, slate text, and the same brand accents to
/// preserve gamified identity on both.
///
/// Accent colors (primary, secondary, success, warning, error, xp, streak)
/// are shared; surface/text/border adapt per brightness via [AppLightColors]
/// and Theme's colorScheme. Screens should prefer Theme's colorScheme for
/// surfaces/text where possible, but AppColors remain the single source for
/// accents.
///
/// For context-aware access, use `Theme.of(context).brightness` or
/// `context.isDark` extension if needed; AppColors constants remain dark
/// for backward compat, light via AppLightColors.
abstract final class AppColors {
  // Backgrounds (dark).
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

  // Muted / locked (dark).
  static const Color locked = Color(0xFF475569);
  static const Color lockedSurface = Color(0xFF1E293B);

  // Text (dark).
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textOnColor = Color(0xFF0B1020);

  // Lines & overlays (dark).
  static const Color border = Color(0xFF24304F);
  static const Color borderStrong = Color(0xFF334368);
  static const Color scrim = Color(0xD9060A14);
}

/// Genuine light theme palette. Not inverted dark — white surfaces, slate
/// text, visible borders, same brand accents for identity.
abstract final class AppLightColors {
  static const Color background = Color(0xFFF1F5F9); // slate-100
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFE2E8F0); // slate-200

  static const Color locked = Color(0xFF94A3B8);
  static const Color lockedSurface = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF334155); // slate-700
  static const Color textTertiary = Color(0xFF64748B); // slate-500
  static const Color textOnColor = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderStrong = Color(0xFFCBD5E1); // slate-300
  static const Color scrim = Color(0x590F172A);
}

/// Helper to pick correct surface/text/border per brightness without
/// scattering ternary everywhere. Accents (primary etc.) are identical.
extension AppColorContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
