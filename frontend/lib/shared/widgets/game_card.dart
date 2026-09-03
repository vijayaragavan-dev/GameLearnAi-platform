import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';

/// Base surface card with subtle border and elevation.
/// Single design language: radius lg (20), border AppColors.border,
/// shadow drop, padding 16. Used by all lists and grids.
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderColor ??
              (isDark ? AppColors.border : AppLightColors.border),
        ),
        boxShadow: isDark ? AppShadows.drop() : null,
      ),
      child: child,
    );
  }
}

/// Slim interactive wrapper for cards that need hover feedback on desktop.
/// Preserves existing GameCard look; adds a very subtle border highlight
/// on hover — no gradient/shadow overuse.
class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hovered
                  ? (isDark ? AppColors.borderStrong : AppLightColors.borderStrong)
                  : (isDark ? AppColors.border : AppLightColors.border),
            ),
            boxShadow: _hovered
                ? AppShadows.soft(AppColors.primary, alpha: 0.12)
                : (isDark ? AppShadows.drop() : null),
          ),
          child: widget.child,
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.03),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.04),
                  Colors.white.withValues(alpha: 0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppLightColors.border,
        ),
      ),
      child: child,
    );
  }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(
              alpha: isDark ? intensity : intensity * 0.45,
            ),
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
              glowColor.withValues(alpha: isDark ? 0.16 : 0.06),
              isDark ? AppColors.surfaceElevated : AppLightColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: glowColor.withValues(alpha: 0.45)),
        ),
        child: child,
      ),
    );
  }

}
