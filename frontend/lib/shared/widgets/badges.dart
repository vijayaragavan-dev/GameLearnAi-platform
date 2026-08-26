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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? null : null,
          color: active
              ? AppColors.streak.withValues(alpha: 0.16)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active
                ? AppColors.streak.withValues(alpha: 0.55)
                : AppColors.border,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.streak.withValues(alpha: 0.3),
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
    );
  }
}
