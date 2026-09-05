import 'package:flutter/material.dart';

/// GameLearn AI semantic color palette — Version 2.0
///
/// Dark is the primary futuristic game-world identity: deep navy surfaces,
/// electric purple/cyan, gold XP. Light is a genuine premium light theme —
/// not an inverted dark — with white surfaces, slate text, same brand accents.
///
/// Token hierarchy:
///   Background → Surface → Card → Featured → Modal/Overlay → Reward
///
/// Rules:
///   - Accent colors (primary, secondary, success, warning, error, xp, streak)
///     are shared across both themes.
///   - Surface/text/border tokens are theme-split via [AppLightColors].
///   - Screens MUST prefer these tokens. Never scatter raw Color() values.
///   - Use [AppColorContext] extension for context-aware resolution.
abstract final class AppColors {
  // ── Background levels (dark) ─────────────────────────────────────────────
  /// Deepest background — behind everything, used for page scaffolds.
  static const Color background = Color(0xFF070B17);

  /// Slightly elevated background — separates page regions.
  static const Color backgroundElevated = Color(0xFF0C1220);

  /// Deep atmospheric layer — used for background decoration.
  static const Color backgroundDeep = Color(0xFF040710);

  /// Interactive background regions — hover/focus states on background.
  static const Color backgroundInteractive = Color(0xFF0F1728);

  // ── Surface levels (dark) ─────────────────────────────────────────────────
  /// Base card/panel surface.
  static const Color surface = Color(0xFF10172A);

  /// Elevated card — sits above [surface], drawer, bottom sheet.
  static const Color surfaceElevated = Color(0xFF151E35);

  /// Higher still — modal dialogs, popovers.
  static const Color surfaceHigh = Color(0xFF1B2542);

  /// Interactive surface state — hover/focus tint for tappable surfaces.
  static const Color surfaceInteractive = Color(0xFF1A2640);

  /// Selected surface — active/selected state.
  static const Color surfaceSelected = Color(0xFF1E2D50);

  /// Disabled surface — muted, non-interactive.
  static const Color surfaceDisabled = Color(0xFF0E1525);

  // ── Brand accents (shared across themes) ─────────────────────────────────
  /// Electric purple — primary brand accent.
  static const Color primary = Color(0xFF8B5CF6);

  /// Lighter purple — bright variant for selected states, icons.
  static const Color primaryBright = Color(0xFFA78BFA);

  /// Deep purple — dark variant for gradient starts.
  static const Color primaryDeep = Color(0xFF5B21B6);

  /// Cyan — secondary accent for energy, info, Nova.
  static const Color secondary = Color(0xFF22D3EE);

  /// Deep cyan — dark variant.
  static const Color secondaryDeep = Color(0xFF0E7490);

  // ── Semantic state colors (shared) ────────────────────────────────────────
  /// Emerald success — correct answers, completion, XP gain.
  static const Color success = Color(0xFF34D399);

  /// Amber warning — caution, medium difficulty, streak at risk.
  static const Color warning = Color(0xFFFBBF24);

  /// Coral error — incorrect, failed, danger actions.
  static const Color error = Color(0xFFF87171);

  /// Sky info — neutral information, hints.
  static const Color info = Color(0xFF38BDF8);

  /// Deep info.
  static const Color infoDeep = Color(0xFF075985);

  // ── Reward / gamification accents (shared) ───────────────────────────────
  /// Gold XP — the reward color. Use sparingly and meaningfully.
  static const Color xp = Color(0xFFFACC15);

  /// Streak orange — daily streak flame.
  static const Color streak = Color(0xFFFB923C);

  // ── Locked / disabled (dark) ─────────────────────────────────────────────
  static const Color locked = Color(0xFF475569);
  static const Color lockedSurface = Color(0xFF1E293B);

  // ── Border levels (dark) ─────────────────────────────────────────────────
  /// Subtlest border — section separators.
  static const Color borderSubtle = Color(0xFF1A2235);

  /// Default border — cards, inputs.
  static const Color border = Color(0xFF24304F);

  /// Strong border — hovered cards, interactive feedback.
  static const Color borderStrong = Color(0xFF334368);

  /// Focus ring border — keyboard focus indicator.
  static const Color borderFocus = Color(0xFFA78BFA);

  // ── Text (dark) ───────────────────────────────────────────────────────────
  /// High-emphasis text — titles, important content.
  static const Color textPrimary = Color(0xFFF1F5F9);

  /// Medium-emphasis text — secondary labels, descriptions.
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Low-emphasis text — placeholders, overlines.
  static const Color textTertiary = Color(0xFF64748B);

  /// Muted text — supporting context, timestamps.
  static const Color textMuted = Color(0xFF475569);

  /// Disabled text — non-interactive content.
  static const Color textDisabled = Color(0xFF475569);

  /// On-color text — text on colored/gradient backgrounds.
  static const Color textOnColor = Color(0xFF0B1020);

  /// On-accent text — white text on accent-colored buttons.
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Glow / overlay (dark) ────────────────────────────────────────────────
  /// Accent glow — primary purple ambient light.
  static const Color glowPrimary = Color(0x408B5CF6);

