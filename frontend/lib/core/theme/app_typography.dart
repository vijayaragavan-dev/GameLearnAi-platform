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
  }) => TextStyle(
    fontFamily: displayFamily,
    fontVariations: _wght(weight),
    fontSize: size,
    height: 1.12,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle h1(BuildContext context) => TextStyle(
    fontFamily: displayFamily,
    fontVariations: _wght(700),
    fontSize: 26,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle h2(BuildContext context) => TextStyle(
    fontFamily: displayFamily,
    fontVariations: _wght(700),
    fontSize: 20,
    color: AppColors.textPrimary,
  );

  static TextStyle h3(BuildContext context) => TextStyle(
    fontFamily: displayFamily,
    fontVariations: _wght(700),
    fontSize: 17,
    color: AppColors.textPrimary,
  );

  static TextStyle body(BuildContext context) => const TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySecondary(BuildContext context) => const TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static TextStyle caption(BuildContext context) => const TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12.5,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static TextStyle label(BuildContext context) => const TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  static TextStyle monoNumber(BuildContext context, {double size = 16}) =>
      TextStyle(
        fontFamily: displayFamily,
        fontVariations: _wght(700),
        fontSize: size,
        color: AppColors.textPrimary,
      );
}
