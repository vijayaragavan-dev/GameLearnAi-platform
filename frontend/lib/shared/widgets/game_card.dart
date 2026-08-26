import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';

/// Base surface card with subtle border and elevation.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: borderColor ?? AppColors.border),
      boxShadow: AppShadows.drop(),
    ),
    child: child,
  );
}

/// Translucent glass surface for hero sections over gradients.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.xl,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.03),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: child,
  );
}

/// Card with a colored glow halo - used for recommended/highlight content.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    required this.glowColor,
    this.padding = const EdgeInsets.all(16),
    this.intensity = 0.35,
  });

  final Widget child;
  final Color glowColor;
  final EdgeInsetsGeometry padding;
  final double intensity;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: intensity),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glowColor.withValues(alpha: 0.16),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: glowColor.withValues(alpha: 0.45)),
      ),
      child: child,
    ),
  );
}
