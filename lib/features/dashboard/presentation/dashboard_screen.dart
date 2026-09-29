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
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/game_visual_identity.dart';
import '../../../core/theme/subject_visual_identity.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../game_engine/models/game_models.dart';
import '../../leaderboard/providers/leaderboard_providers.dart';
import '../../avatar/providers/active_mascot_provider.dart';
import '../../avatar/widgets/cartoon_mascot_view.dart';
import '../../subjects/domain/world_context.dart';
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
        icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Color(0xFFEF4444)),
        label: const Text(
          'SPARKY',
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

              // ── 0. TOP STATUS BAR (STREAK, XP, HEARTS, SOUND, THEME) ──
              _staggered(i++, _TopStatusBar(dashboard: d)),
              const SizedBox(height: 14),

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
                const SizedBox(height: 16),
              ] else ...[
                // 1. DASHBOARD HERO
                _staggered(i++, _HeroCard(dashboard: d)),
                const SizedBox(height: 16),
                // 2. CURRENT ADVENTURE
                _staggered(i++, _ContinueCard(dashboard: d, onContinue: onContinue)),
                const SizedBox(height: 16),
              ],

              if (d.assessment.assessedSubjects.isEmpty &&
                  d.mastery.topicsAssessed == 0 &&
                  !d.recommendations.any((r) => r.topicId != null)) ...[
                _staggered(i++, const _AssessmentNudge()),
                const SizedBox(height: 20),
              ],

              // ── 3. YOUR JOURNEY ──
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
// 0. TOP STATUS BAR (STREAK, XP, HEARTS, SOUND, THEME)
// ─────────────────────────────────────────────────────────────────────────────
class _TopStatusBar extends ConsumerStatefulWidget {
  const _TopStatusBar({required this.dashboard});
  final Dashboard dashboard;

  @override
  ConsumerState<_TopStatusBar> createState() => _TopStatusBarState();
}

