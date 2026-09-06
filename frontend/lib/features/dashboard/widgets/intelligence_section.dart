import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/intelligence/learner_intelligence.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/responsive_layout.dart';
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
    final recs = AdaptiveEngine.recommendations(intel, data.recommendations);

    // Insufficient data truthful state
    if (intel.insufficientData) {
      return GameCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.psychology_rounded, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text('YOUR LEARNING INTELLIGENCE', style: AppTypography.overline(context).copyWith(color: AppColors.primary))]),
            const SizedBox(height: 8),
            Text('Keep learning to unlock personalized insights', style: AppTypography.h3(context)),
            const SizedBox(height: 6),
            Text('Not enough activity yet to identify weak topics. Complete a quiz or play a game to generate your first insights.', style: AppTypography.bodySecondary(context)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(label: const Text('Explore Worlds'), onPressed: () => context.go(Routes.subjects)),
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
        // Recommended next action
        if (recs.isNotEmpty) ...[
          Text('RECOMMENDED NEXT', style: AppTypography.overline(context)),
          const SizedBox(height: 8),
          for (final r in recs.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GameCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.22))), child: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(r.reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 6, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)), child: Text(r.difficulty, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary))),
                          if (r.gameType != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)), child: Text(r.gameType!.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.secondary))),
                        ]),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () => _handleRecTap(context, r), style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), child: Text(r.actionLabel.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
            ),
        ],
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
                  Icon(Icons.warning_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.topicName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                    Text('Mastery ${w.masteryScore.round()}% • ${w.trend.isEmpty ? 'needs practice' : w.trend.toLowerCase()} • ${w.currentDifficulty}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                  ])),
                  TextButton(onPressed: () => context.push(Routes.tutorWithContext(topicId: w.topicId, topicName: w.topicName, focus: w.topicName)), child: const Text('TUTOR')),
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
        // Revision queue
        if (intel.revisionQueue.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('REVISION PRIORITY', style: AppTypography.overline(context)),
          const SizedBox(height: 8),
          for (final rev in intel.revisionQueue)
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
                  OutlinedButton(onPressed: () => context.push(Routes.tutorWithContext(topicId: rev.topicId, topicName: rev.topicName, focus: rev.topicName)), child: const Text('REVISE')),
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
        // Recommended games
        if (intel.recommendedGames.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('PERSONALIZED GAMES', style: AppTypography.overline(context)),
          const SizedBox(height: 8),
          AdaptiveGrid(
            compact: 1,
            medium: 2,
            expanded: 2,
            wide: 3,
            spacing: 10,
            children: [
              for (final g in intel.recommendedGames)
                GameCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g.gameType.toUpperCase().replaceAll('_', ' '), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(g.topicName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(g.reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.push(Routes.gameHub(g.topicId), extra: g.topicName), child: Text('PLAY ${g.gameType.toUpperCase()}'))),
                  ]),
                ),
            ],
          ),
        ],
        // AI Tutor suggestion
        const SizedBox(height: 12),
        GameCard(
          child: Row(children: [
            const Icon(Icons.psychology_rounded, color: AppColors.secondary),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AI TUTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.secondary)),
              const SizedBox(height: 2),
              Text(intel.weakTopics.isNotEmpty ? 'Get help with ${intel.weakTopics.first.topicName} — contextual guidance ready' : 'Get hints, explanations, or a study plan', style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
            ])),
            const SizedBox(width: 10),
            FilledButton(onPressed: () => context.push(Routes.tutorWithContext(topicId: intel.weakTopics.isNotEmpty ? intel.weakTopics.first.topicId : null, topicName: intel.weakTopics.isNotEmpty ? intel.weakTopics.first.topicName : null, focus: intel.weakTopics.isNotEmpty ? intel.weakTopics.first.topicName : null)), style: FilledButton.styleFrom(backgroundColor: AppColors.secondary), child: const Text('OPEN')),
          ]),
        ),
      ],
    );
  }

  void _handleRecTap(BuildContext context, AdaptiveRecommendation r) {
    if (r.topicId != null) {
      if (r.gameType != null) {
        context.push(Routes.gameHub(r.topicId!, subjectId: null, subjectName: r.topicName), extra: r.topicName);
      } else {
        context.push(Routes.topic(r.topicId!));
      }
    } else {
      context.go(Routes.subjects);
    }
  }
}
