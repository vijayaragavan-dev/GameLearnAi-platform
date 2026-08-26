import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/dashboard_models.dart' hide Dashboard;
import '../../../core/models/gamification_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/recommendation_card.dart'
    show SectionHeader, DifficultyPill;
import '../../../shared/widgets/stat_card.dart';

/// Player statistics: overall mastery, level, streak, mastery radar,
/// recent quiz accuracy. All values are backend-provided reads.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  Future<
    (
      LearnerProfile,
      GamificationSummary,
      StreakState,
      List<RecentTopicMastery>,
      List<RecentQuizRun>,
    )
  >?
  _future;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.dashboard);
    _reload();
  }

  void _reload() {
    setState(() {
      final repo = ref.read(gamificationRepoProvider);
      final intel = ref.read(intelligenceRepoProvider);
      _future = () async {
        final profile = await repo.profile();
        final summary = await repo.summary();
        final streak = await repo.streak();
        final dashboard = await intel.dashboard();
        return (
          profile,
          summary,
          streak,
          dashboard.mastery.recentTopics,
          dashboard.recentActivity.quizzes,
        );
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLAYER STATS')),
      body: RefreshIndicator(
        color: AppColors.primaryBright,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async => _reload(),
        child: FutureBuilder(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done && !snap.hasData) {
              return ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [SkeletonList(itemCount: 3, itemHeight: 130)],
              );
            }
            if (snap.hasError) {
              final err = describeError(snap.error!);
              return ErrorState(
                title: err.title,
                message: err.message,
                onRetry: _reload,
              );
            }
            final (profile, summary, streak, topics, quizzes) = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'LEVEL',
                        value: '${summary.currentLevel}',
                        sub: summary.atMaxLevel
                            ? 'MAX LEVEL'
                            : '${summary.xpToNextLevel} XP to next',
                        tint: AppColors.primaryBright,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'TOTAL XP',
                        value: Formatters.count(summary.totalXp),
                        tint: AppColors.xp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'STREAK',
                        value: '${streak.currentStreakDays}',
                        sub: 'days Â· best ${streak.longestStreakDays}',
                        tint: AppColors.streak,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go(Routes.achievements),
                        child: StatCard(
                          label: 'BADGES',
                          value: '${summary.unlockedAchievements}',
                          sub: 'unlocked',
                          tint: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Overall mastery ring.
                GameCard(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 86,
                        height: 86,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: profile.overallMastery / 100,
                              ),
                              duration: AppMotion.celebration,
                              curve: AppMotion.easeOut,
                              builder: (context, v, _) =>
                                  CircularProgressIndicator(
                                    value: v.clamp(0, 1),
                                    strokeWidth: 7,
                                    strokeCap: StrokeCap.round,
                                    color: AppColors.primaryBright,
                                    backgroundColor: AppColors.surfaceHigh,
                                  ),
                            ),
                            Text(
                              Formatters.percent(profile.overallMastery),
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OVERALL MASTERY',
                              style: TextStyle(
                                fontSize: 10.5,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Across every assessed topic.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Mastery radar.
                const SectionHeader(title: 'Topic performance'),
                if (topics.isEmpty)
                  const EmptyMiniCard(
                    text:
                        'Complete an assessment or challenge to reveal your mastery radar.',
                  )
                else
                  ...topics.map((t) {
                    final tint = switch (t.masteryLevel) {
                      'MASTERED' => AppColors.xp,
                      'PROFICIENT' => AppColors.success,
                      'DEVELOPING' => AppColors.warning,
                      _ => AppColors.secondaryDeep,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () =>
                            context.push(Routes.topicPerformance(t.topicId)),
                        child: GameCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.topicName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Formatters.percent(t.masteryScore),
                                    style: TextStyle(
                                      fontFamily: AppTypography.displayFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: tint,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (t.masteryScore / 100).clamp(0, 1),
                                  minHeight: 5,
                                  color: tint,
                                  backgroundColor: AppColors.surfaceHigh,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  DifficultyPill(
                                    difficulty: t.currentDifficulty,
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.north_east_rounded,
                                    size: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                  Text(
                                    t.trend.toLowerCase(),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                // Accuracy trend.
                if (quizzes.length >= 2) ...[
                  const SizedBox(height: 14),
                  const SectionHeader(title: 'Recent accuracy'),
                  GameCard(
                    child: SizedBox(
                      height: 110,
                      child: AccuracyBars(quizzes: quizzes.reversed.toList()),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Simple accuracy bar chart - only when it improves understanding.
class AccuracyBars extends StatelessWidget {
  const AccuracyBars({super.key, required this.quizzes});

  final List<RecentQuizRun> quizzes;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final q in quizzes.take(10))
          Expanded(
            child: Tooltip(
              message: '${q.topicName}: ${Formatters.percent(q.score)}',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final h =
                        (q.score / 100).clamp(0.05, 1.0) *
                        constraints.maxHeight;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: q.score >= 80
                              ? AppColors.success.withValues(alpha: 0.85)
                              : q.score >= 50
                              ? AppColors.warning.withValues(alpha: 0.85)
                              : AppColors.error.withValues(alpha: 0.85),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
