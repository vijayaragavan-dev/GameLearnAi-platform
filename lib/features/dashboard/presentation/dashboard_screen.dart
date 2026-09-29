import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/error/user_facing_error.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../../../core/theme/game_visual_identity.dart';
import '../../../core/theme/subject_visual_identity.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/progression_widgets.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/xp_bar.dart';
import '../../game_engine/models/game_models.dart';
import '../../leaderboard/providers/leaderboard_providers.dart';
import '../../subjects/domain/world_context.dart';
import '../../avatar/providers/active_mascot_provider.dart';
import '../../avatar/widgets/cartoon_mascot_view.dart';
import '../../../core/models/mascot_character.dart';
import '../providers/dashboard_provider.dart';

/// Comic Neo-Brutalist Dashboard Screen
///
/// Mandated sections:
/// 1. DASHBOARD HERO (Profile / Level / XP / Streak)
/// 2. CURRENT ADVENTURE (Continue mission)
/// 3. YOUR JOURNEY (Learning path progress & nodes)
/// 4. WORLDS (Top worlds catalog & view all)
/// 5. GAME ZONE (14 Games showcase & featured arenas)
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
          showPremiumSnack(
            context,
            'This world is complete! Explore another world or revisit topics.',
            accent: AppColors.success,
            icon: Icons.emoji_events_rounded,
          );
        }
      }
      final name = Uri.encodeComponent(subject.name);
      context.push('/${Routes.path(subject.id).substring(1)}?name=$name');
      return;
    }
    context.push(Routes.subjects);
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
        backgroundColor: const Color(0xFFFFD43B), // Game Yellow
        foregroundColor: const Color(0xFF171923), // Ink Black
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF171923), width: 2.0),
        ),
        icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF171923)),
        label: const Text(
          'NOVA',
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Color(0xFF171923),
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: GlowOrb(
                color: AppColors.primary,
                size: 320,
                opacity: isDark ? 0.10 : 0.04,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -40,
            child: IgnorePointer(
              child: GlowOrb(
                color: AppColors.secondary,
                size: 260,
                opacity: isDark ? 0.06 : 0.03,
              ),
            ),
          ),
          RefreshIndicator(
            color: AppColors.primaryBright,
            backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
            onRefresh: _refresh,
            child: SafeArea(
              top: true,
              bottom: false,
              child: Builder(
                builder: (context) {
                  if (state.showLoading) {
                    return const SkeletonDashboard();
                  }
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
                    final offline =
                        state.error is NetworkException ||
                        state.error is TimeoutApiException;
                    return _DashboardBody(
                      dashboard: dashboard,
                      onContinue: () => _continueAdventure(dashboard),
                      onOpenRecommendation: _openRecommendation,
                      showOfflineBanner: offline,
                      onRetryOffline: _refresh,
                    );
                  }
                  return const SkeletonDashboard();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.dashboard,
    required this.onContinue,
    required this.onOpenRecommendation,
    this.showOfflineBanner = false,
    this.onRetryOffline,
  });

  final Dashboard dashboard;
  final VoidCallback onContinue;
  final void Function(RecommendationItem) onOpenRecommendation;
  final bool showOfflineBanner;
  final VoidCallback? onRetryOffline;

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
    final isExpanded =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.expanded;
    var i = 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveCenter(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showOfflineBanner) ...[
                OfflineBanner(onRetry: onRetryOffline ?? () {}),
                const SizedBox(height: 12),
              ],

              // ── 1. DASHBOARD HERO & 2. CURRENT ADVENTURE ──
              if (isExpanded) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _staggered(i++, _HeroCard(dashboard: d))),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _staggered(
                        i++,
                        _ContinueCard(dashboard: d, onContinue: onContinue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ] else ...[
                // 1. DASHBOARD HERO
                _staggered(i++, _HeroCard(dashboard: d)),
                const SizedBox(height: 16),
                // 2. CURRENT ADVENTURE
                _staggered(i++, _ContinueCard(dashboard: d, onContinue: onContinue)),
                const SizedBox(height: 20),
              ],

              if (d.assessment.assessedSubjects.isEmpty &&
                  d.mastery.topicsAssessed == 0 &&
                  !d.recommendations.any((r) => r.topicId != null)) ...[
                _staggered(i++, const _AssessmentNudge()),
                const SizedBox(height: 20),
              ],

              // ── 3. YOUR JOURNEY ──
              _staggered(
                i++,
                const _ComicSectionHeader(
                  title: 'Your journey',
                  icon: Icons.alt_route_rounded,
                  accent: Color(0xFF3B82F6),
                ),
              ),
              _staggered(i++, _JourneySection(dashboard: d)),
              const SizedBox(height: 20),

              // ── 4. WORLDS ──
              _staggered(
                i++,
                const _ComicSectionHeader(
                  title: 'Worlds',
                  icon: Icons.public_rounded,
                  accent: Color(0xFF06B6D4),
                ),
              ),
              _staggered(i++, _SubjectsSection(dashboard: d)),
              const SizedBox(height: 20),

              // ── 5. GAME ZONE ──
              _staggered(
                i++,
                const _ComicSectionHeader(
                  title: 'Game zone',
                  icon: Icons.sports_esports_rounded,
                  accent: Color(0xFF7C3AED),
                  badge: '14 GAMES',
                ),
              ),
              _staggered(i++, _GameZoneSection(dashboard: d)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. HERO — Comic command center identity
// ─────────────────────────────────────────────────────────────────────────────
// ---------------------------------------------------------------------------
// 1. HERO — Comic Brutalist Command Center
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMascot = ref.watch(activeMascotProvider);
    final g = dashboard.gamification;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = dashboard.learner.displayName;
    final firstName = _firstName(name);

    final mastery =
        (dashboard.learner.overallMastery.clamp(0, 100) / 100)
            .clamp(0.0, 1.0);

    final compactHero = MediaQuery.sizeOf(context).width < 600;

    final ink = isDark
        ? const Color(0xFFF4F7FF)
        : const Color(0xFF111827);

    final paper = isDark
        ? const Color(0xFF182235)
        : const Color(0xFFFFFCF4);

    final blue = AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ink,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: isDark ? 0.45 : 0.18),
            offset: const Offset(7, 7),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // ---------------------------------------------------------------
            // COMIC BACKGROUND BLOCK
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: compactHero ? 110 : 180,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      blue.withValues(alpha: 0.95),
                      AppColors.secondary.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // COMIC YELLOW ACCENT
            Positioned(
              left: -20,
              bottom: -30,
              child: Transform.rotate(
                angle: -0.08,
                child: Container(
                  width: compactHero ? 150 : 220,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.xp,
                    border: Border.all(
                      color: ink,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // DECORATIVE COMIC DOTS
            Positioned(
              right: 18,
              top: 18,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(70, 70),
                  painter: _ComicDotsPainter(
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // CONTENT
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================================================
                  // TOP AREA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -----------------------------------------------------
                      // AVATAR
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => context.push(Routes.adminCharacters),
                            child: Container(
                              width: compactHero ? 58 : 72,
                              height: compactHero ? 58 : 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeMascot.character.bellyColor,
                                border: Border.all(
                                  color: ink,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ink.withValues(alpha: 0.22),
                                    offset: const Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: CartoonMascotView(
                                character: activeMascot.character,
                                accessory: activeMascot.accessory,
                                mood: MascotMood.idle,
                                size: compactHero ? 48 : 58,
                              ),
                            ),
                          ),

                          // LEVEL BADGE
                          Positioned(
                            right: -7,
                            bottom: -5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.xp,
                                borderRadius:
                                    BorderRadius.circular(999),
                                border: Border.all(
                                  color: ink,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        ink.withValues(alpha: 0.25),
                                    offset: const Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${g.currentLevel}',
                                style: const TextStyle(
                                  fontFamily:
                                      AppTypography.bodyFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      // -----------------------------------------------------
                      // GREETING + NAME
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Formatters.daypartGreeting()}, '
                              '$firstName'
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTypography.overline(context)
                                      .copyWith(
                                color: blue,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTypography.hero(
                                context,
                                size: compactHero ? 24 : 28,
                              ).copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  size: 15,
                                  color: AppColors.xp,
                                ),
                                const SizedBox(width: 4),

                                Flexible(
                                  child: Text(
                                    '${Formatters.count(g.totalXp)} XP',
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style:
                                        AppTypography.xpLabel(
                                      context,
                                      size: 12,
                                    ).copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Flexible(
                                  child: Text(
                                    'LEVEL ${g.currentLevel}',
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style:
                                        AppTypography.caption(
                                      context,
                                    ).copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (!compactHero) ...[
                        const SizedBox(width: 8),

                        MasteryOrb(
                          fraction: mastery,
                          size: 52,
                          animate: false,
                        ),

                        const SizedBox(width: 7),

                        StreakChip(
                          days:
                              dashboard.streak.currentStreakDays,
                          onTap: () =>
                              context.push(Routes.streak),
                        ),

                        const SizedBox(width: 7),

                        _LeaderboardRankChip(
                          onTap: () {
                            context.push(Routes.arena);
                          },
                        ),
                      ],
                    ],
                  ),

                  // =========================================================
                  // MOBILE MASTERY / STREAK / LEADERBOARD
                  if (compactHero) ...[
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        MasteryOrb(
                          fraction: mastery,
                          size: 46,
                          animate: false,
                        ),
                        const SizedBox(width: 8),
                        StreakChip(
                          days:
                              dashboard.streak.currentStreakDays,
                          onTap: () =>
                              context.push(Routes.streak),
                        ),
                        const SizedBox(width: 8),
                        _LeaderboardRankChip(
                          onTap: () {
                            context.push(Routes.arena);
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // =========================================================
                  // MOTIVATIONAL COMIC MESSAGE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: ink,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Transform.rotate(
                          angle: -0.08,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 19,
                            color: AppColors.xp,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ready to learn something awesome today?',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTypography.bodySecondary(
                              context,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =========================================================
                  // XP SECTION
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      13,
                      12,
                      13,
                      10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.16)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: ink,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'LEVEL ${g.currentLevel}',
                              style: const TextStyle(
                                fontFamily:
                                    AppTypography.displayFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              g.xpToNextLevel == null
                                  ? 'MAX LEVEL'
                                  : '${Formatters.count(g.xpToNextLevel!)} XP TO GO',
                              style: TextStyle(
                                fontFamily:
                                    AppTypography.bodyFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppLightColors
                                        .textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        XPBar(
                          currentLevel: g.currentLevel,
                          totalXp: g.totalXp,
                          xpToNextLevel:
                              g.xpToNextLevel,
                          height: 9,
                          showLabels: true,
                        ),
                      ],
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

  static String _firstName(String name) =>
      name.split(' ').first;
}

/// Comic Leaderboard Rank Chip displayed beside StreakChip in the Hero card.
class _LeaderboardRankChip extends ConsumerWidget {
  const _LeaderboardRankChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(myPositionProvider);
    final rank = posState.data?.rank;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankText = (rank != null && rank > 0) ? '#$rank' : '#—';

    return PressableScale(
      onTap: () {
        ref.read(audioManagerProvider).play(Sfx.buttonTap);
        ref.read(hapticsProvider).tap();
        onTap();
      },
      child: Semantics(
        button: true,
        label: 'Leaderboard rank $rankText',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E232F) : const Color(0xFFFFD43B), // Game Yellow
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFF171923),
              width: 2.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF171923),
                offset: Offset(2.2, 2.2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 15,
                color: Color(0xFF171923),
              ),
              const SizedBox(width: 4),
              Text(
                rankText,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Color(0xFF171923),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comic dotted decoration
class _ComicDotsPainter extends CustomPainter {
  const _ComicDotsPainter({required this.color});

  final Color color;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const radius = 2.0;
    const gap = 11.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double y = 0; y < size.height; y += gap) {
      for (double x = 0; x < size.width; x += gap) {
        canvas.drawCircle(
          Offset(x, y),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _ComicDotsPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CURRENT ADVENTURE — prominent CTA
// ─────────────────────────────────────────────────────────────────────────────
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF171923), width: 2.5),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    border: Border.fromBorderSide(BorderSide(color: Color(0xFF171923), width: 1.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.explore_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'CURRENT ADVENTURE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF171923), width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subject?.name ?? 'Choose your first world',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF171923),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151921) : const Color(0xFFF7F5EF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF171923), width: 1.5),
            ),
            child: Row(
              children: [
                if (_hasSubject) ...[
                  SubjectIcon(iconKey: subject!.iconKey, size: 18, withBackground: false),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    topic?.topicName ?? path?.title ?? 'Your personalized path awaits',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF596174),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PressableScale(
            onTap: onContinue,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD43B), // Game Yellow
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF171923), width: 2.5),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 22, color: Color(0xFF171923)),
                  const SizedBox(width: 6),
                  Text(
                    _hasSubject ? 'CONTINUE MISSION' : 'START ADVENTURE',
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF171923),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. YOUR JOURNEY — real learningPath nodes
// ─────────────────────────────────────────────────────────────────────────────
class _JourneySection extends StatelessWidget {
  const _JourneySection({required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = dashboard.learningPath;
    if (path == null || path.nodes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E232F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF171923), width: 2.5),
          boxShadow: NeoBrutalShadows.hard,
        ),
        child: const Text(
          'Your journey will appear once your first path is forged. Start an adventure to chart it.',
          style: TextStyle(
            fontFamily: AppTypography.bodyFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF596174),
          ),
        ),
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
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF171923), width: 2.5),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    border: Border.fromBorderSide(BorderSide(color: Color(0xFF171923), width: 1.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alt_route_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'YOUR JOURNEY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE9FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF171923), width: 1.5),
                ),
                child: Text(
                  '$completed/$total NODES',
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF171923),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            path.title.isEmpty ? 'Learning Path' : path.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF171923),
            ),
          ),
          const SizedBox(height: 10),
          // Comic Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${(progress * 100).round()}% COMPLETED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$completed of $total finished',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF596174),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151921) : const Color(0xFFF7F5EF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF171923), width: 2.0),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: val.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Emerald Green
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Node Status Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatusPill(label: '$completed COMPLETED', color: const Color(0xFF10B981), bg: const Color(0xFFD1FAE5)),
              if (inProgress > 0)
                _StatusPill(label: '$inProgress IN PROGRESS', color: const Color(0xFFF59E0B), bg: const Color(0xFFFEF3C7)),
              if (available > 0)
                _StatusPill(label: '$available AVAILABLE', color: const Color(0xFF3B82F6), bg: const Color(0xFFDCE9FF)),
            ],
          ),
          const SizedBox(height: 12),
          // Next Topic Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151921) : const Color(0xFFF7F5EF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF171923), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded, size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next: ${next.topicName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF171923),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Open Path Button
          PressableScale(
            onTap: () {
              final name = Uri.encodeComponent(
                path.subjectName.isEmpty ? dashboard.currentSubject?.name ?? '' : path.subjectName,
              );
              final id = path.subjectId.isEmpty ? dashboard.currentSubject?.id ?? '' : path.subjectId;
              if (id.isNotEmpty) context.push('/path/$id?name=$name');
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE9FF), // Soft Blue
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF171923), width: 2.0),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_rounded, size: 18, color: Color(0xFF171923)),
                  SizedBox(width: 6),
                  Text(
                    'OPEN FULL PATH',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF171923),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF171923), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.displayFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. WORLDS — Real catalog (Top 2 + View All)
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectsSection extends ConsumerWidget {
  const _SubjectsSection({required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 4),
      ),
      error: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E232F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF171923), width: 2.5),
          boxShadow: NeoBrutalShadows.hard,
        ),
        child: const Text('Cannot load worlds right now.'),
      ),
      data: (all) {
        final subjects = [...all]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        if (subjects.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF171923), width: 2.5),
              boxShadow: NeoBrutalShadows.hard,
            ),
            child: const Text('No worlds available yet.'),
          );
        }

        final displayed = subjects.take(2).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...displayed.map((s) {
              final assessed = dashboard.assessment.assessedSubjects.any((a) => a.subjectId == s.id);
              final identity = SubjectVisualRegistry.fromIconKey(s.iconKey);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PressableScale(
                  onTap: () {
                    final name = Uri.encodeComponent(s.name);
                    context.push('${Routes.world(s.id)}?name=$name');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E232F) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF171923), width: 2.5),
                      boxShadow: NeoBrutalShadows.hardSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: identity.accent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF171923), width: 2.0),
                            boxShadow: NeoBrutalShadows.hardXs,
                          ),
                          alignment: Alignment.center,
                          child: Icon(identity.icon, size: 22, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF171923),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.description.isEmpty ? 'Explore this world' : s.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF596174),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: assessed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF171923), width: 1.5),
                          ),
                          child: Text(
                            assessed ? 'LIVE' : 'NEW',
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: isDark ? Colors.white : const Color(0xFF171923),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (subjects.length > 2) ...[
              const SizedBox(height: 2),
              PressableScale(
                onTap: () => context.push(Routes.subjects),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD43B), // Game Yellow
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF171923), width: 2.5),
                    boxShadow: NeoBrutalShadows.hardSm,
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public_rounded, size: 18, color: Color(0xFF171923)),
                      SizedBox(width: 8),
                      Text(
                        'VIEW ALL WORLDS',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF171923),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF171923)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. GAME ZONE — 14 Games Showcase & Featured Arenas
