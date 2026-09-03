import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// Hexagonal level badge with the level number.
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.size = 56,
    this.showGlow = true,
  });

  final int level;
  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.brand,
        border: Border.all(color: AppColors.primaryBright, width: 2),
        boxShadow: showGlow
            ? AppShadows.glow(AppColors.primary, alpha: 0.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          fontFamily: AppTypography.displayFamily,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Difficulty chip rendered from backend difficulty strings.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  /// EASY | MEDIUM | HARD (backend enum).
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (difficulty.toUpperCase()) {
      'EASY' => (AppColors.success, 'EASY'),
      'MEDIUM' => (AppColors.warning, 'MEDIUM'),
      'HARD' => (AppColors.error, 'HARD'),
      _ => (AppColors.textSecondary, difficulty.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(difficulty), size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String d) => switch (d.toUpperCase()) {
    'EASY' => Icons.shield_outlined,
    'MEDIUM' => Icons.shield_moon_outlined,
    'HARD' => Icons.local_fire_department_outlined,
    _ => Icons.shield_outlined,
  };
}

/// Streak flame chip for headers.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days, this.onTap});

  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = days > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: onTap != null,
        label: 'Streak $days ${days == 1 ? 'day' : 'days'}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? AppColors.streak.withValues(alpha: 0.16)
                : (isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: active
                  ? AppColors.streak.withValues(alpha: 0.55)
                  : (isDark ? AppColors.border : AppLightColors.border),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.streak.withValues(alpha: 0.28),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active
                    ? Icons.local_fire_department
                    : Icons.local_fire_department_outlined,
                size: 15,
                color: active ? AppColors.streak : AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                '$days',
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.streak : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                days == 1 ? 'DAY' : 'DAYS',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: active ? AppColors.streak : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold XP pill — always data-driven. Pass real XP value; never fabricate.
class XPBadge extends StatelessWidget {
  const XPBadge({super.key, required this.xp, this.compact = false});

  final int xp;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '$xp XP',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.xp.withValues(alpha: isDark ? 0.14 : 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.xp.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: compact ? 13 : 14,
              color: AppColors.xp,
            ),
            const SizedBox(width: 4),
            Text(
              compact ? '$xp' : '+$xp XP',
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: isDark ? AppColors.xp : const Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category chip for game/world grouping — consistent height 36, pill, selectable.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10)
                : (isDark ? AppColors.surface : AppLightColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : (isDark ? AppColors.border : AppLightColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: selected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textSecondary
                            : AppLightColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic status pill — locked / available / completed / featured.
enum StatusKind { locked, available, completed, featured, inProgress }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.kind, this.label});

  final StatusKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (kind) {
      StatusKind.locked => (
        AppColors.locked,
        Icons.lock_rounded,
        label ?? 'LOCKED',
      ),
      StatusKind.available => (
        AppColors.success,
        Icons.play_circle_rounded,
        label ?? 'AVAILABLE',
      ),
      StatusKind.completed => (
        AppColors.success,
        Icons.check_circle_rounded,
        label ?? 'COMPLETED',
      ),
      StatusKind.featured => (
        AppColors.primary,
        Icons.star_rounded,
        label ?? 'FEATURED',
      ),
      StatusKind.inProgress => (
        AppColors.warning,
        Icons.timelapse_rounded,
        label ?? 'IN PROGRESS',
      ),
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: kind == StatusKind.locked
            ? (isDark ? AppColors.lockedSurface : AppLightColors.lockedSurface)
            : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(
            alpha: kind == StatusKind.locked ? 0.35 : 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Locked indicator — icon + label, for path nodes / game cards.
class LockedIndicator extends StatelessWidget {
  const LockedIndicator({super.key, this.label = 'LOCKED', this.size = 13});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.lock_rounded, size: size, color: AppColors.locked),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppColors.locked,
        ),
      ),
    ],
  );
}
