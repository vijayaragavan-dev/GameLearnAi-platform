import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext;
import '../../../core/error/user_facing_error.dart';
import '../../../core/intelligence/learner_intelligence.dart';
import '../../../core/models/dashboard_models.dart' hide Dashboard;
import '../../../core/models/gamification_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/adaptive_next_action.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/recommendation_card.dart'
    show SectionHeader, DifficultyPill;
import '../../../shared/widgets/stat_card.dart';

/// Mastery filter — presentational only, never recomputes mastery.
enum MasteryFilter { all, strong, developing, needsPractice }

extension MasteryFilterExt on MasteryFilter {
  String get label => switch (this) {
    MasteryFilter.all => 'All',
    MasteryFilter.strong => 'Strong',
    MasteryFilter.developing => 'Developing',
    MasteryFilter.needsPractice => 'Needs Practice',
  };

  bool matches(RecentTopicMastery m) => switch (this) {
    MasteryFilter.all => true,
    MasteryFilter.strong =>
      m.masteryLevel == 'MASTERED' || m.masteryLevel == 'PROFICIENT',
    MasteryFilter.developing => m.masteryLevel == 'DEVELOPING',
    MasteryFilter.needsPractice => m.masteryLevel == 'BEGINNER',
  };
}

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

  MasteryFilter _filter = MasteryFilter.all;

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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceElevated
            : Colors.white,
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
            // Filtered view — presentational only.
            final filtered = topics.where((t) => _filter.matches(t)).toList();
            // Identify weak focus (lowest mastery among Needs Practice, or overall lowest)
            RecentTopicMastery? focus;
            if (topics.isNotEmpty) {
              final candidates = topics
                  .where((t) => t.masteryLevel == 'BEGINNER')
                  .toList();
              final pool = candidates.isNotEmpty ? candidates : topics;
              focus = pool.reduce(
                (a, b) => a.masteryScore < b.masteryScore ? a : b,
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isDark =
                    Theme.of(context).brightness == Brightness.dark;
                final isCompact = width < 600;
                final isExpanded = width >= 1024;
                final contentMax = isExpanded ? 840.0 : double.infinity;
                final horizontalPad = isCompact ? 16.0 : 20.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMax),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        8,
                        horizontalPad,
                        110,
                      ),
                      child: Column(
                        children: [
                          // ── Cinematic stats header (reference: level band
                          // + tagline). All values are the same backend reads
                          // used below — identity strip, not a second source.
                          FeaturedSurface(
                            accent: AppColors.primary,
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                            scene: ScenePalette.violet,
                            sceneSeed: seedForKey(profile.displayName),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'YOUR PROGRESS',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTypography.displayFamily,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Track your progress. See your growth.',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: Theme.of(
                                                    context,
                                                  ).brightness ==
                                                  Brightness.dark
                                                  ? AppColors.textSecondary
                                                  : AppLightColors
                                                        .textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const NeonQuote(
                                      text:
                                          'PROGRESS\nTURNS EFFORT\nINTO MASTERY',
                                      fontSize: 10,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _StatChip(
                                      icon: Icons.military_tech_rounded,
                                      label:
                                          'LEVEL ${summary.currentLevel}',
                                      color: AppColors.primaryBright,
                                    ),
                                    _StatChip(
                                      icon: Icons.bolt_rounded,
                                      label:
                                          '${Formatters.count(summary.totalXp)} XP',
                                      color: AppColors.xp,
                                    ),
                                    _StatChip(
                                      icon: Icons
                                          .local_fire_department_rounded,
                                      label:
                                          '${streak.currentStreakDays}-DAY STREAK',
                                      color: AppColors.streak,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Hero stats — responsive grid.
                          if (isCompact)
                            Column(
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
                                        value: Formatters.count(
                                          summary.totalXp,
                                        ),
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
                                        sub:
                                            'days · best ${streak.longestStreakDays}',
                                        tint: AppColors.streak,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            context.go(Routes.achievements),
                                        child: StatCard(
                                          label: 'BADGES',
                                          value:
                                              '${summary.unlockedAchievements}',
                                          sub: 'unlocked',
                                          tint: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    label: 'LEVEL',
                                    value: '${summary.currentLevel}',
                                    sub: summary.atMaxLevel
                                        ? 'MAX'
                                        : '${summary.xpToNextLevel} XP',
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    label: 'STREAK',
                                    value: '${streak.currentStreakDays}',
                                    sub: 'best ${streak.longestStreakDays}',
                                    tint: AppColors.streak,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.go(Routes.achievements),
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

                          // Overall mastery — gamified hero.
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
                                        duration: AppMotion.durFor(
                                          context,
                                          AppMotion.celebration,
                                        ),
                                        curve: AppMotion.easeOut,
                                        builder: (context, v, _) =>
                                            CircularProgressIndicator(
                                              value: v.clamp(0, 1),
                                              strokeWidth: 7,
                                              strokeCap: StrokeCap.round,
                                              color: AppColors.primaryBright,
                                              backgroundColor: isDark
                                                  ? AppColors.surfaceHigh
                                                  : AppLightColors
                                                        .surfaceHigh,
                                            ),
                                      ),
                                      Semantics(
                                        label:
                                            'Overall mastery ${Formatters.percent(profile.overallMastery)}',
                                        child: Text(
                                          Formatters.percent(
                                            profile.overallMastery,
                                          ),
                                          style: const TextStyle(
                                            fontFamily:
                                                AppTypography.displayFamily,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
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
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppLightColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Mastery header + filter chips.
                          const NeonSectionHeader(
                            icon: Icons.radar_rounded,
                            title: 'Topic mastery',
                            subtitle: 'Stages update as you learn',
                            accent: AppColors.primary,
                          ),
                          if (topics.isEmpty)
                            const EmptyMiniCard(
                              text:
                                  'Complete an assessment or challenge to reveal your mastery radar.',
                            )
                          else ...[
                            _MasteryFilterChips(
                              topics: topics,
                              selected: _filter,
                              onSelected: (f) => setState(() => _filter = f),
                            ),
                            const SizedBox(height: 12),
                            if (filtered.isEmpty)
                              EmptyMiniCard(
                                text:
                                    'No topics yet in "${_filter.label}" — keep exploring to grow your skills.',
                              )
                            else
                              ...filtered.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _MasteryCard(topic: t),
                                ),
                              ),
                            // Weak-area emphasis — honest, non-shaming.
                            if (focus != null &&
                                focus.masteryLevel == 'BEGINNER') ...[
                              const SizedBox(height: 14),
                              GlowCard(
                                glowColor: AppColors.warning,
                                intensity: 0.22,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.warning.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: Border.all(
                                          color: AppColors.warning.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.flag_rounded,
                                        color: AppColors.warning,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'FOCUS MISSION',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              letterSpacing: 1.6,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            focus.topicName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.textPrimary
                                                  : AppLightColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Needs practice — ${Formatters.percent(focus.masteryScore)} mastery. Your next mission can strengthen this skill.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.35,
                                              color: isDark
                                                  ? AppColors.textSecondary
                                                  : AppLightColors
                                                        .textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'View topic',
                                      onPressed: () => context.push(
                                        Routes.topicPerformance(focus!.topicId),
                                      ),
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          // Recent accuracy — sparkline/history.
                          if (quizzes.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const NeonSectionHeader(
                              icon: Icons.track_changes_rounded,
                              title: 'Recent accuracy',
                              subtitle:
                                  'Your performance in recent attempts',
                              accent: AppColors.secondary,
                            ),
                            if (quizzes.length >= 2)
                              GameCard(
                                child: SizedBox(
                                  height: 152,
                                  child: AccuracyBars(
                                    quizzes: quizzes.reversed.toList(),
                                  ),
                                ),
                              )
                            else
                              const EmptyMiniCard(
                                text:
                                    'Complete one more mission to reveal your accuracy trend.',
                              ),
                            const SizedBox(height: 8),
                            // Sparkline of scores over time (backend-provided RecentQuizRun.score)
                            if (quizzes.length >= 2) ...[
                              const SizedBox(height: 8),
                              GameCard(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SCORE TRAJECTORY',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        letterSpacing: 1.8,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 56,
                                      width: double.infinity,
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: _ScoreSparkline(
                                              scores: quizzes.reversed
                                                  .map((q) => q.score)
                                                  .toList(),
                                            ),
                                          ),
                                          // Latest-value badge (reference:
                                          // glowing % pill at the line end).
                                          // Same backend read as the axis
                                          // labels below — no new data.
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Semantics(
                                              label:
                                                  'Latest score ${Formatters.percent(quizzes.first.score)}',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.9),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  Formatters.percent(
                                                    quizzes.first.score,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          Formatters.percent(
                                            quizzes.last.score,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        const Text(
                                          'most recent →',
                                          style: TextStyle(
                                            fontSize: 10,
                                            letterSpacing: 1,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        Text(
                                          Formatters.percent(
                                            quizzes.first.score,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ] else ...[
                            const SizedBox(height: 18),
                            const NeonSectionHeader(
                              icon: Icons.track_changes_rounded,
                              title: 'Recent accuracy',
                              subtitle:
                                  'Your performance in recent attempts',
                              accent: AppColors.secondary,
                            ),
                            const EmptyMiniCard(
                              text:
                                  'Complete a few missions to reveal your skill trend.',
                            ),
                          ],

                          // ── MASTERY DISTRIBUTION (A8)
                          const SizedBox(height: 18),
                          _MasteryDistribution(topics: topics),
                          // ── GAME PERFORMANCE (A8)
                          const SizedBox(height: 18),
                          _GamePerformance(quizzes: quizzes),
                          // ── LEARNING CONSISTENCY (A8)
                          const SizedBox(height: 18),
                          _ConsistencySection(streak: streak, quizzes: quizzes),
                          // ── ACHIEVEMENT PROGRESS (A8)
                          const SizedBox(height: 18),
                          _AchievementProgress(summary: summary),
                          // ── RECOMMENDED NEXT ACTION (A8) via AdaptiveEngine
                          const SizedBox(height: 18),
                          _ProgressRecommendedNext(topics: topics, quizzes: quizzes),
                          // ── CONNECTIONS: Tutor / Path / Leaderboard (A8)
                          const SizedBox(height: 18),
                          _ProgressConnections(focusTopic: focus),
                          const SizedBox(height: 8),
                          // Honest historical trend note when insufficient series
                          if (quizzes.length < 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.primary.withValues(alpha: 0.14))),
                                child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary), const SizedBox(width: 8), Expanded(child: Text('Historical trend requires 3+ completed activities. Your current view shows the latest available state.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)))]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MasteryDistribution extends StatelessWidget {
  const _MasteryDistribution({required this.topics});
  final List<RecentTopicMastery> topics;
  @override
  Widget build(BuildContext context) {
    final mastered = topics.where((t) => t.masteryLevel == 'MASTERED').length;
    final proficient = topics.where((t) => t.masteryLevel == 'PROFICIENT').length;
    final developing = topics.where((t) => t.masteryLevel == 'DEVELOPING').length;
    final beginner = topics.where((t) => t.masteryLevel == 'BEGINNER').length;
    final total = topics.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (total == 0) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeader(title: 'Mastery distribution'), const SizedBox(height: 8), const EmptyMiniCard(text: 'Complete more learning activities to unlock deeper mastery insights.')]);
    }
    Widget bar(String label, int count, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: total == 0 ? 0 : count / total, minHeight: 8, color: color, backgroundColor: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh))),
            const SizedBox(width: 8),
            Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Mastery distribution'),
      const SizedBox(height: 8),
      GameCard(child: Column(children: [bar('Mastered', mastered, AppColors.xp), bar('Strong', proficient, AppColors.success), bar('Developing', developing, AppColors.warning), bar('Needs Practice', beginner, AppColors.error)])),
    ]);
  }
}

class _GamePerformance extends StatelessWidget {
  const _GamePerformance({required this.quizzes});
  final List<RecentQuizRun> quizzes;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (quizzes.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeader(title: 'Game performance'), const SizedBox(height: 8), const EmptyMiniCard(text: 'No game activity yet. Play a game to see your performance.')]);
    }
    // Show recent quiz performance as proxy for game performance (real data only)
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Game performance'),
      const SizedBox(height: 8),
      GameCard(
        child: Column(
          children: [
            for (final q in quizzes.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: (q.score >= 80 ? AppColors.success : q.score >= 50 ? AppColors.warning : AppColors.error).withValues(alpha: 0.14)), child: Icon(q.score >= 80 ? Icons.emoji_events_rounded : q.score >= 50 ? Icons.trending_up_rounded : Icons.flag_rounded, size: 16, color: q.score >= 80 ? AppColors.success : q.score >= 50 ? AppColors.warning : AppColors.error)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(q.topicName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)), Text('${Formatters.percent(q.score)} • ${q.correctCount}/${q.totalQuestions} correct • ${Formatters.shortDate(q.submittedAt)}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))])),
                  const SizedBox(width: 8),
                  MasteryBadge(score: q.score),
                ]),
              ),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary), const SizedBox(width: 8), Expanded(child: Text('Unplayed games remain clearly unplayed — complete more games to populate this view.', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)))])),
          ],
        ),
      ),
    ]);
  }
}

