import 'package:flutter/material.dart';
import 'app_colors.dart';

/// GameLearn AI type scale — Version 2.0
///
/// Display face : Space Grotesk (GameLearnDisplay variable font)
/// Body face    : Inter (GameLearnBody variable font)
///
/// Hierarchy (largest → smallest):
///   displayLarge → hero → display → h1 → gameTitle → h2 → h3 →
///   body → bodySecondary → caption → label → overline
///
/// Numbers (game-specific):
///   xpNumber → levelNumber → streakNumber → gameScore → metric → monoNumber
///
/// All methods are context-aware (dark/light). Provide BuildContext.
abstract final class AppTypography {
  static const String displayFamily = 'GameLearnDisplay';
  static const String bodyFamily = 'GameLearnBody';

  static List<FontVariation> _wght(int value) => [
    FontVariation('wght', value.toDouble()),
  ];

  // ── Display tier ─────────────────────────────────────────────────────────

  /// Display large — 40pt, w800. Hero sections, splash titles.
  static TextStyle displayLarge(BuildContext context, {double size = 40}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(800),
      fontSize: size,
      height: 1.05,
      letterSpacing: -0.8,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// Hero — 30pt, w700. Page hero headlines, welcome sections.
  static TextStyle hero(BuildContext context, {double size = 30}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(700),
      fontSize: size,
      height: 1.15,
      letterSpacing: -0.4,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// Display — 34pt, w700. Game result scores, major display numbers.
  static TextStyle display(
    BuildContext context, {
    double size = 34,
    int weight = 700,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(weight),
      fontSize: size,
      height: 1.12,
      letterSpacing: -0.5,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  // ── Heading tier ─────────────────────────────────────────────────────────

  /// H1 — 26pt, w700. Page titles.
  static TextStyle h1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(700),
      fontSize: 26,
      letterSpacing: -0.3,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// Game title — 22pt, w800. In-game titles, game card names. Space Grotesk
  /// with tight tracking for a premium game-interface feel.
  static TextStyle gameTitle(BuildContext context, {double size = 22}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(800),
      fontSize: size,
      height: 1.10,
      letterSpacing: -0.2,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// H2 / Section title — 20pt, w700. Section headings, card group labels.
  static TextStyle h2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(700),
      fontSize: 20,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// H3 / Card title — 17pt, w700. Card headings, dialog titles.
  static TextStyle h3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(700),
      fontSize: 17,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// Aliases.
  static TextStyle sectionTitle(BuildContext context) => h2(context);
  static TextStyle cardTitle(BuildContext context) => h3(context);

  // ── Body tier ────────────────────────────────────────────────────────────

  /// Body — 15pt, w400. Standard reading text.
  static TextStyle body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 15,
      height: 1.45,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// Body secondary — 14pt. Supporting descriptions, metadata.
  static TextStyle bodySecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      height: 1.45,
      color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
    );
  }

  /// Body emphasis — 15pt, w600. Emphasized inline text.
  static TextStyle bodyEmphasis(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  // ── Utility tier ──────────────────────────────────────────────────────────

  /// Caption — 12.5pt, w600. Supporting details, timestamps, hints.
  static TextStyle caption(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 12.5,
      height: 1.35,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
    );
  }

  /// Label — 13pt, w600, tracked. Form labels, category labels.
  static TextStyle label(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
    );
  }

  /// Badge label — 11pt, w800. Pill badges, difficulty chips, status.
  static TextStyle badgeLabel(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: color ??
          (isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
    );
  }

  /// Overline — 11pt, w700, tracked caps. Overline text above headings.
  static TextStyle overline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
    );
  }

  /// Button label — 14pt, w700. CTA buttons.
  static TextStyle buttonLabel(BuildContext context, {double size = 14}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// Nav label — 11.5pt, selectable weight. Bottom bar labels.
  static TextStyle navLabel(BuildContext context, {bool selected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 11.5,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: 0.6,
      color: selected
          ? (isDark ? AppColors.primaryBright : AppColors.primary)
          : (isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
    );
  }

  // ── Numeric / game stats tier ─────────────────────────────────────────────

  /// Metric — 28pt, w800. KPI stat values, score totals.
  static TextStyle metric(BuildContext context, {double size = 28}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(800),
      fontSize: size,
      height: 1,
      letterSpacing: -0.3,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// Mono number — Display face numbers, consistent character width feel.
  static TextStyle monoNumber(BuildContext context, {double size = 16}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(700),
      fontSize: size,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  /// Game score — 36pt. Large score display in game result.
  static TextStyle gameScore(BuildContext context, {double size = 36}) =>
      metric(context, size: size);

  /// XP number — gold, bold. Used for XP earned/total display.
  /// Includes subtle glow shadow on dark theme.
  static TextStyle xpNumber(BuildContext context, {double size = 24}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(800),
      fontSize: size,
      height: 1,
      letterSpacing: -0.2,
      color: AppColors.xp,
      shadows: isDark
          ? [Shadow(color: AppColors.xp.withValues(alpha: 0.45), blurRadius: 12)]
          : null,
    );
  }

  /// XP label — small tracked XP text (e.g., "+250 XP").
  static TextStyle xpLabel(BuildContext context, {double size = 13}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
      color: AppColors.xp,
      shadows: isDark
          ? [Shadow(color: AppColors.xp.withValues(alpha: 0.35), blurRadius: 8)]
          : null,
    );
  }

  /// Level number — purple, large. Used in level badges and headers.
  static TextStyle levelNumber(BuildContext context, {double size = 20}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(800),
      fontSize: size,
      height: 1,
      letterSpacing: -0.2,
      color: isDark ? AppColors.primaryBright : AppColors.primary,
      shadows: isDark
          ? [
              Shadow(
                color: AppColors.primary.withValues(alpha: 0.40),
                blurRadius: 10,
              ),
            ]
          : null,
    );
  }

  /// Streak number — orange flame color. Used in streak counters.
  static TextStyle streakNumber(BuildContext context, {double size = 20}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(800),
      fontSize: size,
      height: 1,
      letterSpacing: -0.2,
      color: AppColors.streak,
      shadows: isDark
          ? [
              Shadow(
                color: AppColors.streak.withValues(alpha: 0.40),
                blurRadius: 10,
              ),
            ]
          : null,
    );
  }

  /// Stat number — neutral large number for KPI display.
  static TextStyle statNumber(
    BuildContext context, {
    double size = 32,
    Color? color,
    bool glow = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        color ?? (isDark ? AppColors.textPrimary : AppLightColors.textPrimary);
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(800),
      fontSize: size,
      height: 1,
      letterSpacing: -0.3,
      color: textColor,
      shadows: glow && isDark && color != null
          ? [Shadow(color: color.withValues(alpha: 0.40), blurRadius: 12)]
          : null,
    );
  }
}
