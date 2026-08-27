import 'package:flutter/material.dart';

import '../../core/models/dashboard_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';
import 'game_button.dart';
import '../../core/utils/formatters.dart';

/// Adaptive recommendation tile: PERFORMANCE -> AI ADAPTATION -> NEXT MISSION.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.item,
    required this.onStart,
    this.compact = false,
  });

  final RecommendationItem item;
  final VoidCallback onStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, _) = EnumPresentation.activityType(item.activityType);
    final tint = _tintFor(item.activityType);
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.13), AppColors.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: tint.withValues(alpha: 0.18),
                  border: Border.all(color: tint.withValues(alpha: 0.45)),
                ),
                child: Icon(
                  _activityIcon(item.activityType),
                  size: 17,
                  color: tint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: tint,
                  ),
                ),
              ),
              if (item.priority > 0) ...[
                PriorityPill(priority: item.priority),
                const SizedBox(width: 7),
              ],
              DifficultyPill(difficulty: item.recommendedDifficulty),
            ],
          ),
          if (!compact && item.topicName != null) ...[
            const SizedBox(height: 12),
            Text(
              item.topicName!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.reason,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (!compact) ...[
            const SizedBox(height: 14),
            GameChip(
              label: 'VIEW MISSION',
              icon: Icons.arrow_forward_rounded,
              color: tint,
              onTap: onStart,
            ),
          ],
        ],
      ),
    );
    if (!compact) return card;
    return Semantics(
      button: true,
      label: item.topicName == null
          ? 'Open recommendation'
          : 'Open recommendation for ${item.topicName}',
      child: PressableScale(onTap: onStart, child: card),
    );
  }

  IconData _activityIcon(String activity) => switch (activity) {
    'QUIZ' => Icons.sports_esports_rounded,
    'REMEDIATION' => Icons.build_rounded,
    'REVIEW' => Icons.replay_rounded,
    'ADVANCE' => Icons.rocket_launch_rounded,
    'CONTINUE_LESSON' => Icons.menu_book_rounded,
    'PRACTICE' => Icons.school_rounded,
    _ => Icons.auto_awesome_rounded,
  };

  Color _tintFor(String activity) => switch (activity) {
    'QUIZ' => AppColors.error,
    'REMEDIATION' => AppColors.warning,
    'REVIEW' => AppColors.secondary,
    'ADVANCE' => AppColors.success,
    'CONTINUE_LESSON' => AppColors.primaryBright,
    'PRACTICE' => AppColors.primary,
    _ => AppColors.primary,
  };
}

/// Backend-assigned recommendation priority. The client only displays it.
class PriorityPill extends StatelessWidget {
  const PriorityPill({super.key, required this.priority});

  final int priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      1 => AppColors.warning,
      2 => AppColors.primaryBright,
      3 => AppColors.secondary,
      4 => AppColors.success,
      _ => AppColors.textTertiary,
    };
    return Semantics(
      label: 'Priority $priority',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Text(
          'P$priority',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Difficulty pill rendered from backend difficulty strings.
class DifficultyPill extends StatelessWidget {
  const DifficultyPill({super.key, required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    if (difficulty.isEmpty) return const SizedBox.shrink();
    final color = switch (difficulty.toUpperCase()) {
      'EASY' => AppColors.success,
      'MEDIUM' => AppColors.warning,
      'HARD' => AppColors.error,
      _ => AppColors.textTertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

/// Section header with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppTypography.bodyFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
            color: AppColors.textTertiary,
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
