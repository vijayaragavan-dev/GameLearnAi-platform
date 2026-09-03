import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type scale for GameLearn AI.
///
/// Display face: Space Grotesk (bundled variable font).
/// Body face: Inter (bundled variable font).
/// Weights are applied via FontVariation since both files are variable.
abstract final class AppTypography {
  static const String displayFamily = 'GameLearnDisplay';
  static const String bodyFamily = 'GameLearnBody';

  static List<FontVariation> _wght(int value) => [
    FontVariation('wght', value.toDouble()),
  ];

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

  static TextStyle h2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(700),
      fontSize: 20,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  static TextStyle h3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(700),
      fontSize: 17,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  static TextStyle body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 15,
      height: 1.45,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  static TextStyle bodySecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      height: 1.45,
      color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
    );
  }

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

  static TextStyle monoNumber(BuildContext context, {double size = 16}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: displayFamily,
      fontVariations: _wght(700),
      fontSize: size,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
  }

  // ---- Extended premium hierarchy (all theme-aware) ----

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

  static TextStyle sectionTitle(BuildContext context) => h2(context);

  static TextStyle cardTitle(BuildContext context) => h3(context);

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

  static TextStyle gameScore(BuildContext context, {double size = 36}) =>
      metric(context, size: size);

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

  static TextStyle badgeLabel(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color:
          color ??
          (isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
    );
  }

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
}