class _ConsistencySection extends StatelessWidget {
  const _ConsistencySection({required this.streak, required this.quizzes});
  final StreakState streak;
  final List<RecentQuizRun> quizzes;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Learning consistency'),
      const SizedBox(height: 8),
      GameCard(
        child: Row(children: [
          Expanded(child: StatCard(label: 'CURRENT STREAK', value: '${streak.currentStreakDays}', sub: 'days', tint: AppColors.streak)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(label: 'BEST STREAK', value: '${streak.longestStreakDays}', sub: 'days', tint: AppColors.warning)),
        ]),
      ),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)), child: Row(children: [Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary), const SizedBox(width: 8), Expanded(child: Text(quizzes.isEmpty ? 'No recent activity yet. Your consistency will appear after a few learning days.' : 'Recent activity: ${quizzes.length} completed ${quizzes.length == 1 ? 'mission' : 'missions'} • Keep your streak alive by learning daily.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)))])),
    ]);
  }
}

class _AchievementProgress extends StatelessWidget {
  const _AchievementProgress({required this.summary});
  final GamificationSummary summary;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Achievements'),
      const SizedBox(height: 8),
      GameCard(
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.xp.withValues(alpha: 0.14), border: Border.all(color: AppColors.xp.withValues(alpha: 0.32))), child: const Icon(Icons.emoji_events_rounded, size: 22, color: AppColors.xp)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${summary.unlockedAchievements} Badges earned', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)), const SizedBox(height: 2), Text('Keep completing challenges to unlock rare achievements.', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))])),
          const SizedBox(width: 8),
          FilledButton(onPressed: () => context.go(Routes.achievements), style: FilledButton.styleFrom(backgroundColor: AppColors.xp, foregroundColor: Colors.black), child: const Text('VIEW')),
        ]),
      ),
    ]);
  }
}

