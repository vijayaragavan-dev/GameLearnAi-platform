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
  /// Vibrant cobalt blue — primary action & anchor.
  static const Color primary = Color(0xFF3B82F6);

  /// Lighter cobalt blue — bright variant for selected states, icons.
  static const Color primaryBright = Color(0xFF60A5FA);

  /// Deep cobalt blue — dark variant for gradient starts.
  static const Color primaryDeep = Color(0xFF1D4ED8);

  /// Bright Cyan — secondary accent for energy, AI diagnostics, Nova Tutor.
  static const Color secondary = Color(0xFF06B6D4);

  /// Deep cyan — dark variant.
  static const Color secondaryDeep = Color(0xFF0891B2);

  /// Vivid Purple — puzzle, logic, challenges.
  static const Color purple = Color(0xFF7C3AED);

  /// Light Blue — soft accent for pairing with primary.
  static const Color lightBlue = Color(0xFFDCE9FF);

  // ── Semantic state colors (shared) ────────────────────────────────────────
  /// Emerald green — correct answers, completion, mastery.
  static const Color success = Color(0xFF10B981);

  /// Amber warning / energy — caution, medium difficulty, streak flame.
  static const Color warning = Color(0xFFF59E0B);

  /// Coral red error — incorrect, failed, danger actions, needs practice.
  static const Color error = Color(0xFFEF4444);

  /// Sky info — neutral information, hints.
  static const Color info = Color(0xFF06B6D4);

  /// Deep info.
  static const Color infoDeep = Color(0xFF0891B2);

  // ── Reward / gamification accents (shared) ───────────────────────────────
  /// Gold XP / Game Yellow — the reward, tactile game action, progression color.
  static const Color xp = Color(0xFFFFD43B);

  /// Streak flame amber — daily streak flame.
  static const Color streak = Color(0xFFF59E0B);

  /// Game action yellow.
  static const Color gameYellow = Color(0xFFFFD43B);

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
  // ── Background levels (light - Warm Ivory) ─────────────────────────────────
  static const Color background = Color(0xFFF7F5EF); // Warm Ivory canvas
  static const Color backgroundElevated = Color(0xFFEFECE3);
  static const Color backgroundDeep = Color(0xFFE7E3D8);
  static const Color backgroundInteractive = Color(0xFFEDE9DE);

  // ── Surface levels (light) ────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF); // Pure White card surface
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFF4F3F8);
  static const Color surfaceInteractive = Color(0xFFFFF8E7);
  static const Color surfaceSelected = Color(0xFFDCE9FF); // Soft blue selection
  static const Color surfaceDisabled = Color(0xFFEFECE3);

  // ── Locked (light) ────────────────────────────────────────────────────────
  static const Color locked = Color(0xFF727785);
  static const Color lockedSurface = Color(0xFFE7E3D8);

  // ── Info (light) ─────────────────────────────────────────────────────────
  static const Color info = Color(0xFF06B6D4);
  static const Color infoDeep = Color(0xFF0891B2);

  // ── Border levels (light - Deep Ink) ─────────────────────────────────────
  static const Color borderSubtle = Color(0x33171923);
  static const Color border = Color(0xFF171923); // Deep Ink #171923 baseline
  static const Color borderStrong = Color(0xFF171923);
  static const Color borderFocus = Color(0xFF3B82F6);

  // ── Text (light - Ink Black & Slate) ──────────────────────────────────────
  static const Color textPrimary = Color(0xFF171923); // Ink Black
  static const Color textSecondary = Color(0xFF596174); // Slate
  static const Color textTertiary = Color(0xFF596174); // Slate
  static const Color textMuted = Color(0xFF596174);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color textOnColor = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Interaction (light) ───────────────────────────────────────────────────
  static const Color focusRing = Color(0xFF3B82F6);
  static const Color overlay = Color(0x33171923);
  static const Color scrim = Color(0x59171923);
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