// ─────────────────────────────────────────────────────────────────────────────
class _GameZoneSection extends StatelessWidget {
  const _GameZoneSection({
    required this.dashboard,
  });

  final Dashboard dashboard;

  String? _topicIdForGames() {
    final t =
        dashboard.currentSubject?.currentTopic?.topicId;

    if (t != null && t.isNotEmpty) return t;

    final lp = dashboard.learningPath;

    if (lp != null && lp.nodes.isNotEmpty) {
      return lp.nodes.first.topicId;
    }

    final rec =
        dashboard.recommendations.firstOrNull?.topicId;

    if (rec != null && rec.isNotEmpty) return rec;

    final recent =
        dashboard.mastery.recentTopics.firstOrNull?.topicId;

    return recent;
  }

  /// Topic label for the Global Arena entry, mirroring [_topicIdForGames]
  /// source-by-source. The arena is intentionally subject-free, so the hub
  /// must show the topic — never the subject name in the topic slot.
  String? _topicNameForGames() {
    final t =
        dashboard.currentSubject?.currentTopic?.topicName;

    if (t != null && t.isNotEmpty) return t;

    final lp = dashboard.learningPath;

    if (lp != null && lp.nodes.isNotEmpty) {
      final n = lp.nodes.first.topicName;

      if (n.isNotEmpty) return n;
    }

    final rec =
        dashboard.recommendations.firstOrNull?.topicName;

    if (rec != null && rec.isNotEmpty) return rec;

    final recent =
        dashboard.mastery.recentTopics.firstOrNull?.topicName;

    if (recent != null && recent.isNotEmpty) return recent;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final topicId = _topicIdForGames();

    // Use real game identities from registry.
    // Logic intentionally unchanged.
    final featuredTypes = [
      GameType.quizBattle,
      GameType.memoryMatch,
      GameType.puzzleArena,
      GameType.bossBattle,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF171923), width: 2.5),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // HEADER ROW
          // ========================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // GAME ZONE BADGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF171923), width: 1.8),
                  boxShadow: NeoBrutalShadows.hardXs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.navGamesActive,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'GAME ZONE',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // GAME COUNT BADGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF282E3E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF171923), width: 1.6),
                  boxShadow: NeoBrutalShadows.hardXs,
                ),
                child: Text(
                  '14 GAMES',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.textPrimary : const Color(0xFF171923),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ========================================================
          // DESCRIPTION
          // ========================================================
          Text(
            'Play is how you master. Same mastery, more fun.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // ========================================================
          // GAME GRID
          // ========================================================
          AdaptiveGrid(
            compact: 2,
            medium: 2,
            expanded: 4,
            wide: 4,
            spacing: 8,
            runSpacing: 8,
            children: featuredTypes.map((type) {
              final identity = GameVisualRegistry.of(type);
              return PressableScale(
                onTap: () {
                  if (topicId == null || topicId.isEmpty) {
                    context.push(Routes.subjects);
                    return;
                  }
                  context.push(
                    Routes.gameHub(topicId),
                    extra: _topicNameForGames(),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262C3A) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF171923),
                      width: 2,
                    ),
                    boxShadow: NeoBrutalShadows.hardSm,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Column(
                      children: [
                        // SCENE THUMB / ARTWORK
                        Stack(
                          children: [
                            SceneThumb(
                              palette: scenePaletteForGame(identity.type.name),
                              seed: seedForKey(identity.type.name),
                              icon: identity.icon,
                              accent: identity.accent,
                              width: double.infinity,
                              height: 64,
                              iconSize: 26,
                              label: '${identity.type.displayName} game artwork',
                            ),
                            // Comic corner icon badge
                            Positioned(
                              top: 5,
                              left: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF171923), width: 1.5),
                                  boxShadow: NeoBrutalShadows.hardXs,
                                ),
                                child: Icon(
                                  identity.icon,
                                  size: 11,
                                  color: identity.accent,
                                ),
                              ),
                            ),
                            // Comic accent dot
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: identity.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF171923), width: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // GAME DETAILS
                        Padding(
                          padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
                          child: Column(
                            children: [
                              Text(
                                identity.type.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: isDark ? AppColors.textPrimary : const Color(0xFF171923),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: identity.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: identity.accent.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  identity.category.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFamily,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: identity.accent,
                                  ),
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
            }).toList(),
          ),
          const SizedBox(height: 10),

          // ========================================================
          // EXPLORE ALL GAMES BUTTON (Comic Neo-Brutal)
          // ========================================================
          PressableScale(
            onTap: () {
              if (topicId == null || topicId.isEmpty) {
                context.push(Routes.subjects);
                return;
              }
              context.push(
                Routes.gameHub(topicId),
                extra: _topicNameForGames(),
              );
            },
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF171923), width: 2.2),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'EXPLORE ALL 14 GAMES',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ========================================================
          // XP INFORMATION
          // ========================================================
          Center(
            child: Text(
              'Quiz Battle & Speed Run award real XP',
              style: TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting Comic Components
// ─────────────────────────────────────────────────────────────────────────────
class _ComicSectionHeader extends StatelessWidget {
  const _ComicSectionHeader({
    required this.title,
    required this.icon,
    required this.accent,
    this.badge,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF171923), width: 2.0),
              boxShadow: NeoBrutalShadows.hardXs,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: isDark ? Colors.white : const Color(0xFF171923),
              ),
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151921) : const Color(0xFFF7F5EF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF171923), width: 1.5),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171923),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssessmentNudge extends ConsumerWidget {
  const _AssessmentNudge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider).data;
    final subjectId = dashboard?.currentSubject?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF171923), width: 2.5),
        boxShadow: NeoBrutalShadows.hardSm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4), // Bright Cyan
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF171923), width: 2.0),
              boxShadow: NeoBrutalShadows.hardXs,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.radar_rounded, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Knowledge scan available',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF171923),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Take a quick scan so the AI can calibrate your first missions.',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 11.5,
                    color: Color(0xFF596174),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: () {
              ref.read(audioManagerProvider).play(Sfx.buttonTap);
              if (subjectId != null) {
                context.push(Routes.assessmentIntro(subjectId));
              } else {
                context.push(Routes.subjects);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD43B), // Game Yellow
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF171923), width: 2.0),
                boxShadow: NeoBrutalShadows.hardXs,
              ),
              child: const Text(
                'SCAN',
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF171923),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on List<RecommendationItem> {
  RecommendationItem? get firstOrNull => isEmpty ? null : first;
}

extension on List<RecentTopicMastery> {
  RecentTopicMastery? get firstOrNull => isEmpty ? null : first;
}