class _ProgressRecommendedNext extends StatelessWidget {
  const _ProgressRecommendedNext({required this.topics, required this.quizzes});
  final List<RecentTopicMastery> topics;
  final List<RecentQuizRun> quizzes;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Derive weak/strong via same thresholds as AdaptiveEngine for consistency
    final weak = topics.where((t) => t.masteryScore < 40 || (t.trend == 'DECLINING' && t.masteryScore < 60)).toList()..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
    if (weak.isNotEmpty) {
      final w = weak.first;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Recommended next'),
        const SizedBox(height: 8),
        AdaptiveNextActionCard(title: 'Practice ${w.topicName}', reason: 'Mastery ${w.masteryScore.round()}% • needs practice — focused revision will help.', topicName: w.topicName, difficulty: w.currentDifficulty.isEmpty ? 'EASY' : w.currentDifficulty, gameType: 'quiz_battle', actionLabel: 'Practice', onAction: () => context.push(Routes.topic(w.topicId))),
      ]);
    }
    if (topics.any((t) => t.masteryScore >= 80)) {
      final s = topics.where((t) => t.masteryScore >= 80).first;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Recommended next'),
        const SizedBox(height: 8),
        AdaptiveNextActionCard(title: 'Challenge ${s.topicName}', reason: 'Strong mastery ${s.masteryScore.round()}% — ready for harder challenges.', topicName: s.topicName, difficulty: 'HARD', gameType: 'boss_battle', actionLabel: 'Challenge', onAction: () => context.push(Routes.topic(s.topicId))),
      ]);
    }
    if (topics.isNotEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Recommended next'),
        const SizedBox(height: 8),
        AdaptiveNextActionCard(title: 'Continue learning', reason: 'Keep exploring your learning path to unlock deeper insights.', actionLabel: 'Continue', onAction: () => context.go(Routes.subjects)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Recommended next'),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)), child: Row(children: [const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary), const SizedBox(width: 8), Expanded(child: Text('Complete your first assessment to unlock personalized next steps.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)))])),
    ]);
  }
}

