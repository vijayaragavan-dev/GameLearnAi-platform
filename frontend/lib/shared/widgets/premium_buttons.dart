import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';
import 'game_button.dart' show PressableScale;

/// Premium button system extensions — Version 2.0
///
/// Additional buttons beyond the M1-1 set:
///   DangerGameButton  — destructive action (error treatment)
///   RewardButton      — gold XP-themed CTA (reward screens)
///   IconActionButton  — compact icon-only, 48dp touch target
///
/// Existing buttons (exported for single import convenience):
///   PrimaryGameButton, SecondaryGameButton, GhostGameButton,
///   GameActionButton, GameChip — see game_button.dart

// ─────────────────────────────────────────────────────────────────────────────
// DANGER GAME BUTTON — destructive/error action
// ─────────────────────────────────────────────────────────────────────────────

/// Danger button — for destructive or irreversible actions.
class DangerGameButton extends StatelessWidget {
  const DangerGameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expanded = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || busy;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const color = AppColors.error;

    return Opacity(
      opacity: isDisabled && !busy ? AppStates.disabledOpacity : 1,
      child: PressableScale(
        onTap: busy ? null : onTap,
        enabled: !isDisabled,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF991B1B), color],
                  ),
            color: isDisabled
                ? (isDark
                    ? AppColors.lockedSurface
                    : AppLightColors.lockedSurface)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: isDisabled
                ? Border.all(
                    color: isDark ? AppColors.border : AppLightColors.border,
                  )
                : null,
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.30 : 0.16),
                      blurRadius: 22,
                      spreadRadius: 0,
                    ),
                  ],
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
                    color: Colors.white,
                  ),
                )
              else ...[
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 19,
                    color: isDisabled ? AppColors.textDisabled : Colors.white,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDisabled ? AppColors.textDisabled : Colors.white,
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

// ─────────────────────────────────────────────────────────────────────────────
// REWARD BUTTON — gold XP-themed CTA
// ─────────────────────────────────────────────────────────────────────────────

/// Reward button — gold-themed for reward screens and claim actions.
class RewardButton extends StatelessWidget {
  const RewardButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.star_rounded,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;
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
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB45309), AppColors.xp],
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
                : Border.all(
                    color: AppColors.xp.withValues(alpha: 0.55),
                  ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.xp.withValues(
                        alpha: isDark ? 0.42 : 0.22,
                      ),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
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
                    color: Colors.black87,
                  ),
                )
              else ...[
                Icon(
                  icon,
                  size: 22,
                  color: isDisabled ? AppColors.textDisabled : Colors.black87,
                ),
                const SizedBox(width: 10),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: isDisabled ? AppColors.textDisabled : Colors.black87,
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

// ─────────────────────────────────────────────────────────────────────────────
// ICON ACTION BUTTON — compact icon-only 48dp action
// ─────────────────────────────────────────────────────────────────────────────

/// Icon-only action button — 48dp touch target (WCAG AA compliant).
class IconActionButton extends StatefulWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.color,
    this.size = 48,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color? color;
  final double size;
  final bool filled;

  @override
  State<IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onTap == null;
    final accent = widget.color ?? AppColors.primary;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: !isDisabled,
      child: MouseRegion(
        onEnter: isDisabled ? null : (_) => setState(() => _hovered = true),
        onExit: isDisabled ? null : (_) => setState(() => _hovered = false),
        cursor: isDisabled ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Opacity(
            opacity: isDisabled ? AppStates.disabledOpacity : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.filled
                    ? accent.withValues(alpha: _hovered ? 0.20 : 0.12)
                    : (_hovered
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05))
                        : Colors.transparent),
                border: widget.filled
                    ? Border.all(color: accent.withValues(alpha: 0.35))
                    : null,
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                size: widget.size * 0.46,
                color: isDisabled
                    ? (isDark
                        ? AppColors.textDisabled
                        : AppLightColors.textDisabled)
                    : widget.filled
                        ? accent
                        : (isDark
                            ? AppColors.textSecondary
                            : AppLightColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
