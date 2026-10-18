import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/intelligence/learner_intelligence.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../providers/dashboard_provider.dart';

/// AI-powered learning intelligence — mastery, weak areas, revision, next difficulty, game picks.
/// All derived from real Dashboard data; insufficient-data state is truthful.
class IntelligenceSection extends ConsumerWidget {
  const IntelligenceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final data = state.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (data == null) return const SizedBox.shrink();

    final intel = AdaptiveEngine.fromDashboard(data);

    // Revision entries that are already surfaced as focus areas would render
    // the same topic (and the same tutor action) a second time, so the
    // revision list only carries topics the focus list does not show.
    final weakTopicIds = {
      for (final w in intel.weakTopics) w.topicId,
    };
    final revisionOnly = intel.revisionQueue
        .where((rev) => !weakTopicIds.contains(rev.topicId))
        .toList(growable: false);

    // Insufficient data truthful state
    if (intel.insufficientData) {
      return GameCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.psychology_rounded, size: 18, color: AppColors.primary), const SizedBox(width: 8), Flexible(child: Text('YOUR LEARNING INTELLIGENCE', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.overline(context).copyWith(color: AppColors.primary)))]),
            const SizedBox(height: 8),
            Text('Keep learning to unlock personalized insights', style: AppTypography.h3(context)),
            const SizedBox(height: 6),
            Text('Not enough activity yet to identify weak topics. Complete a quiz or play a game to generate your first insights.', style: AppTypography.bodySecondary(context)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(label: const Text('Explore Worlds'), onPressed: () => context.push(Routes.subjects)),
              ActionChip(label: const Text('Open Tutor'), onPressed: () => context.push(Routes.tutor)),
            ]),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mastery overview
        FeaturedSurface(
          accent: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR LEARNING INTELLIGENCE', style: AppTypography.overline(context).copyWith(color: AppColors.primaryBright)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text('${intel.overallMastery.round()}% Mastery', style: AppTypography.hero(context, size: 20))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AdaptiveEngine.masteryColor(intel.overallMastery, isDark).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: AdaptiveEngine.masteryColor(intel.overallMastery, isDark).withValues(alpha: 0.3))),
                    child: Text(intel.trend.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AdaptiveEngine.masteryColor(intel.overallMastery, isDark))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${intel.topicsAssessed} topics assessed • ${intel.topicsMastered} mastered • next: ${intel.nextDifficulty}', style: AppTypography.caption(context)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (intel.overallMastery / 100).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation(AdaptiveEngine.masteryColor(intel.overallMastery, isDark)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Weak areas / strong areas
        if (intel.weakTopics.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('FOCUS AREAS', style: AppTypography.overline(context)),
          const SizedBox(height: 8),
          for (final w in intel.weakTopics.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.error.withValues(alpha: 0.25))),
                child: Row(children: [
                  const Icon(Icons.warning_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.topicName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                    Text('Mastery ${w.masteryScore.round()}% • ${w.trend.isEmpty ? 'needs practice' : w.trend.toLowerCase()} • ${w.currentDifficulty}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                  ])),
                  GameChip(label: 'TUTOR', icon: Icons.psychology_rounded, color: AppColors.secondary, onTap: () => context.push(Routes.tutorWithContext(topicId: w.topicId, topicName: w.topicName, focus: w.topicName))),
                ]),
              ),
            ),
        ],
        if (intel.strongTopics.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('STRONG AREAS', style: AppTypography.overline(context)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in intel.strongTopics.take(3))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.success.withValues(alpha: 0.28))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success), const SizedBox(width: 6), Text('${s.topicName} ${s.masteryScore.round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success))]),
              ),
          ]),
        ],
        // Revision queue (only topics not already listed as focus areas)
        if (revisionOnly.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('REVISION PRIORITY', style: AppTypography.overline(context)),
          const SizedBox(height: 8),
          for (final rev in revisionOnly)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
                child: Row(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.warning.withValues(alpha: 0.14)), child: const Icon(Icons.replay_rounded, size: 16, color: AppColors.warning)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rev.topicName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                    Text('${rev.masteryScore.round()}% • Next: ${rev.currentDifficulty}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                  ])),
                  GameChip(label: 'REVISE', icon: Icons.replay_rounded, color: AppColors.warning, onTap: () => context.push(Routes.tutorWithContext(topicId: rev.topicId, topicName: rev.topicName, focus: rev.topicName))),
                ]),
              ),
            ),
        ],
        // Mistakes
        if (intel.mistakes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('RECENT MISTAKES', style: AppTypography.overline(context)),
          const SizedBox(height: 8),
          for (final m in intel.mistakes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.topicName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                    Text(m.detail, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                  ])),
                ]),
              ),
            ),
        ],
        // Recommended games — compact rows: the full card grid duplicated the
        // Game zone further down the same page.
        if (intel.recommendedGames.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('PERSONALIZED GAMES', style: AppTypography.overline(context)),
          const SizedBox(height: 8),
          for (final g in intel.recommendedGames.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.gameType.toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          g.topicName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppLightColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GameChip(
                    label: 'PLAY',
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    onTap: () => context.push(
                      Routes.gameHub(g.topicId),
                      extra: g.topicName,
                    ),
                  ),
                ]),
              ),
            ),
        ],
        // AI Tutor suggestion
        const SizedBox(height: 12),
        GameCard(
          child: Row(children: [
            const Icon(Icons.psychology_rounded, color: AppColors.secondary),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('STUDY BUDDY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.secondary)),
              const SizedBox(height: 2),
              Text(intel.weakTopics.isNotEmpty ? 'Get help with ${intel.weakTopics.first.topicName} — contextual guidance ready' : 'Get hints, explanations, or a study plan', style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
            ])),
            const SizedBox(width: 10),
            GameChip(label: 'OPEN', icon: Icons.psychology_rounded, color: AppColors.secondary, onTap: () => context.push(Routes.tutorWithContext(topicId: intel.weakTopics.isNotEmpty ? intel.weakTopics.first.topicId : null, topicName: intel.weakTopics.isNotEmpty ? intel.weakTopics.first.topicName : null, focus: intel.weakTopics.isNotEmpty ? intel.weakTopics.first.topicName : null))),
          ]),
        ),
      ],
    );
  }
}