class _ProgressConnections extends StatelessWidget {
  const _ProgressConnections({required this.focusTopic});
  final RecentTopicMastery? focusTopic;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Continue your journey'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(onPressed: () => context.push(focusTopic != null ? Routes.tutorWithContext(topicId: focusTopic!.topicId, topicName: focusTopic!.topicName, focus: focusTopic!.topicName) : Routes.tutor), icon: const Icon(Icons.psychology_rounded, size: 16), label: const Text('ASK TUTOR'), style: FilledButton.styleFrom(backgroundColor: AppColors.secondary)),
        OutlinedButton.icon(onPressed: () => context.go(Routes.subjects), icon: const Icon(Icons.school_rounded, size: 16), label: const Text('LEARNING PATH')),
        OutlinedButton.icon(onPressed: () => context.go(Routes.arena), icon: const Icon(Icons.leaderboard_rounded, size: 16), label: const Text('LEADERBOARD')),
      ]),
    ]);
  }
}

/// Filter chips row — AlwaysScrollable, 36dp min touch, decorative counts.
class _MasteryFilterChips extends StatelessWidget {
  const _MasteryFilterChips({
    required this.topics,
    required this.selected,
    required this.onSelected,
  });

  final List<RecentTopicMastery> topics;
  final MasteryFilter selected;
  final ValueChanged<MasteryFilter> onSelected;

