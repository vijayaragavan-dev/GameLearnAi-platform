import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';

enum GameCardVariant {
  standard,
  elevated,
  interactive,
  reward,
  locked,
  success,
  featured,
}

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
    this.variant = GameCardVariant.standard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final GameCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color resolvedColor = color ?? scheme.surface;
    Color resolvedBorder =
        borderColor ?? (isDark ? AppColors.border : AppLightColors.border);
    List<BoxShadow>? shadows = isDark
        ? AppShadows.drop()
        : AppShadows.elevated(alpha: 0.06);

    switch (variant) {
      case GameCardVariant.elevated:
        shadows = isDark ? AppShadows.drop() : AppShadows.elevated(alpha: 0.08);
        break;
      case GameCardVariant.reward:
        resolvedColor = AppColors.xp.withValues(alpha: isDark ? 0.08 : 0.04);
        resolvedBorder = AppColors.xp.withValues(alpha: isDark ? 0.35 : 0.25);
        shadows = [
          BoxShadow(
            color: AppColors.xp.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case GameCardVariant.locked:
        resolvedColor = isDark
            ? AppColors.lockedSurface
            : AppLightColors.lockedSurface;
        resolvedBorder = isDark ? AppColors.border : AppLightColors.border;
        shadows = null;
        break;
      case GameCardVariant.success:
        resolvedBorder = AppColors.success.withValues(alpha: 0.45);
        shadows = AppShadows.soft(
          AppColors.success,
          alpha: isDark ? 0.18 : 0.10,
        );
        break;
      case GameCardVariant.featured:
        resolvedBorder = AppColors.primary.withValues(alpha: 0.35);
        shadows = AppShadows.glow(
          AppColors.primary,
          alpha: isDark ? 0.18 : 0.09,
        );
        break;
      case GameCardVariant.interactive:
      case GameCardVariant.standard:
        break;
    }

    return Semantics(
      container: variant == GameCardVariant.locked ? true : false,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: variant == GameCardVariant.reward ? null : resolvedColor,
          gradient: variant == GameCardVariant.reward
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.xp.withValues(alpha: isDark ? 0.12 : 0.06),
                    scheme.surface,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: resolvedBorder),
          boxShadow: shadows,
        ),
        child: child,
      ),
    );
  }
}

/// Slim interactive wrapper for cards that need hover feedback on desktop.
/// Preserves existing GameCard look; adds a very subtle border highlight
/// on hover — no gradient/shadow overuse. Supports selected + disabled semantics.
class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final effectiveEnabled = widget.enabled && widget.onTap != null;
    Color border = isDark ? AppColors.border : AppLightColors.border;
    List<BoxShadow>? shadow = isDark
        ? AppShadows.drop()
        : AppShadows.elevated(alpha: 0.06);
    if (widget.selected) {
      border = AppColors.primary.withValues(alpha: 0.45);
      shadow = AppShadows.glow(AppColors.primary, alpha: isDark ? 0.18 : 0.08);
    } else if (_hovered && effectiveEnabled) {
      border = isDark ? AppColors.borderStrong : AppLightColors.borderStrong;
      shadow = AppShadows.interactive(AppColors.primary, alpha: 0.13);
    }
    if (!widget.enabled) {
      border = isDark ? AppColors.border : AppLightColors.border;
      shadow = null;
    }
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: MouseRegion(
        onEnter: effectiveEnabled
            ? (_) => setState(() => _hovered = true)
            : null,
        onExit: effectiveEnabled
            ? (_) => setState(() => _hovered = false)
            : null,
        cursor: effectiveEnabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: effectiveEnabled ? widget.onTap : null,
          onTapDown: effectiveEnabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: effectiveEnabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? AppStates.pressedScale : 1.0,
            duration: AppMotion.fast,
            curve: AppMotion.easeOut,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.easeOut,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? scheme.surface
                    : (isDark
                          ? AppColors.lockedSurface
                          : AppLightColors.lockedSurface),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border),
                boxShadow: shadow,
              ),
              child: Opacity(
                opacity: widget.enabled ? 1 : AppStates.disabledOpacity,
                child: widget.child,
              ),
            ),
          ),
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
