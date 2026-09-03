import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/content_models.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/achievement_icon.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/recommendation_card.dart'
    show DifficultyPill, PriorityPill, RecommendationCard, SectionHeader;
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/xp_bar.dart' show XPBar;
import '../../game_engine/models/game_models.dart';
import '../providers/dashboard_provider.dart';

/// Premium command center — hierarchy mandated by UI-3:
///
/// 1. PROFILE / LEVEL / XP HERO
/// 2. CONTINUE LEARNING (prominent CTA)
/// 3. JOURNEY / PROGRESS
/// 4. SUBJECTS (real catalog)
/// 5. DAILY QUESTS (truthful)
/// 6. GAME ZONE (14 games prominent)
/// 7. ACHIEVEMENTS / STREAK
///
/// Responsive: compact single column; medium+ 2-col grids where density helps;
/// wide centered 1120 (shell constraint). Theme-aware via Theme + AppLightColors.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.dashboard);
  }

  Future<void> _refresh() async =>
      ref.read(dashboardProvider.notifier).refresh();

  void _continueAdventure(Dashboard d) {
    final subject = d.currentSubject;
    if (subject != null) {
      ref.read(hapticsProvider).tap();
      final path = d.learningPath;
      if (path != null && path.nodes.isNotEmpty) {
        for (final n in path.nodes) {
          if (n.status == 'AVAILABLE') {
            ref.read(audioManagerProvider).play(Sfx.buttonTap);
            context.push(Routes.topic(n.topicId));
            return;
          }
        }
        for (final n in path.nodes) {
          if (n.status == 'IN_PROGRESS') {
            ref.read(audioManagerProvider).play(Sfx.buttonTap);
            context.push(Routes.topic(n.topicId));
            return;
          }
        }
        if (path.nodes.every((n) => n.status == 'COMPLETED')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This world is complete! Explore another world or revisit topics.',
              ),
            ),
          );
        }
      }
      final name = Uri.encodeComponent(subject.name);
      context.go('/${Routes.path(subject.id).substring(1)}?name=$name');
      return;
    }
    context.go(Routes.subjects);
  }

  void _openRecommendation(RecommendationItem item) {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    context.push('/recommendation', extra: item);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(audioManagerProvider).play(Sfx.buttonTap);
          ref.read(hapticsProvider).tap();
          context.push(Routes.tutor);
        },
        backgroundColor: isDark ? AppColors.secondaryDeep : AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: const Text(
          'NOVA',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBright,
        backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
        onRefresh: _refresh,
        child: Builder(
          builder: (context) {
            if (state.showLoading) return const SkeletonDashboard();
            final error = state.error;
            if (error != null && state.data == null) {
              final err = describeError(error);
              return ErrorState(
                title: err.title,
                message: err.message,
                onRetry: () => ref.read(dashboardProvider.notifier).load(),
              );
            }
            final dashboard = state.data;
            if (dashboard != null) {
              return _DashboardBody(
                dashboard: dashboard,
                onContinue: () => _continueAdventure(dashboard),
                onOpenRecommendation: _openRecommendation,
              );
            }
            return const SkeletonDashboard();
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.dashboard,
    required this.onContinue,
    required this.onOpenRecommendation,
  });

  final Dashboard dashboard;
  final VoidCallback onContinue;
  final void Function(RecommendationItem) onOpenRecommendation;

  Widget _staggered(int index, Widget child) {
    return Builder(
      builder: (context) {
        final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduce) return child;
        final delayMs = (index * AppMotion.staggerUnit.inMilliseconds).clamp(
          0,
          500,
        );
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.normal + Duration(milliseconds: delayMs),
          curve: AppMotion.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - t)),
              child: child,
            ),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = dashboard;
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
    var i = 0;
    // Use SingleChildScrollView + Column so all dashboard sections are built
    // eagerly for tester finders (ListView lazily builds off-screen slivers).
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppGutters.pagePadding(context),
        12,
        AppGutters.pagePadding(context),
        110,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // 1. HERO — Profile / Level / XP / Streak (premium, theme-aware)
        _staggered(i++, _HeroCard(dashboard: d)),
        const SizedBox(height: 22),

        // 2. CONTINUE LEARNING — visually dominant CTA
        _staggered(i++, _ContinueCard(dashboard: d, onContinue: onContinue)),
        const SizedBox(height: 18),

        // 3. JOURNEY / PROGRESS (uses real learningPath nodes)
        _staggered(i++, const SectionHeader(title: 'Your journey')),
        _staggered(i++, _JourneySection(dashboard: d)),
        const SizedBox(height: 18),

        // 4. SUBJECTS — real catalog, adaptive grid
        _staggered(i++, const SectionHeader(title: 'Worlds')),
        _staggered(i++, _SubjectsSection(dashboard: d)),
        const SizedBox(height: 8),

        // Also keep existing adaptive insights where they add value, now inside journey/quests
        // Nova recommends — truthful, backend-driven
        if (d.recommendations.isNotEmpty) ...[
          _staggered(i++, const SectionHeader(title: 'Nova recommends')),
          ...d.recommendations
              .take(2)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _staggered(
                    i++,
                    RecommendationCard(
                      item: item,
                      compact: true,
                      onStart: () => onOpenRecommendation(item),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
        ],

        // Adaptive brief when rationale available
        if (_explainableRecommendation(d) != null)
          _staggered(
            i++,
            _AdaptiveFocusCard(
              dashboard: d,
              recommendation: _explainableRecommendation(d)!,
              onStart: () =>
                  onOpenRecommendation(_explainableRecommendation(d)!),
            ),
          ),
        if (_explainableRecommendation(d) != null) const SizedBox(height: 8),

        if (d.assessment.assessedSubjects.isEmpty &&
            d.mastery.topicsAssessed == 0 &&
            !d.recommendations.any((r) => r.topicId != null))
          _staggered(i++, const _AssessmentNudge()),

        if (d.mastery.recentTopics.isNotEmpty) ...[
          _staggered(i++, const SectionHeader(title: 'Mastery radar')),
          _staggered(i++, MasteryStrip(topics: d.mastery.recentTopics)),
          const SizedBox(height: 8),
        ],

        // 5. DAILY QUESTS — truthful (uses real recommendations or empty)
        _staggered(i++, const SectionHeader(title: 'Daily quests')),
        _staggered(i++, _QuestsSection(dashboard: d, onOpen: onOpenRecommendation)),
        const SizedBox(height: 18),

        // 6. GAME ZONE — prominent
        _staggered(i++, const SectionHeader(title: 'Game zone')),
        _staggered(i++, _GameZoneSection(dashboard: d)),
        const SizedBox(height: 18),

        // 7. ACHIEVEMENTS / STREAK — real data only
        if (d.achievements.recentUnlocks.isNotEmpty) ...[
          _staggered(i++, const SectionHeader(title: 'Trophy room')),
          _staggered(
            i++,
            GameCard(
              child: Row(
                children: [
                  AchievementIcon(
                    iconKey:
                        'ach_${_snake(d.achievements.recentUnlocks.first.code)}',
                    unlocked: true,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.achievements.recentUnlocks.first.name,
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          Formatters.shortDate(
                            d.achievements.recentUnlocks.first.unlockedAt,
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSecondary
                                : AppLightColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go(Routes.achievements),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Streak prominence (also part of achievements)
        _staggered(i++, _StreakPreview(dashboard: d)),
        const SizedBox(height: 18),

        // Keep existing Phase 2 strips as compact density helpers (not fabricating)
        if (isWide) ...[
          // On wide, show recently learned/mastered/new in a 2-col helper row via AdaptiveGrid
          AdaptiveGrid(
            medium: 2,
            expanded: 2,
            wide: 3,
            spacing: 14,
            runSpacing: 14,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Recently learned'),
                  _RecentlyLearnedStrip(dashboard: d),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Mastered'),
                  _MasteredStrip(dashboard: d),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'New worlds'),
                  _NewWorldsStrip(dashboard: d),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ] else ...[
          _staggered(i++, const SectionHeader(title: 'Recently learned')),
          _staggered(i++, _RecentlyLearnedStrip(dashboard: d)),
          const SizedBox(height: 8),
          _staggered(i++, const SectionHeader(title: 'Mastered')),
          _staggered(i++, _MasteredStrip(dashboard: d)),
          const SizedBox(height: 8),
          _staggered(i++, const SectionHeader(title: 'New worlds')),
          _staggered(i++, _NewWorldsStrip(dashboard: d)),
          const SizedBox(height: 8),
        ],

        if (d.recentActivity.quizzes.isNotEmpty) ...[
          _staggered(i++, const SectionHeader(title: 'Recent battles')),
          _staggered(i++, RecentBattles(quizzes: d.recentActivity.quizzes)),
        ],
        ],
      ),
    );
  }

  static String _snake(String code) => code.toLowerCase();

  static RecommendationItem? _explainableRecommendation(Dashboard d) {
    for (final item in d.recommendations) {
      if (item.topicId != null &&
          item.topicName?.trim().isNotEmpty == true &&
          item.reason.trim().isNotEmpty) {
        return item;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// 1. HERO — premium, theme-aware, responsive
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final g = dashboard.gamification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = dashboard.learner.displayName;
    return GameCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar + level
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.brand,
                      border: Border.all(
                        color: isDark ? AppColors.primaryBright : Colors.white,
                        width: 2,
                      ),
                      boxShadow: isDark
                          ? AppShadows.glow(AppColors.primary, alpha: 0.35)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '${g.currentLevel}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Formatters.daypartGreeting()}, ${_firstName(name)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 13, color: AppColors.xp),
                        const SizedBox(width: 4),
                        Text(
                          '${Formatters.count(g.totalXp)} XP',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.xp,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Level ${g.currentLevel} of ${g.maxLevel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StreakChip(
                days: dashboard.streak.currentStreakDays,
                onTap: () => context.go(Routes.streak),
              ),
            ],
          ),
          const SizedBox(height: 14),
          XPBar(
            currentLevel: g.currentLevel,
            totalXp: g.totalXp,
            xpToNextLevel: g.xpToNextLevel,
            height: 8,
            showLabels: true,
          ),
          const SizedBox(height: 6),
          Text(
            g.xpToNextLevel == null
                ? 'Peak mastery — you are at max level'
                : '${Formatters.count(g.xpToNextLevel!)} XP to next level',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  static String _firstName(String name) => name.split(' ').first;
}

// 2. CONTINUE LEARNING — prominent CTA, theme-aware
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.dashboard, required this.onContinue});
  final Dashboard dashboard;
  final VoidCallback onContinue;

  bool get _hasSubject => dashboard.currentSubject != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = dashboard.currentSubject;
    final topic = subject?.currentTopic;
    final path = dashboard.learningPath;
    return GlowCard(
      glowColor: AppColors.primary,
      intensity: isDark ? 0.22 : 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'CURRENT ADVENTURE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: AppColors.primaryBright,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primaryBright.withValues(alpha: 0.9)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subject?.name ?? 'Choose your first world',
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            topic?.topicName ?? path?.title ?? 'Your personalized path awaits',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryGameButton(
            label: _hasSubject ? 'Continue mission' : 'Start adventure',
            icon: Icons.play_arrow_rounded,
            onTap: onContinue,
          ),
        ],
      ),
    );
  }
}

// 3. JOURNEY — real learningPath nodes, no fabricated hierarchy
class _JourneySection extends StatelessWidget {
  const _JourneySection({required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = dashboard.learningPath;
    if (path == null || path.nodes.isEmpty) {
      return EmptyMiniCard(
        text: isDark
            ? 'Your journey will appear once your first path is forged. Start an adventure to chart it.'
            : 'Your journey will appear once your first path is forged. Start an adventure to chart it.',
      );
    }
    final total = path.nodes.length;
    final completed = path.nodes.where((n) => n.status == 'COMPLETED').length;
    final inProgress = path.nodes.where((n) => n.status == 'IN_PROGRESS').length;
    final available = path.nodes.where((n) => n.status == 'AVAILABLE').length;
    final next = path.nodes.firstWhere(
      (n) => n.status == 'AVAILABLE' || n.status == 'IN_PROGRESS',
      orElse: () => path.nodes.first,
    );
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  path.title.isEmpty ? 'Learning Path' : path.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.primary : AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
                ),
                child: Text(
                  '$completed/$total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Pill(label: '$completed completed', color: AppColors.success),
              if (inProgress > 0) _Pill(label: '$inProgress in progress', color: AppColors.warning),
              if (available > 0) _Pill(label: '$available available', color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: AppColors.primaryBright),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Next: ${next.topicName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: GameChip(
              label: 'OPEN PATH',
              icon: Icons.map_rounded,
              color: AppColors.primary,
              onTap: () {
                final name = Uri.encodeComponent(path.subjectName.isEmpty ? dashboard.currentSubject?.name ?? '' : path.subjectName);
                final id = path.subjectId.isEmpty ? dashboard.currentSubject?.id ?? '' : path.subjectId;
                if (id.isNotEmpty) context.go('/path/$id?name=$name');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

// 4. SUBJECTS — real catalog, adaptive grid 1→2→3
class _SubjectsSection extends ConsumerWidget {
  const _SubjectsSection({required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Subject>>(
      future: ref.read(contentRepoProvider).subjects(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: LinearProgressIndicator(minHeight: 3),
          );
        }
        if (snap.hasError) {
          return const EmptyMiniCard(text: 'Cannot load worlds right now.');
        }
        final subjects = (snap.data ?? const <Subject>[]).take(6).toList();
        if (subjects.isEmpty) return const EmptyMiniCard(text: 'No worlds available yet.');
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AdaptiveGrid(
          compact: 1,
          medium: 2,
          expanded: 2,
          wide: 3,
          children: subjects.map((s) {
            final assessed = dashboard.assessment.assessedSubjects.any((a) => a.subjectId == s.id);
            return GameCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SubjectGlyph(iconKey: s.iconKey, color: AppColors.primary, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.description.isEmpty ? 'Explore this world' : s.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (assessed ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: (assessed ? AppColors.success : AppColors.primary).withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      assessed ? 'LIVE' : 'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: assessed ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// 5. DAILY QUESTS — truthful: uses real recommendations if any, else coming-soon empty
class _QuestsSection extends StatelessWidget {
  const _QuestsSection({required this.dashboard, required this.onOpen});
  final Dashboard dashboard;
  final void Function(RecommendationItem) onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quests = dashboard.recommendations.take(3).toList();
    if (quests.isEmpty) {
      return GameCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
              ),
              child: const Icon(Icons.task_alt_rounded, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily quests are coming next',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your next missions will become daily quests. Keep exploring to unlock them.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: quests.map((q) {
        final label = q.activityType.isEmpty ? 'QUEST' : q.activityType.replaceAll('_', ' ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GameCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
                  ),
                  child: const Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.topicName ?? label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        q.reason.isEmpty ? label : q.reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GameChip(label: 'GO', icon: Icons.play_arrow_rounded, color: AppColors.primary, onTap: () => onOpen(q)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 6. GAME ZONE — prominent, 14 games entry, real navigation
class _GameZoneSection extends StatelessWidget {
  const _GameZoneSection({required this.dashboard});
  final Dashboard dashboard;

  String? _topicIdForGames() {
    final t = dashboard.currentSubject?.currentTopic?.topicId;
    if (t != null && t.isNotEmpty) return t;
    final lp = dashboard.learningPath;
    if (lp != null && lp.nodes.isNotEmpty) return lp.nodes.first.topicId;
    final rec = dashboard.recommendations.firstOrNull?.topicId;
    if (rec != null && rec.isNotEmpty) return rec;
    final recent = dashboard.mastery.recentTopics.firstOrNull?.topicId;
    return recent;
  }

  String? _subjectIdForGames() {
    final sid = dashboard.currentSubject?.id;
    if (sid != null && sid.isNotEmpty) return sid;
    final lpSid = dashboard.learningPath?.subjectId;
    if (lpSid != null && lpSid.isNotEmpty) return lpSid;
    return dashboard.learner.currentSubjectId;
  }

  String? _subjectNameForGames() => dashboard.currentSubject?.name ?? dashboard.learningPath?.subjectName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topicId = _topicIdForGames();
    final featured = [
      (GameType.quizBattle, 'Quiz Battle', Icons.bolt_rounded, AppColors.primary),
      (GameType.memoryMatch, 'Memory', Icons.psychology_rounded, AppColors.secondary),
      (GameType.puzzleArena, 'Puzzle', Icons.extension_rounded, const Color(0xFF06B6D4)),
      (GameType.bossBattle, 'Boss', Icons.videogame_asset_rounded, const Color(0xFFEF4444)),
    ];
    return GlowCard(
      glowColor: AppColors.primary,
      intensity: isDark ? 0.14 : 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_esports_rounded, size: 12, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'GAME ZONE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '14 GAMES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Play is how you master. Same mastery, more fun.',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          AdaptiveGrid(
            compact: 2,
            medium: 2,
            expanded: 4,
            wide: 4,
            spacing: 10,
            runSpacing: 10,
            children: featured.map((f) {
              return GestureDetector(
                onTap: () {
                  if (topicId == null || topicId.isEmpty) {
                    context.go(Routes.subjects);
                    return;
                  }
                  final name = _subjectNameForGames();
                  final sid = _subjectIdForGames();
                  context.push(Routes.gameHub(topicId, subjectId: sid, subjectName: name), extra: name);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceHigh.withValues(alpha: 0.55) : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: f.$4.withValues(alpha: 0.22)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: f.$4.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.$3, size: 18, color: f.$4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f.$2,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SecondaryGameButton(
              label: 'Explore all games',
              icon: Icons.arrow_forward_rounded,
              onTap: () {
                if (topicId == null || topicId.isEmpty) {
                  context.go(Routes.subjects);
                  return;
                }
                final name = _subjectNameForGames();
                final sid = _subjectIdForGames();
                context.push(Routes.gameHub(topicId, subjectId: sid, subjectName: name), extra: name);
              },
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Quiz Battle & Speed Run award real XP',
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 7. STREAK preview (also achievements above)
class _StreakPreview extends StatelessWidget {
  const _StreakPreview({required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = dashboard.streak;
    final hasStreak = streak.currentStreakDays > 0;
    return GameCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (hasStreak ? AppColors.streak : AppColors.locked).withValues(alpha: 0.14),
              border: Border.all(color: (hasStreak ? AppColors.streak : AppColors.border).withValues(alpha: 0.3)),
            ),
            child: Icon(
              hasStreak ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
              size: 20,
              color: hasStreak ? AppColors.streak : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStreak ? '${streak.currentStreakDays} day streak' : 'Start your streak',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                  ),
                ),
                Text(
                  hasStreak ? 'Best: ${streak.longestStreakDays} days' : 'Learn daily to build momentum',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GameChip(
            label: 'VIEW',
            icon: Icons.chevron_right_rounded,
            color: AppColors.streak,
            onTap: () => context.go(Routes.streak),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveFocusCard extends StatelessWidget {
  const _AdaptiveFocusCard({
    required this.dashboard,
    required this.recommendation,
    required this.onStart,
  });

  final Dashboard dashboard;
  final RecommendationItem recommendation;
  final VoidCallback onStart;

  RecentTopicMastery? get _recommendedMastery {
    final topicId = recommendation.topicId;
    if (topicId == null) return null;
    for (final topic in dashboard.mastery.recentTopics) {
      if (topic.topicId == topicId) return topic;
    }
    return null;
  }

  List<RecentTopicMastery> get _strongTopics => dashboard.mastery.recentTopics
      .where(
        (topic) =>
            topic.topicName.isNotEmpty &&
            (topic.masteryLevel == 'MASTERED' ||
                topic.masteryLevel == 'PROFICIENT'),
      )
      .take(2)
      .toList(growable: false);

  bool get _needsPractice {
    final mastery = _recommendedMastery;
    return recommendation.activityType == 'REVIEW' ||
        recommendation.activityType == 'REMEDIATION' ||
        mastery?.masteryLevel == 'BEGINNER' ||
        mastery?.trend == 'DECLINING';
  }

  @override
  Widget build(BuildContext context) {
    final mastery = _recommendedMastery;
    final strongTopics = _strongTopics;
    final tint = _needsPractice ? AppColors.warning : AppColors.secondary;
    final topicName = recommendation.topicName!;
    final difficulty = mastery?.currentDifficulty.isNotEmpty == true
        ? mastery!.currentDifficulty
        : recommendation.recommendedDifficulty;
    final difficultyLabel = mastery?.currentDifficulty.isNotEmpty == true
        ? 'CURRENT DIFFICULTY'
        : 'RECOMMENDED DIFFICULTY';

    return GlowCard(
      glowColor: tint,
      intensity: 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: 16, color: tint),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'ADAPTIVE BRIEF',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                    color: tint,
                  ),
                ),
              ),
              if (recommendation.priority > 0)
                PriorityPill(priority: recommendation.priority),
            ],
          ),
          if (strongTopics.isNotEmpty) ...[
            const SizedBox(height: 14),
            _FocusLine(
              label: 'YOU ARE STRONG IN',
              value: strongTopics
                  .map(
                    (topic) =>
                        '${topic.topicName} (${Formatters.percent(topic.masteryScore)})',
                  )
                  .join('  ·  '),
            ),
          ],
          if (_needsPractice) ...[
            const SizedBox(height: 12),
            _FocusLine(label: 'NEEDS PRACTICE', value: topicName),
          ],
          const SizedBox(height: 12),
          _FocusLine(label: 'NEXT RECOMMENDED MISSION', value: topicName),
          if (difficulty.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FocusLine(label: difficultyLabel, value: difficulty),
                ),
                DifficultyPill(difficulty: difficulty),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _FocusLine(label: 'WHY', value: recommendation.reason),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: GameChip(
              label: recommendation.activityType == 'CONTINUE_LESSON'
                  ? 'START RECOMMENDED TRAINING'
                  : 'START RECOMMENDED CHALLENGE',
              icon: Icons.play_arrow_rounded,
              color: tint,
              onTap: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusLine extends StatelessWidget {
  const _FocusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Assessment placement nudge.
class _AssessmentNudge extends ConsumerWidget {
  const _AssessmentNudge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider).data;
    final subjectId = dashboard?.currentSubject?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      child: Row(
        children: [
          const NovaCompanion(size: 44, mood: NovaMood.thinking),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Knowledge scan available',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                  ),
                ),
                Text(
                  'Take a quick scan so the AI can calibrate your first missions.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GameChip(
            label: 'SCAN',
            icon: Icons.radar_rounded,
            color: AppColors.secondary,
            onTap: () {
              ref.read(audioManagerProvider).play(Sfx.buttonTap);
              if (subjectId != null) {
                context.push(Routes.assessmentIntro(subjectId));
              } else {
                context.go(Routes.subjects);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mastery strip - recentTopics rendered verbatim from DASH-001 section 3.
class MasteryStrip extends StatelessWidget {
  const MasteryStrip({super.key, required this.topics});

  final List<RecentTopicMastery> topics;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: topics.map((t) {
        final (_, levelIcon) = EnumPresentationExt.masteryLevel(t.masteryLevel);
        final (_, trendIcon) = EnumPresentationExt.trend(t.trend);
        final tint = switch (t.masteryLevel) {
          'MASTERED' => AppColors.xp,
          'PROFICIENT' => AppColors.success,
          'DEVELOPING' => AppColors.warning,
          _ => AppColors.secondaryDeep,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => context.push(Routes.topicPerformance(t.topicId)),
            child: GameCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.topicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(levelIcon, size: 14, color: tint),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.percent(t.masteryScore),
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(trendIcon,
                      size: 14,
                      color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                  Icon(Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 2: Recently Learned — derived verbatim from DASH-001 mastery.recentTopics
// and recentActivity. Honest empty when insufficient data; no fake timestamps.
class _RecentlyLearnedStrip extends StatelessWidget {
  const _RecentlyLearnedStrip({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assessed = dashboard.assessment.assessedSubjects;
    if (assessed.isNotEmpty) {
      final slice = assessed.take(3).toList();
      return Column(
        children: slice.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                final name = Uri.encodeComponent(s.subjectName);
                context.go(
                  '/${Routes.path(s.subjectId).substring(1)}?name=$name',
                );
              },
              child: GameCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        'ASSESSED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
    final recentQuizzes = dashboard.recentActivity.quizzes;
    if (recentQuizzes.isNotEmpty) {
      final slice = recentQuizzes.take(3).toList();
      return Column(
        children: slice.map((q) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => context.push(Routes.topic(q.topicId)),
              child: GameCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: Text(
                        Formatters.percent(q.score),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBright,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        q.topicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
    final recentTopics = dashboard.mastery.recentTopics;
    if (recentTopics.isNotEmpty) {
      final slice = recentTopics.take(3).toList();
      return Column(
        children: slice.map((t) {
          final (_, levelIcon) = EnumPresentationExt.masteryLevel(
            t.masteryLevel,
          );
          final tint = switch (t.masteryLevel) {
            'MASTERED' => AppColors.xp,
            'PROFICIENT' => AppColors.success,
            'DEVELOPING' => AppColors.warning,
            _ => AppColors.secondaryDeep,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => context.push(Routes.topicPerformance(t.topicId)),
              child: GameCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(levelIcon, size: 16, color: tint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.topicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
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
                    const SizedBox(width: 6),
                    Text(
                      t.trend.isEmpty ? 'NEW' : t.trend,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
    return const EmptyMiniCard(
      text:
          'No recent learning yet — take a scan or challenge to start your journey.',
    );
  }
}

class _MasteredStrip extends StatelessWidget {
  const _MasteredStrip({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mastered = dashboard.mastery.recentTopics
        .where((t) => t.masteryLevel == 'MASTERED')
        .take(3)
        .toList();
    if (mastered.isEmpty) {
      return const EmptyMiniCard(
        text:
            'No topics mastered yet — keep conquering missions to earn mastery.',
      );
    }
    return Column(
      children: mastered.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => context.push(Routes.topicPerformance(t.topicId)),
            child: GameCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 16,
                    color: AppColors.xp,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.topicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.xp.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.xp.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'MASTERED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.xp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// New worlds — presentation-only filter of SUBJ-001 catalog where id NOT IN
// DASH-001 assessment.assessedSubjects. One fetch of the catalog, no per-filter request.
class _NewWorldsStrip extends ConsumerStatefulWidget {
  const _NewWorldsStrip({required this.dashboard});

  final Dashboard dashboard;

  @override
  ConsumerState<_NewWorldsStrip> createState() => _NewWorldsStripState();
}

class _NewWorldsStripState extends ConsumerState<_NewWorldsStrip> {
  late final Future<List<Subject>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(contentRepoProvider).subjects();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assessedIds = widget.dashboard.assessment.assessedSubjects
        .map((a) => a.subjectId)
        .toSet();
    return FutureBuilder<List<Subject>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          );
        }
        if (snap.hasError) {
          return const EmptyMiniCard(text: 'Cannot load worlds right now.');
        }
        final subjects = snap.data ?? const <Subject>[];
        final newSubjects = subjects
            .where((s) => !assessedIds.contains(s.id))
            .take(3)
            .toList();
        if (newSubjects.isEmpty) {
          if (subjects.isEmpty) {
            return const EmptyMiniCard(text: 'No worlds available yet.');
          }
          return const EmptyMiniCard(
            text: 'All worlds started — explore your path to discover more.',
          );
        }
        return Column(
          children: newSubjects.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  final name = Uri.encodeComponent(s.name);
                  context.go('/${Routes.path(s.id).substring(1)}?name=$name');
                },
                child: GameCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SubjectGlyph(
                        iconKey: s.iconKey,
                        color: AppColors.primaryBright,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Recent quiz attempts (DASH-001 section 10).
class RecentBattles extends StatelessWidget {
  const RecentBattles({super.key, required this.quizzes});

  final List<RecentQuizRun> quizzes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: quizzes.map((q) {
        final scoreColor = q.score >= 80
            ? AppColors.success
            : q.score >= 50
                ? AppColors.warning
                : AppColors.error;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => context.push(Routes.topic(q.topicId)),
            child: GameCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.55),
                      ),
                      color: scoreColor.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      Formatters.percent(q.score),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.topicName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${q.correctCount}/${q.totalQuestions} correct · '
                          '${Formatters.shortDate(q.submittedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.quiz_outlined,
                    size: 17,
                    color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Local enum-presentation helpers to avoid importing formatters twice.
abstract final class EnumPresentationExt {
  static (String, IconData) masteryLevel(String level) => switch (level) {
        'MASTERED' => ('Mastered', Icons.workspace_premium_rounded),
        'PROFICIENT' => ('Proficient', Icons.star_rounded),
        'DEVELOPING' => ('Developing', Icons.trending_up_rounded),
        _ => ('Beginner', Icons.eco_rounded),
      };

  static (String, IconData) trend(String trend) => switch (trend) {
        'IMPROVING' => ('Improving', Icons.north_east_rounded),
        'STABLE' => ('Stable', Icons.drag_handle_rounded),
        'DECLINING' => ('Needs attention', Icons.priority_high_rounded),
        _ => ('New', Icons.bolt_rounded),
      };
}

extension on List<RecommendationItem> {
  RecommendationItem? get firstOrNull => isEmpty ? null : first;
}

extension on List<RecentTopicMastery> {
  RecentTopicMastery? get firstOrNull => isEmpty ? null : first;
}
