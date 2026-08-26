import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// Press-scale microinteraction wrapper used by all tappable surfaces.
class PressableScale extends ConsumerStatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final bool enabled;

  @override
  ConsumerState<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends ConsumerState<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scale = _down ? 0.97 : 1.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.enabled
          ? () {
              if (widget.haptic) ref.read(hapticsProvider).tap();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Filled gradient call-to-action.
class PrimaryGameButton extends StatelessWidget {
  const PrimaryGameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expanded = true,
    this.color = AppColors.primary,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.85), color],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.glow(color, alpha: 0.35),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.textOnColor,
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: 19, color: AppColors.textOnColor),
              const SizedBox(width: 8),
            ],
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.textOnColor,
              ),
            ),
          ],
        ],
      ),
    );
    return PressableScale(onTap: busy ? null : onTap, child: button);
  }
}

/// Outlined secondary action.
class SecondaryGameButton extends StatelessWidget {
  const SecondaryGameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expanded = true,
    this.color = AppColors.secondary,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill-shaped action chip (e.g., "CONTINUE", "VIEW").
class GameChip extends StatelessWidget {
  const GameChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = AppColors.primaryBright,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
