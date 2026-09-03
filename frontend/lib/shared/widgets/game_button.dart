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
    final isDisabled = onTap == null || busy;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.85), color],
              ),
        color: isDisabled
            ? (isDark ? AppColors.lockedSurface : AppLightColors.lockedSurface)
            : null,
        borderRadius: BorderRadius.circular(16),
        border: isDisabled
            ? Border.all(
                color: isDark ? AppColors.border : AppLightColors.border,
              )
            : null,
        boxShadow: isDisabled
            ? null
            : AppShadows.glow(color, alpha: isDark ? 0.32 : 0.18),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: isDisabled
                    ? AppColors.textDisabled
                    : AppColors.textOnColor,
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(
                icon,
                size: 19,
                color: isDisabled
                    ? AppColors.textDisabled
                    : AppColors.textOnColor,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: isDisabled
                    ? AppColors.textDisabled
                    : AppColors.textOnColor,
              ),
            ),
          ],
        ],
      ),
    );
    return Opacity(
      opacity: isDisabled && !busy ? AppStates.disabledOpacity : 1,
      child: PressableScale(
        onTap: busy ? null : onTap,
        enabled: !isDisabled,
        child: button,
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onTap == null;
    return Opacity(
      opacity: isDisabled ? AppStates.disabledOpacity : 1,
      child: PressableScale(
        onTap: onTap,
        enabled: !isDisabled,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surface : AppLightColors.surface)
                .withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled
                  ? (isDark ? AppColors.border : AppLightColors.border)
                  : color.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isDisabled ? AppColors.textDisabled : color,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTypography.bodyFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDisabled ? AppColors.textDisabled : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tertiary / ghost button — text-like but with higher tap target, for "Skip", "Cancel".
class GhostGameButton extends StatelessWidget {
  const GhostGameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onTap == null;
    return Opacity(
      opacity: isDisabled ? AppStates.disabledOpacity : 1,
      child: PressableScale(
        onTap: onTap,
        enabled: !isDisabled,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppLightColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTypography.bodyFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppLightColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game-energetic action — slightly larger, with subtle sheen. Use for "PLAY NOW", "START BATTLE".
class GameActionButton extends StatelessWidget {
  const GameActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.play_arrow_rounded,
    this.color = AppColors.primary,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || busy;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: isDisabled && !busy ? AppStates.disabledOpacity : 1,
      child: PressableScale(
        onTap: busy ? null : onTap,
        enabled: !isDisabled,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.82)],
                  ),
            color: isDisabled
                ? (isDark
                      ? AppColors.lockedSurface
                      : AppLightColors.lockedSurface)
                : null,
            borderRadius: BorderRadius.circular(18),
            border: isDisabled
                ? Border.all(
                    color: isDark ? AppColors.border : AppLightColors.border,
                  )
                : null,
            boxShadow: isDisabled
                ? null
                : AppShadows.glow(color, alpha: isDark ? 0.38 : 0.20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                )
              else ...[
                Icon(icon, size: 22, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
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
