import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/providers.dart';
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
import '../../../shared/widgets/recommendation_card.dart';
import '../../../shared/widgets/xp_bar.dart' show XPBar;
import '../providers/dashboard_provider.dart';

/// Command center: "What should I do next?" answered above the fold.
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
      final name = Uri.encodeComponent(subject.name);
      context.go('/${Routes.path(subject.id).substring(1)}?name=$name');
      return;
    }
    // No current subject yet: guide to worlds.
    context.go(Routes.subjects);
  }

  void _openRecommendation(RecommendationItem item) {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    context.push('/recommendation', extra: item);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(audioManagerProvider).play(Sfx.buttonTap);
          ref.read(hapticsProvider).tap();
          context.push(Routes.tutor);
        },
        backgroundColor: AppColors.secondaryDeep,
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: const Text(
          'NOVA',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBright,
        backgroundColor: AppColors.surfaceElevated,
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
  }

  @override
  Widget build(BuildContext context) {
    final d = dashboard;
    var i = 0;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        _staggered(i++, _Header(dashboard: d)),
        const SizedBox(height: 22),
        // Current adventure / start prompt.
        _staggered(i++, _AdventureCard(dashboard: d, onContinue: onContinue)),
        const SizedBox(height: 18),

        // Nova recommendations.
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

        // Assessment nudge when nothing assessed yet.
        if (d.assessment.assessedSubjects.isEmpty &&
            d.mastery.topicsAssessed == 0 &&
            !d.recommendations.any((r) => r.topicId != null))
          _staggered(i++, const _AssessmentNudge()),

        // Mastery glance.
        if (d.mastery.recentTopics.isNotEmpty) ...[
          _staggered(i++, const SectionHeader(title: 'Mastery radar')),
          _staggered(i++, MasteryStrip(topics: d.mastery.recentTopics)),
          const SizedBox(height: 8),
        ],

        // Recent achievement.
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
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
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

        // Recent activity.
        if (d.recentActivity.quizzes.isNotEmpty) ...[
          _staggered(i++, const SectionHeader(title: 'Recent battles')),
          _staggered(i++, RecentBattles(quizzes: d.recentActivity.quizzes)),
        ],
      ],
    );
  }

  static String _snake(String code) => code.toLowerCase();
}

// ---------------------------------------------------------------------------
// Header: greeting, level, XP bar, streak.
class _Header extends StatelessWidget {
  const _Header({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final g = dashboard.gamification;
    final name = dashboard.learner.displayName;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LevelBadge(level: g.currentLevel, size: 54),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${Formatters.daypartGreeting()}, ${_firstName(name)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${Formatters.count(g.totalXp)} XP collected',
                style: const TextStyle(fontSize: 12.5, color: AppColors.xp),
              ),
              // Backend-derived level progress (DASH-001 gamification block).
              // Nulls at MAX_LEVEL -> compact bar without "to next" label.
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: XPBar(
                  currentLevel: g.currentLevel,
                  totalXp: g.totalXp,
                  xpToNextLevel: g.xpToNextLevel,
                  height: 6,
                  showLabels: false,
                ),
              ),
            ],
          ),
        ),
        StreakChip(
          days: dashboard.streak.currentStreakDays,
          onTap: () => context.go(Routes.streak),
        ),
      ],
    );
  }

  static String _firstName(String name) => name.split(' ').first;
}

// ---------------------------------------------------------------------------
// Adventure hero card.
class _AdventureCard extends StatelessWidget {
  const _AdventureCard({required this.dashboard, required this.onContinue});

  final Dashboard dashboard;
  final VoidCallback onContinue;

  bool get _hasSubject => dashboard.currentSubject != null;

  @override
  Widget build(BuildContext context) {
    final subject = dashboard.currentSubject;
    final topic = subject?.currentTopic;
    final path = dashboard.learningPath;
    return GlowCard(
      glowColor: AppColors.primary,
      intensity: 0.28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
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
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subject?.name ?? 'Choose your first world',
            style: const TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            topic?.topicName ?? path?.title ?? 'Your personalized path awaits',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
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

// ---------------------------------------------------------------------------
// Assessment placement nudge.
class _AssessmentNudge extends ConsumerWidget {
  const _AssessmentNudge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dashboard already knows currentSubject; route there if available.
    final dashboard = ref.watch(dashboardProvider).data;
    final subjectId = dashboard?.currentSubject?.id;
    return GlassCard(
      child: Row(
        children: [
          const NovaCompanion(size: 44, mood: NovaMood.thinking),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Knowledge scan available',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'Take a quick scan so the AI can calibrate your first missions.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
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
                  Icon(trendIcon, size: 14, color: AppColors.textTertiary),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
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

// ---------------------------------------------------------------------------
// Recent quiz attempts (DASH-001 section 10).
class RecentBattles extends StatelessWidget {
  const RecentBattles({super.key, required this.quizzes});

  final List<RecentQuizRun> quizzes;

  @override
  Widget build(BuildContext context) {
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${q.correctCount}/${q.totalQuestions} correct Â· '
                          '${Formatters.shortDate(q.submittedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.quiz_outlined,
                    size: 17,
                    color: AppColors.textTertiary,
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
