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
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart' show PressableScale;
import '../../../shared/widgets/recommendation_card.dart' show DifficultyPill;
import '../../../shared/widgets/xp_bar.dart';

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

/// Player statistics screen in Comic Neo-Brutalism theme.
/// Displays ONLY 4 primary sections:
/// 1. Your Progress (Hero band)
/// 2. Overall Mastery (Mastery Core)
/// 3. Topic Mastery (Filtered topics with progress radar)
/// 4. Learn Streak (Interactive streak tracker & weekday streak bubbles)
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
      appBar: AppBar(
        title: const Text(
          'PLAYER STATS',
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
            final (profile, summary, streak, topics, _) = snap.data!;
            // Filtered view — presentational only.
            final filtered = topics.where((t) => _filter.matches(t)).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. YOUR PROGRESS
                          _YourProgressHero(
                            summary: summary,
                            streak: streak,
                          ),
                          const SizedBox(height: 18),

                          // 2. OVERALL MASTERY
                          _MasteryCore(
                            mastery: profile.overallMastery,
                            topicCount: topics.length,
                          ),
                          const SizedBox(height: 18),

                          // 3. TOPIC MASTERY
                          const NeonSectionHeader(
                            icon: Icons.radar_rounded,
                            title: 'Topic mastery',
                            subtitle: 'Stages update as you learn',
                            accent: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
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
                          ],
                          const SizedBox(height: 18),

                          // 4. LEARN STREAK
                          const NeonSectionHeader(
                            icon: Icons.local_fire_department_rounded,
                            title: 'Learn streak',
                            subtitle: 'Consistency builds true skill',
                            accent: AppColors.streak,
                          ),
                          const SizedBox(height: 12),
                          _LearnStreakCard(streak: streak),
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

/// ── 1. YOUR PROGRESS HERO ───────────────────────────────────────────────────
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
  static const Color _brightBlue = Color(0xFF3B82F6);
  static const Color _cyan = Color(0xFF22D3EE);

  static const Color _yellow = Color(0xFFFFD43B);
  static const Color _red = Color(0xFFEF4444);

  static const Color _cream = Color(0xFFFFF8E7);
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
                    Text(
                      'YOUR PROGRESS',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        height: 0.95,
                        color: _white,

                        // Strong comic outline
                        shadows: const [
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

                    Text(
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

              _ComicQuote(
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
          style: TextStyle(
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
            Text(
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
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 0.9,
                color: _white,
                shadows: const [
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
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: _yellow,
                shadows: const [
                  Shadow(
                    color: _ink,
                    offset: Offset(1.5, 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            Expanded(
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
              style: TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: _white,
              ),
            ),

            Text(
              '$totalXp XP',
              style: TextStyle(
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
                  style: TextStyle(
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
                  style: TextStyle(
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

                              Text(
                                'MASTERY',

                                style: const TextStyle(
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
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected == f
                      ? NeoBrutalColors.ink
                      : (isDark
                          ? AppColors.textSecondary
                          : NeoBrutalColors.inkSecondary),
                ),
                selectedColor: isDark
                    ? AppColors.primary
                    : NeoBrutalColors.lemonYellow,
                backgroundColor: isDark ? AppColors.surfaceHigh : Colors.white,
                checkmarkColor: NeoBrutalColors.ink,
                side: BorderSide(
                  color: isDark ? AppColors.border : NeoBrutalColors.ink,
                  width: isDark ? 1.0 : 2.0,
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

/// ── 3. TOPIC MASTERY CARD ──────────────────────────────────────────────────
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? tint.withValues(alpha: 0.35) : NeoBrutalColors.ink,
            width: isDark ? 1.0 : 2.0,
          ),
          boxShadow: isDark ? null : NeoBrutalShadows.hardSm,
        ),
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
                    color: isDark
                        ? tint.withValues(alpha: 0.15)
                        : const Color(0xFFE0E7FF),
                    border: Border.all(
                      color: isDark
                          ? tint.withValues(alpha: 0.5)
                          : NeoBrutalColors.ink,
                      width: isDark ? 1.0 : 1.5,
                    ),
                  ),
                  child: Icon(
                    levelIcon,
                    size: 16,
                    color: isDark ? tint : const Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.topicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textPrimary
                              : NeoBrutalColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
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
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 9,
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
                      fontWeight: FontWeight.w800,
                      color: tint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Animated progress bar with neo-brutal styling
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceHigh : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? AppColors.border : NeoBrutalColors.ink,
                  width: isDark ? 0.8 : 1.2,
                ),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: (topic.masteryScore / 100).clamp(0.0, 1.0),
                ),
                duration: AppMotion.durFor(context, AppMotion.feature),
                curve: AppMotion.easeOut,
                builder: (context, val, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: val,
                  child: Container(
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
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
                      fontFamily: AppTypography.bodyFamily,
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

/// ── 4. LEARN STREAK CARD ───────────────────────────────────────────────────
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
                    Column(
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
                            Text(
                              currentStreak == 1 ? 'DAY STREAK' : 'DAYS STREAK',
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
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentStreak > 0
                              ? 'Keep learning daily!'
                              : 'Start your streak today!',
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
          color: isDark ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? color.withValues(alpha: 0.45) : NeoBrutalColors.ink,
            width: isDark ? 1.0 : 2.0,
          ),
          boxShadow: isDark ? null : NeoBrutalShadows.hardXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isDark ? color : NeoBrutalColors.ink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? color : NeoBrutalColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              fontFamily: AppTypography.bodyFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