  /// Cyan glow — secondary energy ambient.
  static const Color glowSecondary = Color(0x4022D3EE);

  /// Gold glow — XP/reward ambient.
  static const Color glowXP = Color(0x40FACC15);

  /// Success glow — completion ambient.
  static const Color glowSuccess = Color(0x4034D399);

  /// Error glow — alert ambient.
  static const Color glowError = Color(0x40F87171);

  /// Focus ring glow alias.
  static const Color focusRing = Color(0xFFA78BFA);

  /// Modal overlay scrim.
  static const Color overlay = Color(0xB310172A);

  // ── Lines & misc (dark) ───────────────────────────────────────────────────
  static const Color scrim = Color(0xD9060A14);
}

/// Genuine premium light theme palette. Not an inverted dark —
/// white surfaces, slate text, visible borders, same brand accents.
abstract final class AppLightColors {
  // ── Background levels (light) ────────────────────────────────────────────
  static const Color background = Color(0xFFF1F5F9); // slate-100
  static const Color backgroundElevated = Color(0xFFE8EFF8);
  static const Color backgroundDeep = Color(0xFFE2E8F0); // slate-200
  static const Color backgroundInteractive = Color(0xFFEBF0F9);

  // ── Surface levels (light) ────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFE2E8F0);
  static const Color surfaceInteractive = Color(0xFFF5F8FF);
  static const Color surfaceSelected = Color(0xFFEEF2FF);
  static const Color surfaceDisabled = Color(0xFFF8FAFC);

  // ── Locked (light) ────────────────────────────────────────────────────────
  static const Color locked = Color(0xFF94A3B8);
  static const Color lockedSurface = Color(0xFFE2E8F0);

  // ── Info (light) ─────────────────────────────────────────────────────────
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoDeep = Color(0xFF0369A1);

  // ── Border levels (light) ────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color borderFocus = Color(0xFF8B5CF6);

  // ── Text (light) ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF334155); // slate-700
  static const Color textTertiary = Color(0xFF64748B); // slate-500
  static const Color textMuted = Color(0xFF94A3B8); // slate-400
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color textOnColor = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Interaction (light) ───────────────────────────────────────────────────
  static const Color focusRing = Color(0xFF8B5CF6);
  static const Color overlay = Color(0x3310172A);
  static const Color scrim = Color(0x590F172A);
}

/// Context-aware color resolution — single source for theme-adaptive values.
///
/// Usage:
///   final bg = context.surfaceColor;
///   final text = context.textPrimaryColor;
///
/// Accents (primary, xp, streak, success, warning, error) are identical
/// across themes and should be referenced directly from [AppColors].
extension AppColorContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Background
  Color get backgroundColor =>
      isDark ? AppColors.background : AppLightColors.background;
  Color get backgroundElevatedColor =>
      isDark ? AppColors.backgroundElevated : AppLightColors.backgroundElevated;
  Color get backgroundDeepColor =>
      isDark ? AppColors.backgroundDeep : AppLightColors.backgroundDeep;
  Color get backgroundInteractiveColor =>
      isDark
          ? AppColors.backgroundInteractive
          : AppLightColors.backgroundInteractive;

  // Surface
  Color get surfaceColor =>
      isDark ? AppColors.surface : AppLightColors.surface;
  Color get surfaceElevatedColor =>
      isDark ? AppColors.surfaceElevated : AppLightColors.surfaceElevated;
  Color get surfaceHighColor =>
      isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh;
  Color get surfaceInteractiveColor =>
      isDark ? AppColors.surfaceInteractive : AppLightColors.surfaceInteractive;
  Color get surfaceSelectedColor =>
      isDark ? AppColors.surfaceSelected : AppLightColors.surfaceSelected;
  Color get surfaceDisabledColor =>
      isDark ? AppColors.surfaceDisabled : AppLightColors.surfaceDisabled;

  // Border
  Color get borderSubtleColor =>
      isDark ? AppColors.borderSubtle : AppLightColors.borderSubtle;
  Color get borderColor =>
      isDark ? AppColors.border : AppLightColors.border;
  Color get borderStrongColor =>
      isDark ? AppColors.borderStrong : AppLightColors.borderStrong;
  Color get borderFocusColor =>
      isDark ? AppColors.borderFocus : AppLightColors.borderFocus;

  // Text
  Color get textPrimaryColor =>
      isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
  Color get textSecondaryColor =>
      isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
  Color get textTertiaryColor =>
      isDark ? AppColors.textTertiary : AppLightColors.textTertiary;
  Color get textMutedColor =>
      isDark ? AppColors.textMuted : AppLightColors.textMuted;
  Color get textDisabledColor =>
      isDark ? AppColors.textDisabled : AppLightColors.textDisabled;

  // Locked
  Color get lockedColor =>
      isDark ? AppColors.locked : AppLightColors.locked;
  Color get lockedSurfaceColor =>
      isDark ? AppColors.lockedSurface : AppLightColors.lockedSurface;
}
