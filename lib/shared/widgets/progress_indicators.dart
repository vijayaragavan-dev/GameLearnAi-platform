import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// Shared progress primitives — data-driven, no fake values.
/// All fractions are 0..1 derived from real backend fields passed by callers.

/// Circular progress ring — used for mastery, level, completion.
/// Wraps progress with animated arc; respects reduced motion.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.fraction,
    this.size = 64,
    this.stroke = 6,
    this.color = AppColors.primary,
    this.backgroundColor,
    this.child,
    this.semanticLabel,
  });

  final double fraction; // 0..1 from real data
  final double size;
  final double stroke;
  final Color color;
  final Color? backgroundColor;
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh);
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final clamped = fraction.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel ?? '${(clamped * 100).round()} percent',
      value: '${(clamped * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: clamped,
                strokeWidth: stroke,
                backgroundColor: bg,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

/// Animated circular ring with Tween — for reward / mastery reveal.
class AnimatedProgressRing extends StatelessWidget {
  const AnimatedProgressRing({
    super.key,
    required this.fraction,
    this.size = 168,
    this.stroke = 10,
    this.color = AppColors.primary,
    this.duration = AppMotion.feature,
  });

  final double fraction;
  final double size;
  final double stroke;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      return ProgressRing(
        fraction: fraction,
        size: size,
        stroke: stroke,
        color: color,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
      duration: duration,
      curve: AppMotion.easeOut,
      builder: (context, value, _) => ProgressRing(
        fraction: value,
        size: size,
        stroke: stroke,
        color: color,
        child: Text(
          '${(fraction * 100).round()}%',
          style: AppTypography.metric(context, size: size * 0.18),
        ),
      ),
    );
  }
}

/// Linear mastery bar — for topic mastery display.
/// Expects masteryScore 0..100 (or 0..1) — caller normalizes; widget handles both.
class MasteryBar extends StatelessWidget {
  const MasteryBar({
    super.key,
    required this.mastery, // 0..100 or 0..1
    this.height = 8,
    this.color,
  });

  final double mastery;
  final double height;
  final Color? color;

  double get _fraction {
    if (mastery <= 1.0) return mastery.clamp(0.0, 1.0);
    return (mastery / 100).clamp(0.0, 1.0);
  }

  Color _colorFor(BuildContext context) {
    if (color != null) return color!;
    final f = _fraction;
    if (f >= 0.8) return AppColors.success;
    if (f >= 0.5) return AppColors.warning;
    if (f >= 0.3) return AppColors.info;
    return AppColors.locked;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bar = FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: _colorFor(context),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            );
            if (reduce) return bar;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _fraction),
              duration: AppMotion.normal,
              curve: AppMotion.easeOut,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: _colorFor(context),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// XP progress — thin bar variant for headers; wraps mastery logic with XP semantics.
class XPProgress extends StatelessWidget {
  const XPProgress({
    super.key,
    required this.fraction, // 0..1 from server: totalXp / (totalXp + xpToNext)
    this.height = 6,
    this.animate = true,
  });

  final double fraction;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? !animate;
    final clamped = fraction.clamp(0.02, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fill = Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB45309), AppColors.xp],
                ),
                borderRadius: BorderRadius.circular(height),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.xp.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ],
              ),
            );
            if (reduce) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped,
                child: fill,
              );
            }
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: AppMotion.celebration,
              curve: AppMotion.easeOut,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: fill,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Streak visualization — row of dots for last N days. Pass real streak data.
class StreakDots extends StatelessWidget {
  const StreakDots({
    super.key,
    required this.currentStreak,
    this.totalDots = 7,
    this.size = 10,
  });

  final int currentStreak;
  final int totalDots;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Streak $currentStreak days',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalDots, (i) {
          final active = i < currentStreak.clamp(0, totalDots);
          return Container(
            width: size,
            height: size,
            margin: EdgeInsets.only(right: i == totalDots - 1 ? 0 : 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.streak
                  : (isDark
                        ? AppColors.surfaceHigh
                        : AppLightColors.surfaceHigh),
              border: Border.all(
                color: active
                    ? AppColors.streak.withValues(alpha: 0.6)
                    : (isDark ? AppColors.border : AppLightColors.border),
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.streak.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

/// Level progress card — combines LevelBadge semantics with linear bar.
/// Caller passes real level & XP fields; widget never computes level formula.
class LevelProgressRow extends StatelessWidget {
  const LevelProgressRow({
    super.key,
    required this.level,
    required this.fraction,
    this.height = 8,
  });

  final int level;
  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.brand,
          ),
          alignment: Alignment.center,
          child: Text(
            '$level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: XPProgress(fraction: fraction, height: height),
        ),
      ],
    );
  }
}