  int _count(MasteryFilter f) => topics.where((t) => f.matches(t)).length;

  @override
  Widget build(BuildContext context) {
    final chips = MasteryFilter.values;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Row(
        children: [
          for (final f in chips)
            Padding(
              padding: EdgeInsets.only(right: f == chips.last ? 0 : 8),
              child: ChoiceChip(
                label: Text('${f.label} (${_count(f)})'),
                selected: selected == f,
                onSelected: (_) => onSelected(f),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected == f
                      ? Colors.white
                      : (isDark
                            ? AppColors.textSecondary
                            : AppLightColors.textSecondary),
                ),
                selectedColor: AppColors.primary,
                backgroundColor: isDark
                    ? AppColors.surfaceHigh
                    : AppLightColors.surfaceHigh,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: selected == f
                      ? AppColors.primaryBright
                      : (isDark
                            ? AppColors.border
                            : AppLightColors.border),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

/// Single topic mastery card — gamified, accessible, subject-agnostic.
class _MasteryCard extends StatelessWidget {
  const _MasteryCard({required this.topic});

  final RecentTopicMastery topic;

  Color get tint => switch (topic.masteryLevel) {
    'MASTERED' => AppColors.xp,
    'PROFICIENT' => AppColors.success,
    'DEVELOPING' => AppColors.warning,
    'BEGINNER' => AppColors.error,
    _ => AppColors.secondaryDeep,
  };

  IconData get levelIcon => switch (topic.masteryLevel) {
    'MASTERED' => Icons.emoji_events_rounded,
    'PROFICIENT' => Icons.verified_rounded,
    'DEVELOPING' => Icons.trending_up_rounded,
    'BEGINNER' => Icons.flag_rounded,
    _ => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push(Routes.topicPerformance(topic.topicId)),
      child: GameCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint.withValues(alpha: 0.15),
                    border: Border.all(color: tint.withValues(alpha: 0.5)),
                  ),
                  child: Icon(levelIcon, size: 16, color: tint),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.topicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: tint.withValues(alpha: 0.14),
                              border: Border.all(
                                color: tint.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              topic.masteryLevel.isEmpty
                                  ? 'Unknown'
                                  : topic.masteryLevel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: tint,
                              ),
                            ),
                          ),
                          DifficultyPill(difficulty: topic.currentDifficulty),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Mastery ${Formatters.percent(topic.masteryScore)}',
                  child: Text(
                    Formatters.percent(topic.masteryScore),
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (topic.masteryScore / 100).clamp(0, 1),
                minHeight: 6,
                color: tint,
                backgroundColor: isDark
                    ? AppColors.surfaceHigh
                    : AppLightColors.surfaceHigh,
                semanticsLabel:
                    '${topic.topicName} mastery ${Formatters.percent(topic.masteryScore)}',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _TrendIndicator(trend: topic.trend),
                if (topic.lastAssessedAt != null)
                  Text(
                    'Updated ${Formatters.shortDate(topic.lastAssessedAt)}',
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
    );
  }
}

/// Compact identity metric chip for the stats header band — icon + text,
/// never color alone. Values mirror the cards below (same backend reads).
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trend indicator — icon + text, accessible, backend-authoritative.
class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({required this.trend});

  final String trend;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (trend) {
      'IMPROVING' => (Icons.north_east_rounded, 'Improving', AppColors.success),
      'STABLE' => (Icons.drag_handle_rounded, 'Stable', AppColors.secondary),
      'DECLINING' => (
        Icons.south_east_rounded,
        'Needs attention',
        AppColors.warning,
      ),
      'INSUFFICIENT_DATA' => (
        Icons.bubble_chart_rounded,
        'New',
        AppColors.textTertiary,
      ),
      _ => (
        Icons.circle_outlined,
        trend.isEmpty ? 'New' : trend,
        AppColors.textTertiary,
      ),
    };
    return Semantics(
      label: 'Trend $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight sparkline for score trajectory — no external chart package.
class _ScoreSparkline extends StatelessWidget {
  const _ScoreSparkline({required this.scores});

  final List<double> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.length < 2) {
      return const EmptyMiniCard(text: 'Not enough data for trajectory.');
    }
    return CustomPaint(
      painter: _SparklinePainter(
        scores: scores,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.scores, required this.isDark});

  final List<double> scores;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2 || size.width <= 0 || size.height <= 0) return;
    final minScore = 0.0;
    final maxScore = 100.0;
    final range = (maxScore - minScore).clamp(1, 100);
    final stepX = size.width / (scores.length - 1);
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final x = stepX * i;
      final normalized = ((scores[i] - minScore) / range).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Smooth cubic
        final prev = points[i - 1];
        final c1 = Offset(prev.dx + stepX * 0.3, prev.dy);
        final c2 = Offset(x - stepX * 0.3, y);
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, x, y);
      }
    }
    // Gradient fill under line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primaryBright
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = AppColors.primaryBright;
    final dotBorder = Paint()
      ..color = isDark ? AppColors.surface : AppLightColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotBorder);
      canvas.drawCircle(p, 2.2, dotPaint);
    }

    // Zero line subtle
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.scores != scores || old.isDark != isDark;
}

/// Simple accuracy bar chart — only when it improves understanding.
/// Each bar carries its real score (% label) and attempt date; color bands
/// mirror the mastery language (strong/developing/starting), always paired
/// with the numeric label so state is never color-only.
class AccuracyBars extends StatelessWidget {
  const AccuracyBars({super.key, required this.quizzes});

  final List<RecentQuizRun> quizzes;

  Color _band(double score) => score >= 80
      ? AppColors.success
      : score >= 50
      ? AppColors.warning
      : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final items = quizzes.take(10).toList();
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final q in items)
                Expanded(
                  child: Semantics(
                    label:
                        '${q.topicName} score ${Formatters.percent(q.score)}',
                    child: Tooltip(
                      message:
                          '${q.topicName}: ${Formatters.percent(q.score)}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.percent(q.score),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _band(q.score),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final h =
                                      (q.score / 100).clamp(0.12, 1.0) *
                                      constraints.maxHeight;
                                  final band = _band(q.score);
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          5,
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            band.withValues(alpha: 0.95),
                                            band.withValues(alpha: 0.45),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: band.withValues(alpha: 0.5),
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (final q in items)
              Expanded(
                child: Text(
                  Formatters.shortDate(q.submittedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
