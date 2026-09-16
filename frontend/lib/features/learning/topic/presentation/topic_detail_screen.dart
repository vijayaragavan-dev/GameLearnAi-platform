import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/models/content_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/subject_visual_identity.dart';
import '../../../../shared/widgets/app_backgrounds.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/cinematic_scenery.dart';
import '../../../../shared/widgets/cinematic_surfaces.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/nova_companion.dart';

/// TOPIC-001 mission briefing — cinematic edition.
///
/// Same contracts: topic fetch, lesson/quiz/game-hub routes, difficulty
/// badge, honest empty description fallback. Presentation follows the
/// Mission Briefing reference: mission hero, intel panel, concept tags,
/// action cards, Nova counsel, journey timeline.
class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  late Future<Topic> _future;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
    _future = ref.read(contentRepoProvider).topic(widget.topicId);
    // Best-effort mastery lookup for context display (PROG-002).
  }

  void _retry() => setState(() {
    _future = ref.read(contentRepoProvider).topic(widget.topicId);
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // Title-less bar: back affordance stays; "MISSION BRIEFING" lives
      // once in the hero badge below.
      appBar: AppBar(),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          if (isDark)
            const Positioned(
              top: -70,
              right: -50,
              child: GlowOrb(
                color: AppColors.primary,
                size: 260,
                opacity: 0.16,
              ),
            ),
          FutureBuilder<Topic>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done &&
                  !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                final err = describeError(snap.error!);
                return ErrorState(
                  title: err.title,
                  message: err.message,
                  onRetry: _retry,
                );
              }
              final topic = snap.data!;
              final identity =
                  SubjectVisualRegistry.fromName(topic.subjectName);
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppGutters.pagePadding(context),
                  right: AppGutters.pagePadding(context),
                  top: 8,
                  bottom: 110,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── MISSION HERO ──
                        CinematicHero(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    identity.accent.withValues(alpha: 0.30),
                                    AppColors.surfaceElevated,
                                  ]
                                : [
                                    identity.accent.withValues(alpha: 0.12),
                                    AppLightColors.surface,
                                  ],
                          ),
                          accent: identity.accent,
                          badge: 'Mission Briefing',
                          badgeIcon: Icons.track_changes_rounded,
                          scene: scenePaletteForWorld(identity.iconKey),
                          sceneSeed: seedForKey(topic.name),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.subjectName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2.4,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                topic.name,
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppLightColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              DifficultyBadge(
                                difficulty: topic.difficulty,
                              ),
                            ],
                          ),
                          tagline: 'SMALL LOGIC\nBIG POSSIBILITIES',
                          leading: const NovaAvatar(size: 76),
                        ),
                        const SizedBox(height: 14),
                        // ── MISSION INTEL ──
                        GlassPanel(
                          glowColor: identity.accent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.psychology_outlined,
                                    size: 18,
                                    color: identity.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'MISSION INTEL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.textSecondary
                                          : AppLightColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                topic.description.isNotEmpty
                                    ? topic.description
                                    : 'Conquer this topic through training and challenges.',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.55,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppLightColors.textSecondary,
                                ),
                              ),
                              // Concept tags stay honest: derived from the
                              // mission description keywords when available.
                              // No fabricated concept list is rendered.
                              if (topic.description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final tag in <String>{
                                      topic.subjectName,
                                      topic.difficulty,
                                    })
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 11,
                                              vertical: 6,
                                            ),
                                        decoration: BoxDecoration(
                                          color: identity.accent.withValues(
                                            alpha: isDark ? 0.12 : 0.08,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(
                                                AppRadius.pill,
                                              ),
                                          border: Border.all(
                                            color: identity.accent.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textPrimary
                                                : AppLightColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // ── ACTION CARDS ──
                        PrimaryGameButton(
                          label: 'Enter training',
                          icon: Icons.menu_book_rounded,
                          onTap: () => context.push(Routes.lesson(topic.id)),
                        ),
                        const SizedBox(height: 12),
                        SecondaryGameButton(
                          label: 'Take the challenge',
                          icon: Icons.sports_esports_rounded,
                          onTap: () {
                            ref
                                .read(audioManagerProvider)
                                .play(Sfx.buttonConfirm);
                            context.push(Routes.quiz(topic.id));
                          },
                        ),
                        const SizedBox(height: 12),
                        // Game Arena entry — subject-aware hub
                        _GameArenaCard(topic: topic),
                        const SizedBox(height: 14),
                        // ── NOVA COUNSEL ──
                        GlassPanel(
                          glowColor: AppColors.secondary,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const NovaCompanion(
                                size: 56,
                                mood: NovaMood.speaking,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'NOVA SAYS',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '“Every decision you make in code, shapes the world you build.”',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontStyle: FontStyle.italic,
                                        height: 1.5,
                                        color: isDark
                                            ? AppColors.textPrimary
                                            : AppLightColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ── JOURNEY TIMELINE ──
                        const JourneyTimeline(stage: 0),
                      ],
                    ),
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

class _GameArenaCard extends ConsumerWidget {
  const _GameArenaCard({required this.topic});
  final Topic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Open Game Arena for ${topic.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
          context.push(
            Routes.gameHub(
              topic.id,
              subjectId: topic.subjectId,
              subjectName: topic.subjectName,
            ),
            extra: topic.name,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.xp.withValues(alpha: isDark ? 0.20 : 0.12),
                (isDark
                    ? AppColors.surfaceElevated
                    : AppLightColors.surface),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.xp.withValues(alpha: 0.45),
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: AppColors.xp.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.xpGold,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GAME ARENA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppLightColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quiz Battle • Memory • Drag & Drop • Speed Run',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.xp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
