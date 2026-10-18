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
import '../../../core/theme/neo_brutalism.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/adaptive_next_action.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/recommendation_card.dart'
    show SectionHeader, DifficultyPill;
import '../../../shared/widgets/stat_card.dart';
import '../../shell/shell_dock_insets.dart';

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
                    // Shell dock clearance: derived (ShellDockMetrics).
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        8,
                        horizontalPad,
                        ShellDockMetrics.bottomClearance(context),
                      ),
                      child: Column(
                        children: [
                          // 1. YOUR PROGRESS — comic hero (port from
                          // reference): level band, XP bar, identity chips.
                          // Same backend reads as the cards below.
                          _YourProgressHero(
                            summary: summary,
                            streak: streak,
                          ),
                          const SizedBox(height: 18),
                          // At-a-glance numbers live in the hero band above
                          // (LevelBadge + XPBar + streak/badge chips) with
                          // detail in Consistency/Achievements below — no
                          // duplicated stat grid.
                          const SizedBox(height: 18),

                          // Overall mastery — Mastery Core: tiered ring + tier
                          // chip derived from the same 80/60/40 cutoffs as
                          // AdaptiveEngine. Real overallMastery only.
                          _MasteryCore(
                            mastery: profile.overallMastery,
                            topicCount: topics.length,
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
                                          if (quizzes.length >= 2) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _accuracyTrendLine(quizzes),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                height: 1.35,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors
                                                          .textSecondary
                                                    : AppLightColors
                                                          .textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GameChip(
                                      label: 'VIEW',
                                      icon: Icons.chevron_right_rounded,
                                      color: AppColors.warning,
                                      onTap: () => context.push(
                                        Routes.topicPerformance(
                                            focus!.topicId),
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
                                  height: 196,
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
                                      height: 120,
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
                                          // Latest-value + honest delta badges
                                          // (reference: glowing % pill at the
                                          // line end). Same backend reads as
                                          // the axis labels below — no new
                                          // data.
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Semantics(
                                              label:
                                                  'Latest score ${Formatters.percent(quizzes.first.score)}, change ${_trajectoryDeltaLabel(quizzes)} points vs previous',
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _trajectoryDeltaColor(
                                                              quizzes)
                                                          .withValues(
                                                              alpha: 0.14),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        999,
                                                      ),
                                                      border: Border.all(
                                                        color:
                                                            _trajectoryDeltaColor(
                                                                    quizzes)
                                                                .withValues(
                                                                    alpha:
                                                                        0.45),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _trajectoryDeltaLabel(
                                                          quizzes),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            _trajectoryDeltaColor(
                                                                quizzes),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary
                                                          .withValues(
                                                              alpha: 0.9),
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
                                                ],
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

                          // —— LEARN STREAK (reference section 4)
                          const SizedBox(height: 18),
                          const NeonSectionHeader(
                            icon: Icons.local_fire_department_rounded,
                            title: 'Learn streak',
                            subtitle: 'Consistency builds true skill',
                            accent: AppColors.streak,
                          ),
                          const SizedBox(height: 12),
                          _LearnStreakCard(streak: streak),

                          // —— MASTERY DISTRIBUTION (A8)
                          const SizedBox(height: 18),
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
                                child: const Row(children: [Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary), SizedBox(width: 8), Expanded(child: Text('Historical trend requires 3+ completed activities. Your current view shows the latest available state.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)))]),
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

class _YourProgressHero extends StatelessWidget {
  const _YourProgressHero({
    required this.summary,
    required this.streak,
  });

  final GamificationSummary summary;
  final StreakState streak;

  // ------------------------------------------------------------
  // GAMELEARN AI - COMIC / NEO-BRUTALIST COLORS
  // ------------------------------------------------------------

  static const Color _blue = Color(0xFF2563EB);

  static const Color _yellow = Color(0xFFFFD43B);
  static const Color _red = Color(0xFFEF4444);

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _blue,

        // Thick comic outline
        border: Border.all(
          color: _ink,
          width: 3.5,
        ),

        borderRadius: BorderRadius.circular(28),

        // Hard neo-brutalist shadow
        boxShadow: const [
          BoxShadow(
            color: _ink,
            blurRadius: 0,
            offset: Offset(6, 7),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // YOUR PROGRESS
                    const Text(
                      'YOUR PROGRESS',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        height: 0.95,
                        color: _white,

                        // Strong comic outline
                        shadows: [
                          Shadow(
                            color: _ink,
                            offset: Offset(2, 2),
                          ),
                          Shadow(
                            color: _ink,
                            offset: Offset(-1, 1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Track your progress. See your growth.',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: _white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Comic underline
                    Container(
                      width: 105,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // =================================================
              // COMIC QUOTE
              // =================================================

              const _ComicQuote(
                text: 'PROGRESS\nTURNS EFFORT\nINTO MASTERY',
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =====================================================
          // LEVEL + XP
          // =====================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                label:
                    'Level ${summary.currentLevel}, ${Formatters.count(summary.totalXp)} XP',
                child: _ComicLevelBadge(
                  level: summary.currentLevel,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: _ComicXPSection(
                  currentLevel: summary.currentLevel,
                  totalXp: summary.totalXp,
                  xpToNextLevel: summary.xpToNextLevel ?? 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =====================================================
          // STATS
          // =====================================================

          Row(
            children: [
              Expanded(
                child: _ComicStatChip(
                  icon: Icons.local_fire_department_rounded,
                  value: '${streak.currentStreakDays}',
                  label: 'DAY STREAK',
                  color: _red,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _ComicStatChip(
                  icon: Icons.emoji_events_rounded,
                  value: '${summary.unlockedAchievements}',
                  label: 'BADGES',
                  color: _yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// COMIC QUOTE
// ============================================================================

class _ComicQuote extends StatelessWidget {
  const _ComicQuote({
    required this.text,
  });

  final String text;

  static const Color _yellow = Color(0xFFFFD43B);
  static const Color _ink = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.025,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 125,
        ),
        padding: const EdgeInsets.fromLTRB(
          10,
          9,
          10,
          9,
        ),
        decoration: BoxDecoration(
          color: _yellow,

          border: Border.all(
            color: _ink,
            width: 2.5,
          ),

          borderRadius: BorderRadius.circular(8),

          boxShadow: const [
            BoxShadow(
              color: _ink,
              blurRadius: 0,
              offset: Offset(3, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: 0.4,
            color: _ink,
          ),
        ),
      ),
    );
  }
}


// ============================================================================
// COMIC LEVEL BADGE
// ============================================================================

class _ComicLevelBadge extends StatelessWidget {
  const _ComicLevelBadge({
    required this.level,
  });

  final int level;

  static const Color _blue = Color(0xFF3B82F6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _blue,

        border: Border.all(
          color: _ink,
          width: 3,
        ),

        boxShadow: const [
          BoxShadow(
            color: _ink,
            blurRadius: 0,
            offset: Offset(3, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _blue,
          border: Border.all(
            color: _cyan,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LEVEL',
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: _white,
              ),
            ),

            const SizedBox(height: 1),

            Text(
              '$level',
              style: const TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 0.9,
                color: _white,
                shadows: [
                  Shadow(
                    color: _ink,
                    offset: Offset(1.5, 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// COMIC XP SECTION
// ============================================================================

class _ComicXPSection extends StatelessWidget {
  const _ComicXPSection({
    required this.currentLevel,
    required this.totalXp,
    required this.xpToNextLevel,
  });

  final int currentLevel;
  final int totalXp;
  final int xpToNextLevel;

  static const Color _yellow = Color(0xFFFFD43B);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    // Calculate a safe visual progress value.
    //
    // We keep the existing XP data untouched.
    // This only controls how much of the bar is filled.
    final int safeNextXp = xpToNextLevel <= 0 ? 1 : xpToNextLevel;

    final double progress =
        (totalXp / safeNextXp).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =========================================================
        // XP LABEL
        // =========================================================

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$xpToNextLevel XP',
              style: const TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: _yellow,
                shadows: [
                  Shadow(
                    color: _ink,
                    offset: Offset(1.5, 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            const Expanded(
              child: Text(
                'TO NEXT LEVEL',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: _white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        // =========================================================
        // XP BAR
        // =========================================================

        Container(
          height: 19,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _ink,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _yellow,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 5),

        // =========================================================
        // XP VALUES
        // =========================================================

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${totalXp - xpToNextLevel > 0 ? totalXp - xpToNextLevel : 0} XP',
              style: const TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: _white,
              ),
            ),

            Text(
              '$totalXp XP',
              style: const TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: _white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


// ============================================================================
// COMIC STAT CHIP
// ============================================================================

class _ComicStatChip extends StatelessWidget {
  const _ComicStatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 67,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _white,

        border: Border.all(
          color: _ink,
          width: 2.5,
        ),

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // =======================================================
          // ICON
          // =======================================================

          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: _ink,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 25,
              color: _ink,
            ),
          ),

          const SizedBox(width: 8),

          // =======================================================
          // VALUE + LABEL
          // =======================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                    color: _ink,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
/// ── 2. OVERALL MASTERY ──────────────────────────────────────────────────────

class _LearnStreakCard extends StatefulWidget {
  const _LearnStreakCard({required this.streak});

  final StreakState streak;

  @override
  State<_LearnStreakCard> createState() => _LearnStreakCardState();
}

class _LearnStreakCardState extends State<_LearnStreakCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  bool _tapped = false;
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.streak.currentStreakDays > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onCardTap() {
    setState(() {
      _tapped = !_tapped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStreak = widget.streak.currentStreakDays;
    final longestStreak = widget.streak.longestStreakDays;
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // In a 7-day week, compute which days are active based on currentStreak
    final activeDaysCount = currentStreak.clamp(0, 7);

    return PressableScale(
      onTap: _onCardTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark
                ? AppColors.streak.withValues(alpha: 0.45)
                : NeoBrutalColors.ink,
            width: isDark ? 1.5 : 2.5,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: AppColors.streak.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : NeoBrutalShadows.hard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Flame Icon + Streak numbers + Best streak badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.streak.withValues(alpha: 0.18)
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? AppColors.streak : NeoBrutalColors.ink,
                            width: isDark ? 1.5 : 2.5,
                          ),
                          boxShadow: isDark ? null : NeoBrutalShadows.hardXs,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            size: 26,
                            color: currentStreak > 0
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$currentStreak',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : NeoBrutalColors.ink,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  currentStreak == 1
                                      ? 'DAY STREAK'
                                      : 'DAYS STREAK',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: currentStreak > 0
                                        ? const Color(0xFFF59E0B)
                                        : (isDark
                                            ? AppColors.textTertiary
                                            : NeoBrutalColors.inkSecondary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentStreak > 0
                                ? 'Keep learning daily!'
                                : 'Start your streak today!',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFamily,
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : NeoBrutalColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Best Streak Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceHigh
                        : NeoBrutalColors.pastelYellow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? AppColors.border : NeoBrutalColors.ink,
                      width: isDark ? 1.0 : 1.5,
                    ),
                    boxShadow: isDark ? null : NeoBrutalShadows.hardXs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 13,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'BEST: $longestStreak',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.textPrimary
                              : NeoBrutalColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7-Day Interactive Weekday Tracker
            Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final isActive = i < activeDaysCount;
                        final isSelected = _selectedDayIndex == i;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDayIndex =
                                  _selectedDayIndex == i ? null : i;
                            });
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? (isDark
                                            ? AppColors.streak
                                            : NeoBrutalColors.lemonYellow)
                                        : (isDark
                                            ? AppColors.surfaceHigh
                                            : const Color(0xFFF3F4F6)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isActive
                                          ? NeoBrutalColors.ink
                                          : (isDark
                                              ? AppColors.border
                                              : const Color(0xFFD1D5DB)),
                                      width: isActive ? 1.8 : 1.2,
                                    ),
                                    boxShadow: isActive && !isDark
                                        ? NeoBrutalShadows.hardXs
                                        : null,
                                  ),
                                  child: Center(
                                    child: isActive
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 15,
                                            color: NeoBrutalColors.ink,
                                          )
                                        : Text(
                                            weekdays[i],
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTypography.displayFamily,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.textTertiary
                                                  : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  weekdayNames[i],
                                  style: TextStyle(
                                    fontFamily: AppTypography.bodyFamily,
                                    fontSize: 9,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? (isDark
                                            ? AppColors.textPrimary
                                            : NeoBrutalColors.ink)
                                        : (isDark
                                            ? AppColors.textTertiary
                                            : const Color(0xFF9CA3AF)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Motivational Banner / Feedback
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceHigh
                    : (currentStreak > 0
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark
                      ? AppColors.border
                      : (currentStreak > 0
                          ? NeoBrutalColors.ink
                          : const Color(0xFFD1D5DB)),
                  width: isDark ? 1.0 : 1.5,
                ),
                boxShadow: !isDark && currentStreak > 0
                    ? NeoBrutalShadows.hardXs
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    currentStreak > 0
                        ? Icons.local_fire_department_rounded
                        : Icons.explore_rounded,
                    size: 16,
                    color: currentStreak > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentStreak > 0
                          ? '🔥 You\'re on fire! Keep learning today to maintain your streak!'
                          : 'Complete a few missions to build your learning streak!',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimary
                            : (currentStreak > 0
                                ? NeoBrutalColors.ink
                                : NeoBrutalColors.inkSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── HELPER CHIP & INDICATOR ────────────────────────────────────────────────
class _MasteryCore extends StatefulWidget {
  const _MasteryCore({
    required this.mastery,
    required this.topicCount,
  });

  /// Backend-provided overall mastery (0–100). Never fabricated.
  final double mastery;

  /// Backend-provided count of tracked topics for the subtitle.
  final int topicCount;

  @override
  State<_MasteryCore> createState() => _MasteryCoreState();
}

class _MasteryCoreState extends State<_MasteryCore> {
  bool _tapped = false;

  (String label, Color tint) _tier() {
    if (widget.mastery >= AdaptiveEngine.masteredThreshold) {
      return (
        'MASTERED',
        const Color(0xFF10B981),
      );
    }

    if (widget.mastery >= AdaptiveEngine.proficientThreshold) {
      return (
        'PROFICIENT',
        AppColors.primary,
      );
    }

    if (widget.mastery >= AdaptiveEngine.developingThreshold) {
      return (
        'DEVELOPING',
        AppColors.warning,
      );
    }

    return (
      'NEEDS PRACTICE',
      AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (tierLabel, tint) = _tier();

    final needsPractice =
        !isDark && widget.mastery < 50;

    // ==========================================================
    // COMIC / NEO-BRUTALIST COLORS
    // ==========================================================

    const ink = Color(0xFF171717);
    const white = Color(0xFFFFFFFF);

    const blue = Color(0xFF2563EB);
    const yellow = Color(0xFFFFD43B);

    const green = Color(0xFF10B981);
    const red = Color(0xFFEF4444);
    const orange = Color(0xFFF97316);

    final Color mainColor = needsPractice
        ? red
        : blue;

    final Color activeColor = widget.mastery >=
            AdaptiveEngine.masteredThreshold
        ? green
        : widget.mastery >=
                AdaptiveEngine.proficientThreshold
            ? blue
            : widget.mastery >=
                    AdaptiveEngine.developingThreshold
                ? orange
                : red;

    return Semantics(
      label:
          'Overall mastery ${Formatters.percent(widget.mastery)}, tier $tierLabel',

      child: PressableScale(
        onTap: () {
          setState(() {
            _tapped = !_tapped;
          });
        },

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            // ==================================================
            // MAIN CARD
            // ==================================================

            color: isDark
                ? Theme.of(context).cardTheme.color
                : mainColor,

            borderRadius: BorderRadius.circular(28),

            border: Border.all(
              color: isDark
                  ? activeColor.withValues(alpha: 0.7)
                  : ink,
              width: isDark ? 1.5 : 3.5,
            ),

            // Hard comic shadow instead of soft glow
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: activeColor.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: ink,
                      blurRadius: 0,
                      offset: Offset(6, 7),
                    ),
                  ],
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // =================================================
              // HEADER
              // =================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,

                children: [
                  // ---------------------------------------------
                  // RADAR ICON
                  // ---------------------------------------------

                  Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: white,

                      border: Border.all(
                        color: ink,
                        width: 2.5,
                      ),

                      borderRadius:
                          BorderRadius.circular(12),

                      boxShadow: const [
                        BoxShadow(
                          color: ink,
                          blurRadius: 0,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),

                    child: Icon(
                      Icons.radar_rounded,
                      size: 24,
                      color: mainColor,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ---------------------------------------------
                  // TITLE
                  // ---------------------------------------------

                  Expanded(
                    child: Text(
                      'OVERALL MASTERY',

                      style: TextStyle(
                        fontFamily:
                            AppTypography.displayFamily,

                        fontSize: 18,

                        fontWeight:
                            FontWeight.w900,

                        letterSpacing: 1.0,

                        height: 1,

                        color: isDark
                            ? Colors.white
                            : white,

                        shadows: const [
                          Shadow(
                            color: ink,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ---------------------------------------------
                  // TRACKED BADGE
                  // ---------------------------------------------

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: yellow,

                      border: Border.all(
                        color: ink,
                        width: 2.5,
                      ),

                      borderRadius:
                          BorderRadius.circular(999),

                      boxShadow: const [
                        BoxShadow(
                          color: ink,
                          blurRadius: 0,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),

                    child: Text(
                      '${widget.topicCount} TRACKED',

                      style: const TextStyle(
                        fontFamily:
                            AppTypography.displayFamily,

                        fontSize: 9,

                        fontWeight:
                            FontWeight.w900,

                        letterSpacing: 0.6,

                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // =================================================
              // MASTERY + TIER
              // =================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,

                children: [
                  // =============================================
                  // MASTERY CIRCLE
                  // =============================================

                  AnimatedScale(
                    scale: _tapped ? 1.08 : 1.0,

                    duration:
                        const Duration(
                      milliseconds: 200,
                    ),

                    child: Container(
                      width: 128,
                      height: 128,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: white,

                        border: Border.all(
                          color: ink,
                          width: 3.5,
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color: ink,
                            blurRadius: 0,
                            offset: Offset(5, 6),
                          ),
                        ],
                      ),

                      child: Stack(
                        alignment:
                            Alignment.center,

                        children: [
                          // -------------------------------------
                          // PROGRESS RING
                          // -------------------------------------

                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end:
                                  widget.mastery / 100,
                            ),

                            duration:
                                AppMotion.durFor(
                              context,
                              AppMotion.celebration,
                            ),

                            curve:
                                AppMotion.easeOut,

                            builder:
                                (
                              context,
                              v,
                              _,
                            ) {
                              return SizedBox(
                                width: 108,
                                height: 108,

                                child:
                                    CircularProgressIndicator(
                                  value:
                                      v.clamp(
                                    0.0,
                                    1.0,
                                  ),

                                  strokeWidth: 10,

                                  strokeCap:
                                      StrokeCap.round,

                                  color: mainColor,

                                  backgroundColor:
                                      const Color(
                                    0xFFE5E7EB,
                                  ),
                                ),
                              );
                            },
                          ),

                          // -------------------------------------
                          // PERCENTAGE
                          // -------------------------------------

                          Column(
                            mainAxisSize:
                                MainAxisSize.min,

                            children: [
                              Text(
                                Formatters.percent(
                                  widget.mastery,
                                ),

                                style: const TextStyle(
                                  fontFamily:
                                      AppTypography
                                          .displayFamily,

                                  fontSize: 27,

                                  fontWeight:
                                      FontWeight.w900,

                                  height: 0.95,

                                  color: ink,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              const Text(
                                'MASTERY',

                                style: TextStyle(
                                  fontFamily:
                                      AppTypography
                                          .displayFamily,

                                  fontSize: 9,

                                  fontWeight:
                                      FontWeight.w900,

                                  letterSpacing: 1.8,

                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 18),

                  // =============================================
                  // TIER INFORMATION
                  // =============================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        // ---------------------------------------
                        // TIER BADGE
                        // ---------------------------------------

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),

                          decoration: BoxDecoration(
                            color: white,

                            border: Border.all(
                              color: ink,
                              width: 2.5,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              11,
                            ),

                            boxShadow: const [
                              BoxShadow(
                                color: ink,
                                blurRadius: 0,
                                offset: Offset(3, 4),
                              ),
                            ],
                          ),

                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,

                            children: [
                              Icon(
                                Icons
                                    .bar_chart_rounded,

                                size: 22,

                                color: activeColor,
                              ),

                              const SizedBox(
                                width: 7,
                              ),

                              Flexible(
                                child: Text(
                                  '$tierLabel TIER',

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    fontFamily:
                                        AppTypography
                                            .displayFamily,

                                    fontSize: 11,

                                    fontWeight:
                                        FontWeight.w900,

                                    letterSpacing:
                                        0.7,

                                    color: ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ---------------------------------------
                        // MAIN MESSAGE
                        // ---------------------------------------

                        Text(
                          needsPractice
                              ? 'KEEP TRAINING.'
                              : 'KEEP BUILDING.',

                          style: const TextStyle(
                            fontFamily:
                                AppTypography
                                    .displayFamily,

                            fontSize: 21,

                            fontWeight:
                                FontWeight.w900,

                            height: 0.95,

                            letterSpacing: 0.4,

                            color: white,

                            shadows: [
                              Shadow(
                                color: ink,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          'Across every assessed topic.',

                          style: TextStyle(
                            fontFamily:
                                AppTypography
                                    .bodyFamily,

                            fontSize: 12,

                            fontWeight:
                                FontWeight.w700,

                            height: 1.3,

                            color: isDark
                                ? AppColors
                                    .textSecondary
                                : white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // =================================================
              // BOTTOM STATUS CARD
              // =================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),

                decoration: BoxDecoration(
                  color: white,

                  border: Border.all(
                    color: ink,
                    width: 2.5,
                  ),

                  borderRadius:
                      BorderRadius.circular(15),

                  boxShadow: const [
                    BoxShadow(
                      color: ink,
                      blurRadius: 0,
                      offset: Offset(3, 4),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    // -------------------------------------------
                    // STATUS ICON
                    // -------------------------------------------

                    Container(
                      width: 43,
                      height: 43,

                      decoration: BoxDecoration(
                        color: needsPractice
                            ? red
                            : green,

                        border: Border.all(
                          color: ink,
                          width: 2,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          11,
                        ),
                      ),

                      child: Icon(
                        needsPractice
                            ? Icons
                                .local_fire_department_rounded
                            : Icons.check_rounded,

                        size: 25,

                        color: white,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // -------------------------------------------
                    // STATUS TEXT
                    // -------------------------------------------

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            needsPractice
                                ? 'KEEP GOING!'
                                : 'GREAT WORK!',

                            style: const TextStyle(
                              fontFamily:
                                  AppTypography
                                      .displayFamily,

                              fontSize: 15,

                              fontWeight:
                                  FontWeight.w900,

                              letterSpacing: 0.5,

                              color: ink,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            needsPractice
                                ? 'Complete challenges to improve your mastery.'
                                : 'Keep completing challenges to improve your mastery.',

                            maxLines: 2,

                            overflow:
                                TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontFamily:
                                  AppTypography
                                      .bodyFamily,

                              fontSize: 10.5,

                              fontWeight:
                                  FontWeight.w700,

                              height: 1.25,

                              color: Color(
                                0xFF374151,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // -------------------------------------------
                    // ARROW
                    // -------------------------------------------

                    Container(
                      width: 40,
                      height: 40,

                      decoration:
                          const BoxDecoration(
                        color: yellow,

                        shape: BoxShape.circle,

                        border:
                            Border.fromBorderSide(
                          BorderSide(
                            color: ink,
                            width: 2.5,
                          ),
                        ),
                      ),

                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 21,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// ── 3. TOPIC MASTERY FILTER CHIPS ──────────────────────────────────────────
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
      return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionHeader(title: 'Mastery distribution'), SizedBox(height: 8), EmptyMiniCard(text: 'Complete more learning activities to unlock deeper mastery insights.')]);
    }
    final segments = [
      (mastered, 'Mastered', AppColors.xp),
      (proficient, 'Strong', AppColors.success),
      (developing, 'Developing', AppColors.warning),
      (beginner, 'Needs Practice', AppColors.error),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Mastery distribution'),
      const SizedBox(height: 8),
      GameCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label:
                  'Mastery distribution across $total topics: $mastered mastered, $proficient strong, $developing developing, $beginner needs practice',
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppMotion.durFor(context, AppMotion.feature),
                curve: AppMotion.easeOut,
                builder: (context, t, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        for (final (count, _, color) in segments)
                          if (count > 0)
                            Expanded(
                              flex: count,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: t.clamp(0.0, 1.0),
                                child: Container(color: color),
                              ),
                            ),
                        if (segments.every((s) => s.$1 == 0))
                          Expanded(
                            child: Container(
                              color: isDark
                                  ? AppColors.surfaceHigh
                                  : AppLightColors.surfaceHigh,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final (count, label, color) in segments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: color.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '$count of $total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
      return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionHeader(title: 'Game performance'), SizedBox(height: 8), EmptyMiniCard(text: 'No game activity yet. Play a game to see your performance.')]);
    }
    // Show recent quiz performance as proxy for game performance (real data only)
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Game performance'),
      const SizedBox(height: 8),
      for (final q in quizzes.take(5))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PressableScale(
            onTap: () => context.push(Routes.topicPerformance(q.topicId)),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: (q.score >= 80
                          ? AppColors.success
                          : q.score >= 50
                              ? AppColors.warning
                              : AppColors.error)
                      .withValues(alpha: 0.30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: (q.score >= 80 ? AppColors.success : q.score >= 50 ? AppColors.warning : AppColors.error).withValues(alpha: 0.14)), child: Icon(q.score >= 80 ? Icons.emoji_events_rounded : q.score >= 50 ? Icons.trending_up_rounded : Icons.flag_rounded, size: 16, color: q.score >= 80 ? AppColors.success : q.score >= 50 ? AppColors.warning : AppColors.error)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(q.topicName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)), Text('${Formatters.percent(q.score)} • ${q.correctCount}/${q.totalQuestions} correct • ${Formatters.shortDate(q.submittedAt)}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))])),
                    const SizedBox(width: 8),
                    MasteryBadge(score: q.score),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (q.score / 100).clamp(0, 1),
                      minHeight: 6,
                      color: q.score >= 80
                          ? AppColors.success
                          : q.score >= 50
                              ? AppColors.warning
                              : AppColors.error,
                      backgroundColor: isDark
                          ? AppColors.surfaceHigh
                          : AppLightColors.surfaceHigh,
                      semanticsLabel:
                          '${q.topicName} accuracy ${Formatters.percent(q.score)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary), const SizedBox(width: 8), Expanded(child: Text('Unplayed games remain clearly unplayed — complete more games to populate this view.', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)))])),
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
          GameChip(label: 'VIEW', icon: Icons.emoji_events_rounded, color: AppColors.xp, onTap: () => context.go(Routes.achievements)),
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
        PrimaryGameButton(
          label: 'Ask tutor',
          icon: Icons.psychology_rounded,
          color: AppColors.secondary,
          expanded: false,
          onTap: () => context.push(focusTopic != null ? Routes.tutorWithContext(topicId: focusTopic!.topicId, topicName: focusTopic!.topicName, focus: focusTopic!.topicName) : Routes.tutor),
        ),
        SecondaryGameButton(
          label: 'Learning path',
          icon: Icons.school_rounded,
          expanded: false,
          onTap: () => context.go(Routes.subjects),
        ),
        SecondaryGameButton(
          label: 'Leaderboard',
          icon: Icons.leaderboard_rounded,
          expanded: false,
          onTap: () => context.go(Routes.arena),
        ),
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
    return PressableScale(
      onTap: () => context.push(Routes.topicPerformance(topic.topicId)),
      child: GameCard(
        borderColor: tint.withValues(alpha: 0.35),
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

/// Honest accuracy-trend sentence from the real quiz series (latest
/// first). Pure presentation of backend reads — no insight invention.
String _accuracyTrendLine(List<RecentQuizRun> quizzes) {
  if (quizzes.length < 2) return 'Complete more missions to reveal your trend.';
  final latest = quizzes.first.score;
  final previous = quizzes[1].score;
  final direction = latest > previous
      ? 'improving'
      : latest < previous
          ? 'declining'
          : 'steady';
  return 'Recent accuracy is $direction — latest ${Formatters.percent(latest)} vs previous ${Formatters.percent(previous)}.';
}

/// Honest latest-vs-previous delta from the real quiz series (latest
/// first). Pure presentation of backend reads — no trend invention.
String _trajectoryDeltaLabel(List<RecentQuizRun> quizzes) {
  if (quizzes.length < 2) return '±0';
  final delta = quizzes.first.score - quizzes[1].score;
  return '${delta >= 0 ? '+' : ''}${delta.round()}';
}

Color _trajectoryDeltaColor(List<RecentQuizRun> quizzes) {
  if (quizzes.length < 2) return AppColors.textTertiary;
  final delta = quizzes.first.score - quizzes[1].score;
  if (delta > 0) return AppColors.success;
  if (delta < 0) return AppColors.error;
  return AppColors.textTertiary;
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

    // Dots + glowing latest point (restrained: one glow, dark only).
    final dotPaint = Paint()..color = AppColors.primaryBright;
    final dotBorder = Paint()
      ..color = isDark ? AppColors.surface : AppLightColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (i == points.length - 1 && isDark) {
        canvas.drawCircle(
          p,
          7,
          Paint()
            ..color = AppColors.primaryBright.withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawCircle(p, 3, dotBorder);
      canvas.drawCircle(p, 2.2, dotPaint);
    }

    // Cinematic grid — truthful 0–100 scale markers, never decoration-only:
    // they anchor the trajectory readout.
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final frac in const [0.25, 0.5, 0.75]) {
      final y = size.height * (1 - frac);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
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

/// Premium accuracy visualization — truthful 0–100 bars with the latest
/// attempt highlighted (glow + delta vs previous). Every value is the
/// real backend score; bands mirror the mastery language and every bar
/// carries its numeric label so state is never color-only.
class AccuracyBars extends StatelessWidget {
  const AccuracyBars({super.key, required this.quizzes});

  /// Chronological (oldest → latest). Must contain 2+ items.
  final List<RecentQuizRun> quizzes;

  Color _band(double score) => score >= 80
      ? AppColors.success
      : score >= 50
      ? AppColors.warning
      : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = quizzes.take(10).toList();
    final latest = items.last;
    final previous = items.length >= 2 ? items[items.length - 2] : null;
    final delta = previous == null ? null : latest.score - previous.score;
    final deltaLabel = delta == null
        ? null
        : '${delta >= 0 ? '+' : ''}${delta.round()} vs prev';
    final deltaColor = delta == null
        ? AppColors.textTertiary
        : delta > 0
            ? AppColors.success
            : delta < 0
                ? AppColors.error
                : AppColors.textTertiary;
    return Column(
      children: [
        Row(
          children: [
            Semantics(
              label:
                  'Latest accuracy ${Formatters.percent(latest.score)} on ${latest.topicName}',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _band(latest.score).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: _band(latest.score).withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  'LATEST ${Formatters.percent(latest.score)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _band(latest.score),
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (deltaLabel != null)
              Text(
                deltaLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    label:
                        '${items[i].topicName} score ${Formatters.percent(items[i].score)}',
                    child: Tooltip(
                      message:
                          '${items[i].topicName}: ${Formatters.percent(items[i].score)}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.percent(items[i].score),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _band(items[i].score),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final h =
                                      (items[i].score / 100).clamp(0.12, 1.0) *
                                      constraints.maxHeight;
                                  final band = _band(items[i].score);
                                  final isLatest = i == items.length - 1;
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: h),
                                      duration: AppMotion.durFor(
                                        context,
                                        AppMotion.feature,
                                      ),
                                      curve: AppMotion.easeOut,
                                      builder: (context, animatedH, _) =>
                                          Container(
                                        height: animatedH,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              band.withValues(
                                                  alpha:
                                                      isLatest ? 1.0 : 0.95),
                                              band.withValues(
                                                  alpha:
                                                      isLatest ? 0.55 : 0.45),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: band.withValues(
                                                alpha: isLatest ? 0.8 : 0.5),
                                            width: isLatest ? 1.2 : 0.8,
                                          ),
                                          boxShadow: isLatest && isDark
                                              ? AppShadows.glow(band,
                                                  alpha: 0.35)
                                              : null,
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