class _TopStatusBarState extends ConsumerState<_TopStatusBar> {
  @override
  Widget build(BuildContext context) {
    final g = widget.dashboard.gamification;
    final streak = widget.dashboard.streak;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audio = ref.watch(audioManagerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && isDark);

    final streakCount = streak.currentStreakDays > 0 ? streak.currentStreakDays : 1;

    return Row(
      children: [
        // Left side: Status chips (Streak, XP, Hearts) wrapped in Expanded + FittedBox
        // to guarantee zero RenderFlex overflow on narrow devices (320px) or large stats.
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Streak Chip: 🔥 1 DAY
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD43B), // Neo yellow
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF171923), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '$streakCount ${streakCount == 1 ? "DAY" : "DAYS"}',
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF171923),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // XP Chip: ⭐ 344 XP
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E232F) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF171923), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${g.totalXp} XP',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF171923),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Hearts Chip: ❤️ 5/5
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B1D28) : const Color(0xFFFDE2E8),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF171923), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '5/5',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF171923),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Sound Toggle Button
        PressableScale(
          onTap: () {
            ref.read(audioManagerProvider).play(Sfx.buttonTap);
            final current = audio.sfxEnabled;
            audio.setSfxEnabled(!current);
            audio.setMusicEnabled(!current);
            setState(() {});
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232F) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF171923), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF171923),
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              audio.sfxEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 19,
              color: isDark ? Colors.white : const Color(0xFF171923),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Theme Toggle Button (Moon / Sun)
        PressableScale(
          onTap: () {
            ref.read(audioManagerProvider).play(Sfx.buttonTap);
            final current = ref.read(themeControllerProvider);
            final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            ref.read(themeControllerProvider.notifier).set(next);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232F) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF171923), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF171923),
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 18,
              color: isDark ? const Color(0xFFFFD43B) : const Color(0xFF171923),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. HERO — Comic command center greeting & Sparky mascot
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = dashboard.gamification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = dashboard.learner.displayName;
    final firstName = _firstName(name);
    final posState = ref.watch(myPositionProvider);
    final rank = posState.data?.rank;
    final activeMascot = ref.watch(activeMascotProvider);
    final mascotChar = activeMascot.character;

    void openLeaderboard() {
      ref.read(audioManagerProvider).play(Sfx.buttonTap);
      final subjectId = dashboard.currentSubject?.id;
      final uri = (subjectId != null && subjectId.isNotEmpty)
          ? '${Routes.arena}?subjectId=${Uri.encodeComponent(subjectId)}'
          : Routes.arena;
      context.push(uri);
    }

    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    final curLevel = g.currentLevel;
    final xpToGo = g.xpToNextLevel ?? 256;
    final totalThresh = g.nextLevelThresholdXp ?? (g.totalXp + xpToGo);
    final progress = totalThresh > 0
        ? (g.totalXp / totalThresh).clamp(0.08, 1.0)
        : 0.25;

    final subject = dashboard.currentSubject?.name ?? 'OOP';
    final subjectTag = subject.contains(' ')
        ? subject.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join().toUpperCase()
        : (subject.length > 5 ? subject.substring(0, 4).toUpperCase() : subject.toUpperCase());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF171923), width: 2.5),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP ROW: PINK BANNER / LEVEL & RANK / AVATAR ──
          Row(
            children: [
              // Pink Banner / Flag icon (tappable -> Leaderboard)
              PressableScale(
                onTap: openLeaderboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5277),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF171923), width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Level & Rank Buttons: Interactive Neo-Brutalist chips redirecting to Leaderboard
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Level Badge Button
                      PressableScale(
                        onTap: openLeaderboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF28233C) : const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF171923), width: 1.8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF171923),
                                offset: Offset(1.5, 1.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C3AED),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'LEVEL ${curLevel.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: isDark ? Colors.white : const Color(0xFF171923),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Rank Badge Button
                      PressableScale(
                        onTap: openLeaderboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD43B), // Neo Yellow
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF171923), width: 1.8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF171923),
                                offset: Offset(1.5, 1.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                'RANK ${rank != null && rank > 0 ? "#$rank" : "#27"}',
                                style: const TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF171923),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Avatar Circle with User Initial
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF171923), width: 2.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (firstName.isNotEmpty ? firstName[0] : 'V').toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── GREETING TITLE: Good Afternoon, Vijay! ──
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$timeGreeting, ',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF171923),
                  ),
                ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Yellow Sunburst rays above name
                  Positioned(
                    top: -12,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: -0.3,
                          child: Container(
                            width: 3.5,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD43B),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.rotate(
                          angle: 0.3,
                          child: Container(
                            width: 3.5,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD43B),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Name + Wavy Underline
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$firstName!',
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF3B82F6), // GameLearn Blue
                        ),
                      ),
                      const SizedBox(height: 1),
                      SizedBox(
                        width: (firstName.length * 13.0 + 12).clamp(40.0, 140.0),
                        height: 7,
                        child: const CustomPaint(
                          painter: _WavyLinePainter(color: Color(0xFFFFD43B)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

          const SizedBox(height: 14),

          // ── SPEECH BUBBLE & SPARKY MASCOT ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Speech bubble
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151921) : const Color(0xFFFFFCF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF171923), width: 2.0),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF171923),
                          ),
                          children: [
                            const TextSpan(text: 'Ready to level up your '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD43B),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF171923), width: 1.2),
                                ),
                                child: Text(
                                  subjectTag,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.displayFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF171923),
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: " skills today? Let's conquer code! 🚀"),
                          ],
                        ),
                      ),
                    ),
                    // Pointer triangle pointing right toward Sparky
                    Positioned(
                      bottom: -8,
                      right: 28,
                      child: CustomPaint(
                        size: const Size(14, 10),
                        painter: _BubbleTrianglePainter(
                          color: isDark ? const Color(0xFF151921) : const Color(0xFFFFFCF4),
                          borderColor: const Color(0xFF171923),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Active Mascot Container (Dynamic companion chosen in Admin Studio)
              PressableScale(
                onTap: () {
                  ref.read(audioManagerProvider).play(Sfx.buttonTap);
                  context.push(Routes.adminCharacters);
                },
                child: Container(
                  width: 78,
                  height: 92,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF28233C)
                        : mascotChar.primaryColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF171923), width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: CartoonMascotView(
                        character: mascotChar,
                        accessory: activeMascot.accessory,
                        mood: activeMascot.mood,
                        size: 64,
                        isAnimated: true,
                        onTap: () {
                          ref.read(audioManagerProvider).play(Sfx.buttonTap);
                          context.push(Routes.adminCharacters);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── DASHED LINE ──
          const _DashedLine(),

          const SizedBox(height: 12),

          // ── PROGRESS ROW (NEXT LEVEL / XP TO GO) ──
          PressableScale(
            onTap: openLeaderboard,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 350,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next: Level ${curLevel + 1}',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF171923),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    Text(
                      '$xpToGo XP to go',
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Level progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151921) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF171923), width: 2.0),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.08, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD43B), // Neo Yellow
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _firstName(String name) => name.split(' ').first;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CURRENT ADVENTURE — Comic Adventure Card
// ─────────────────────────────────────────────────────────────────────────────
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.dashboard, required this.onContinue});
  final Dashboard dashboard;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final subject = dashboard.currentSubject;
    final topic = subject?.currentTopic;
    final subjectName = subject?.name ?? 'Object Oriented Programming';
    final topicName = topic?.topicName ??
        dashboard.learningPath?.title ??
        'Classes, Objects, Inheritance & Abstraction essentials.';
    final mastery = (dashboard.learner.overallMastery.clamp(0, 100)).toInt();
    final masteryProgress = (mastery / 100.0).clamp(0.05, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB), // Vibrant Royal Blue
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF171923), width: 2.8),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP PILLS: CURRENT ADVENTURE & UNIT 01 ──
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 340,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD43B), // Neo Yellow
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF171923), width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF171923),
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Text(
                      'CURRENT ADVENTURE',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Color(0xFF171923),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF171923), width: 1.8),
                    ),
                    child: const Text(
                      'UNIT 01',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Color(0xFF171923),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── TITLE: Object Oriented Programming ──
          Text(
            subjectName,
            style: const TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 6),

          // ── SUBTITLE: Classes, Objects, Inheritance & Abstraction essentials ──
          Text(
            topicName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFDBEAFE),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // ── MASTERY CONTAINER: [✓] 21% Mastered [====== ] ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF171923), width: 2.0),
            ),
            child: Row(
              children: [
                // Green checkmark circle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF171923), width: 1.6),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF171923),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    '$mastery% Mastered',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF171923),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Mini progress bar
                Container(
                  width: 76,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF93C5FD),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF171923), width: 1.4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: masteryProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── ACTION BUTTON: CONTINUE MISSION ➔ ──
          PressableScale(
            onTap: onContinue,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD43B), // Neo Yellow
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF171923), width: 2.6),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              alignment: Alignment.center,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONTINUE MISSION',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Color(0xFF171923),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Color(0xFF171923),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. YOUR JOURNEY — Comic Path with Dynamic Companion & Curriculum Nodes
// ─────────────────────────────────────────────────────────────────────────────
class _JourneySection extends ConsumerWidget {
  const _JourneySection({required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMascot = ref.watch(activeMascotProvider);
    final mascotChar = activeMascot.character;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = dashboard.learningPath;
    final nodes = path?.nodes ?? [];
    final total = nodes.isNotEmpty ? nodes.length : 10;
    final completed = nodes.where((n) => n.status == 'COMPLETED').length;
    final available = nodes.where((n) => n.status == 'AVAILABLE').length;

    String activeTopicName = 'Java Platform & Classes';
    if (nodes.isNotEmpty) {
      final active = nodes.where((n) => n.status == 'AVAILABLE' || n.status == 'IN_PROGRESS');
      if (active.isNotEmpty) {
        activeTopicName = active.first.topicName;
      } else {
        activeTopicName = nodes.first.topicName;
      }
    } else if (dashboard.currentSubject?.currentTopic != null) {
      activeTopicName = dashboard.currentSubject!.currentTopic!.topicName;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF171923), width: 2.5),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP HEADER ROW: BOOK ICON / YOUR JOURNEY / NODES PILL & ASK SPARKY ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Open Book Icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFED7AA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF171923), width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF171923),
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 20,
                  color: Color(0xFF171923),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR JOURNEY',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: isDark ? Colors.white : const Color(0xFF171923),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completed completed • ${available > 0 ? available : 1} available',
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Pills: 0 / 10 NODES & ASK SPARKY
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151921) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF171923), width: 1.6),
                    ),
                    child: Text(
                      '$completed / $total NODES',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: isDark ? Colors.white : const Color(0xFF171923),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PressableScale(
                    onTap: () => context.push('/tutor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD43B), // Neo Yellow
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF171923), width: 1.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF171923),
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_rounded, size: 12, color: Color(0xFFB91C1C)),
                          const SizedBox(width: 4),
                          Text(
                            'ASK ${mascotChar.name.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: Color(0xFF171923),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const _DashedLine(),
          const SizedBox(height: 14),

          // ── ACTIVE CHALLENGE BOX WITH PEEKING SPARKY ──
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151921) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF171923), width: 2.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Content on the left
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 120,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ACTIVE CHALLENGE',
                              style: TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Color(0xFF3B82F6), // GameLearn Blue
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Next: $activeTopicName',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                color: isDark ? Colors.white : const Color(0xFF171923),
                              ),
                            ),
                          ],
                        ),

                        // START button
                        PressableScale(
                          onTap: () {
                            final name = Uri.encodeComponent(
                              path?.subjectName.isEmpty ?? true
                                  ? dashboard.currentSubject?.name ?? ''
                                  : path!.subjectName,
                            );
                            final id = path?.subjectId.isEmpty ?? true
                                ? dashboard.currentSubject?.id ?? ''
                                : path!.subjectId;
                            if (id.isNotEmpty) {
                              context.push('/path/$id?name=$name');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E), // Vivid Emerald Green
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF171923), width: 2.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF171923),
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Text(
                              'START',
                              style: TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Color(0xFF171923),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dynamic Mascot Peeking on the right (from Admin Character Studio)
                  Positioned(
                    right: 4,
                    bottom: -2,
                    child: PressableScale(
                      onTap: () {
                        ref.read(audioManagerProvider).play(Sfx.buttonTap);
                        context.push(Routes.adminCharacters);
                      },
                      child: CartoonMascotView(
                        character: mascotChar,
                        accessory: activeMascot.accessory,
                        mood: activeMascot.mood,
                        size: 100,
                        isAnimated: true,
                        onTap: () {
                          ref.read(audioManagerProvider).play(Sfx.buttonTap);
                          context.push(Routes.adminCharacters);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── CURRICULUM NODES HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'CURRICULUM NODES',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: isDark ? Colors.white : const Color(0xFF171923),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completed / $total',
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── 5 CURRICULUM NODE SQUARES ──
          LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: constraints.maxWidth < 282 ? 282 : constraints.maxWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Node 1: Active Blue
                      _NodeSquare(
                        label: '1',
                        isActive: true,
                        isCompleted: false,
                        isLocked: false,
                        onTap: () {
                          final id = path?.subjectId ?? dashboard.currentSubject?.id ?? '';
                          if (id.isNotEmpty) context.push('/path/$id');
                        },
                      ),

                      // Node 2: Locked
                      _NodeSquare(
                        label: '2',
                        isActive: false,
                        isCompleted: false,
                        isLocked: true,
                        onTap: () {},
                      ),

                      // Node 3: Locked
                      _NodeSquare(
                        label: '3',
                        isActive: false,
                        isCompleted: false,
                        isLocked: true,
                        onTap: () {},
                      ),

                      // Node 4: Locked
                      _NodeSquare(
                        label: '4',
                        isActive: false,
                        isCompleted: false,
                        isLocked: true,
                        onTap: () {},
                      ),

                      // Node 5: SPARKY Bonus
                      _NodeSquare(
                        label: 'SPARKY 👑',
                        isActive: false,
                        isCompleted: false,
                        isLocked: false,
                        isBonus: true,
                        onTap: () => context.push('/tutor'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NodeSquare extends StatelessWidget {
  const _NodeSquare({
    required this.label,
    required this.isActive,
    required this.isCompleted,
    required this.isLocked,
    this.isBonus = false,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isCompleted;
  final bool isLocked;
  final bool isBonus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Widget content;

    if (isBonus) {
      bg = const Color(0xFFF472B6); // Comic pink
      content = const FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SPARKY',
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF171923),
                ),
              ),
              SizedBox(width: 2),
              Text('👑', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
    } else if (isActive) {
      bg = const Color(0xFF3B82F6); // Active Blue
      content = Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypography.displayFamily,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      );
    } else if (isCompleted) {
      bg = const Color(0xFF22C55E); // Green completed
      content = const Icon(Icons.check_rounded, color: Colors.white, size: 20);
    } else {
      // Locked
      bg = isDark ? const Color(0xFF1E232F) : const Color(0xFFEFF6FF);
      content = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE68A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF171923), width: 1.2),
        ),
        child: const Icon(
          Icons.lock_rounded,
          size: 13,
          color: Color(0xFF171923),
        ),
      );
    }

    return PressableScale(
      onTap: onTap,
      child: Container(
        width: isBonus ? 74 : 52,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF171923), width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF171923),
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}

class _WavyLinePainter extends CustomPainter {
  const _WavyLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    const waveCount = 4;
    final waveWidth = size.width / waveCount;
    for (int i = 0; i < waveCount; i++) {
      final x1 = i * waveWidth + waveWidth / 4;
      final y1 = (i % 2 == 0) ? -2.0 : size.height + 2.0;
      final x2 = (i + 1) * waveWidth;
      final y2 = size.height / 2;
      path.quadraticBezierTo(x1, y1, x2, y2);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BubbleTrianglePainter extends CustomPainter {
  const _BubbleTrianglePainter({
    required this.color,
    required this.borderColor,
  });
  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTrianglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
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
          // ========================================================
          // HEADER ROW (Responsive, FittedBox to guarantee 0 overflow)
          // ========================================================
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // FEATURED ARENAS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD43B), // Neo Yellow
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF171923), width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: Color(0xFF171923),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'FEATURED ARENAS',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: Color(0xFF171923),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // GAME COUNT BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282E3E) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF171923), width: 1.6),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(1.2, 1.2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    '14 GAMES TOTAL',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.white : const Color(0xFF171923),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ========================================================
          // DESCRIPTION
          // ========================================================
          Text(
            'Play is how you master. Practice concepts with arcade action!',
            style: TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF171923),
                      width: 2.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF171923),
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF171923),
                                      offset: Offset(1, 1),
                                      blurRadius: 0,
                                    ),
                                  ],
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
                          padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                identity.type.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  color: isDark ? Colors.white : const Color(0xFF171923),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: identity.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: const Color(0xFF171923),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    identity.category.toUpperCase(),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppTypography.displayFamily,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: identity.accent,
                                    ),
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
          const SizedBox(height: 12),

          // ========================================================
          // EXPLORE ALL GAMES BUTTON (Comic Neo-Brutal with FittedBox to prevent any pixel error)
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
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF171923), width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF171923),
                    offset: Offset(2.2, 2.2),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ========================================================
          // XP INFORMATION (FittedBox to prevent overflow)
          // ========================================================
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, size: 13, color: Color(0xFFFFD43B)),
                  const SizedBox(width: 5),
                  Text(
                    'Quiz Battle & Speed Run award real XP',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
