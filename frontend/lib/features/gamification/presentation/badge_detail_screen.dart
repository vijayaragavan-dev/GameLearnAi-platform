import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/gamification_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/achievement_icon.dart';
import '../../../shared/widgets/game_button.dart';

/// Badge detail. Receives the catalog entry via router extra; refetches
/// nothing (GAM-002 already carries the full record).
class BadgeDetailScreen extends StatelessWidget {
  const BadgeDetailScreen({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BADGE')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          children: [
            const SizedBox(height: 12),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1),
                duration: AppMotion.feature,
                curve: AppMotion.spring,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: AchievementIcon(
                  iconKey: achievement.iconKey,
                  unlocked: achievement.isUnlocked,
                  size: 130,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Text(
                achievement.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!achievement.isUnlocked) ...[
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'LOCKED',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.description,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 28),
                  _Row(
                    label: 'XP REWARD',
                    value: '+${achievement.xpReward} XP',
                    valueColor: AppColors.xp,
                  ),
                  _Row(
                    label: 'STATUS',
                    value: achievement.isUnlocked ? 'Unlocked' : 'Locked',
                    valueColor: achievement.isUnlocked
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                  if (achievement.isUnlocked)
                    _Row(
                      label: 'UNLOCKED',
                      value: Formatters.shortDate(achievement.unlockedAt),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SecondaryGameButton(
              label: 'Back to trophy room',
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
