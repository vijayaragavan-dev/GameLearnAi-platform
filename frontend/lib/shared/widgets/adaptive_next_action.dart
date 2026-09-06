import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// Reusable premium "Recommended for you" card driven by A5 intelligence.
/// Supports loading/insufficient/error states, actionable CTA, optional game/difficulty.
class AdaptiveNextActionCard extends StatelessWidget {
  const AdaptiveNextActionCard({
    super.key,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.onAction,
    this.topicName,
    this.subjectName,
    this.gameType,
    this.difficulty,
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
  });

  final String title;
  final String reason;
  final String actionLabel;
  final VoidCallback onAction;
  final String? topicName;
  final String? subjectName;
  final String? gameType;
  final String? difficulty;
  final bool isLoading;
  final bool isError;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
        child: Row(children: [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Text('Loading your next step…', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))]),
      );
    }
    if (isError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
        child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error), const SizedBox(width: 8), Expanded(child: Text(errorMessage ?? 'Something went wrong loading your insights.', style: const TextStyle(fontSize: 12, color: AppColors.error)))]),
      );
    }
    // Insufficient data is handled by caller via empty title/reason, but also support generic
    return Semantics(
      button: true,
      label: 'Recommended $title, $reason',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [AppColors.primary.withValues(alpha: 0.14), AppColors.surfaceElevated] : [AppColors.primary.withValues(alpha: 0.07), AppColors.surface]),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.primary.withValues(alpha: isDark ? 0.32 : 0.20)),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)), child: const Text('RECOMMENDED FOR YOU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.primary))),
              const Spacer(),
              Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.9)),
            ]),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
            const SizedBox(height: 4),
            Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.35, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
            if (topicName != null || subjectName != null || gameType != null || difficulty != null) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (topicName != null) _Pill(label: topicName!.toUpperCase(), icon: Icons.topic_rounded, color: AppColors.secondary),
                if (subjectName != null) _Pill(label: subjectName!.toUpperCase(), icon: Icons.public_rounded, color: AppColors.primary),
                if (gameType != null) _Pill(label: gameType!.toUpperCase().replaceAll('_', ' '), icon: Icons.sports_esports_rounded, color: AppColors.primary),
                if (difficulty != null) _Pill(label: difficulty!.toUpperCase(), icon: Icons.speed_rounded, color: AppColors.textTertiary),
              ]),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.play_arrow_rounded, size: 18), label: Text(actionLabel.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8)), style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12))),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.22))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 11, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: color))]),
      );
}

/// Compact mastery badge with label mapping.
class MasteryBadge extends StatelessWidget {
  const MasteryBadge({super.key, required this.score});
  final double score;
  @override
  Widget build(BuildContext context) {
    final label = score >= 80 ? 'MASTERED' : score >= 60 ? 'STRONG' : score >= 40 ? 'PRACTICING' : score > 0 ? 'DEVELOPING' : 'STARTING';
    final color = score >= 80 ? AppColors.success : score >= 60 ? AppColors.secondary : score >= 40 ? AppColors.warning : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.28))),
      child: Text('$label • ${score.round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: color)),
    );
  }
}
