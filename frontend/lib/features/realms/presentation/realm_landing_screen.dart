import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/content_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../game_engine/providers/game_content_providers.dart';
import '../data/realm_models.dart';

/// Generic realm landing — one screen for every non-CS realm identity.
///
/// Resolves `realmKey` against the backend contract (`GET
/// /api/v1/realms/{key}` + `/subjects`), then renders that realm's
/// subject experience with existing flows only: learning path
/// (forge + traverse), game compatibility (backend truth), tutor
/// with subject context. Computer Science keys redirect to the
/// existing world flow. Unknown/inactive keys render honest states —
/// never fabricated content, never wrong-realm substitution.
class RealmLandingScreen extends ConsumerStatefulWidget {
  const RealmLandingScreen({super.key, required this.realmKey});

  final String realmKey;

  @override
  ConsumerState<RealmLandingScreen> createState() =>
      _RealmLandingScreenState();
}

class _RealmLandingScreenState extends ConsumerState<RealmLandingScreen> {
  late Future<({BackendRealm realm, List<Subject> subjects})> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant RealmLandingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Same route, different realm (e.g. /realm/APTITUDE → /realm/NOPE):
    // refetch instead of showing stale content.
    if (oldWidget.realmKey != widget.realmKey) _reload();
  }

  void _reload() => setState(() {
    final repo = ref.read(realmRepoProvider);
    _future = () async {
      final realm = await repo.realm(widget.realmKey);
      final subjects = await repo.subjectsForRealm(widget.realmKey);
      return (realm: realm, subjects: subjects);
    }();
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('REALM')),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          if (isDark)
            const Positioned(
              top: -60,
              right: -40,
              child: GlowOrb(
                color: AppColors.primary,
                size: 240,
                opacity: 0.10,
              ),
            ),
          SafeArea(
            top: true,
            bottom: true,
            child: FutureBuilder<({BackendRealm realm, List<Subject> subjects})>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done &&
                    !snap.hasData) {
                  return const CinematicLoading(
                    message: 'Opening realm...',
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
                final realm = snap.data!.realm;
                final subjects = snap.data!.subjects;
                // Computer Science always resolves into the existing
                // world flow — never duplicated here.
                final resolved = ResolvedRealm.resolve(realm);
                if (resolved.isWorldBased) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) context.go(Routes.subjects);
                  });
                  return const CinematicLoading(
                    message: 'Entering worlds...',
                  );
                }
                if (subjects.isEmpty) {
                  return EmptyState(
                    icon: Icons.hourglass_empty_rounded,
                    title: '${realm.name} is preparing',
                    message:
                        'This realm has no subjects yet. Check back soon — '
                        'nothing is tracked until real content arrives.',
                    action: SecondaryGameButton(
                      label: 'Back to realms',
                      icon: Icons.public_rounded,
                      expanded: false,
                      onTap: () => context.go(Routes.realms),
                    ),
                  );
                }
                // One subject per realm today; the first active subject
                // leads. Additional subjects render as switcher chips.
                final subject = subjects.first;
                return _SubjectExperience(
                  realm: realm,
                  resolved: resolved,
                  subject: subject,
                  subjects: subjects,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Subject experience inside a non-CS realm: hero, backend compat
/// strip, learning-path entry, tutor entry. Every value is backend
/// data; every CTA reuses an existing route.
class _SubjectExperience extends ConsumerWidget {
  const _SubjectExperience({
    required this.realm,
    required this.resolved,
    required this.subject,
    required this.subjects,
  });

  final BackendRealm realm;
  final ResolvedRealm resolved;
  final Subject subject;
  final List<Subject> subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compat = ref.watch(subjectGamesProvider(subject.id));
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveCenter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppGutters.pagePadding(context),
            8,
            AppGutters.pagePadding(context),
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CinematicHero(
                accent: resolved.accent,
                badge: realm.name,
                badgeIcon: resolved.icon,
                scene: resolved.scene,
                sceneSeed: seedForKey(realm.realmKey),
                title: Text(
                  subject.name.toUpperCase(),
                  style: AppTypography.hero(context, size: 24),
                ),
                subtitle: Text(
                  subject.description.isNotEmpty
                      ? subject.description
                      : 'Learn, play and master ${subject.name}.',
                  style: AppTypography.bodySecondary(context),
                ),
                tagline: 'LEARN • PLAY\nMASTER • GROW',
              ),
              const SizedBox(height: 14),
              // ── GAME COMPATIBILITY (backend truth) ──
              GameChallengeSurface(
                accent: resolved.accent,
                title: 'PLAYABLE GAMES',
                icon: Icons.sports_esports_rounded,
                subtitle: 'verified',
                child: compat.when(
                  loading: () => const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      // Flexible (loose fit): identical when the label
                      // fits; ellipsizes instead of overflowing narrow
                      // rows, large text scales or wide test fonts.
                      Flexible(
                        child: Text(
                          'Checking game support...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  error: (e, _) => EmptyMiniCard(
                    text:
                        'Game support is unavailable right now. ${describeError(e).message}',
                  ),
                  data: (games) {
                    final playable = games.games
                        .where((g) => g.hasContent)
                        .toList(growable: false);
                    if (playable.isEmpty) {
                      return const EmptyMiniCard(
                        text:
                            'No games are enabled for this subject yet. '
                            'Complete lessons and check back — availability '
                            'comes from the backend, never assumed.',
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in playable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(
                                alpha: isDark ? 0.12 : 0.08,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: AppColors.success.withValues(
                                  alpha: 0.40,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    '${g.gameType} • ${g.contentCount}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              // ── SKILLS & TOPICS (backend learning-path nodes) ──
              // Topics surface only through the learner's real path:
              // no path yet → forge prompt; path → node list in backend
              // sequence order. Identities (incl. "Number Series" vs
              // "Number Series (LR)") come from backend topicIds — the
              // UI never merges or renames them.
              _SubjectTopics(subject: subject, accent: resolved.accent),
              const SizedBox(height: 14),
              // ── LEARNING PATH (existing flow, per-subject UUID) ──
              GameChallengeSurface(
                accent: AppColors.primary,
                title: 'LEARNING PATH',
                icon: Icons.route_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forge a personalized path through ${subject.name} — '
                      'topics unlock as missions, exactly like every world.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppLightColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryGameButton(
                      label: 'Open learning path',
                      icon: Icons.auto_awesome_rounded,
                      onTap: () =>
                          context.push(Routes.path(subject.id)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SecondaryGameButton(
                label: 'Ask Nova Tutor',
                icon: Icons.psychology_rounded,
                onTap: () => context.push(
                  Routes.tutorWithContext(
                    subjectId: subject.id,
                    focus: subject.name,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skills & topics for a realm subject, sourced exclusively from the
/// learner's real learning path (`activePathForSubject`). No path →
/// honest forge prompt; path → backend-ordered node list navigating
/// by backend topicId. No fabricated topic list, no name-based IDs.
class _SubjectTopics extends ConsumerStatefulWidget {
  const _SubjectTopics({required this.subject, required this.accent});

  final Subject subject;
  final Color accent;

  @override
  ConsumerState<_SubjectTopics> createState() => _SubjectTopicsState();
}

class _SubjectTopicsState extends ConsumerState<_SubjectTopics> {
  late Future<LearningPath?> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(contentRepoProvider).activePathForSubject(
      widget.subject.id,
    );
  }

  void _retry() => setState(() {
    _future = ref.read(contentRepoProvider).activePathForSubject(
      widget.subject.id,
    );
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GameChallengeSurface(
      accent: widget.accent,
      title: 'SKILLS & TOPICS',
      icon: Icons.list_alt_rounded,
      child: FutureBuilder<LearningPath?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done &&
              !snap.hasData) {
            return const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Loading topics...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }
          if (snap.hasError) {
            final err = describeError(snap.error!);
            return EmptyMiniCard(
              text: 'Topics are unavailable right now. ${err.message}',
              action: GameChip(
                label: 'RETRY',
                icon: Icons.refresh_rounded,
                color: widget.accent,
                onTap: _retry,
              ),
            );
          }
          final nodes = snap.data?.nodes ?? const <PathNode>[];
          if (nodes.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No learning path forged yet — forge one to reveal '
                  '${widget.subject.name} topics as missions.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryGameButton(
                  label: 'Forge learning path',
                  icon: Icons.auto_awesome_rounded,
                  onTap: () =>
                      context.push(Routes.path(widget.subject.id)),
                ),
              ],
            );
          }
          return Column(
            children: [
              for (final node in nodes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Pressable(
                    onTap: () =>
                        context.push(Routes.topic(node.topicId)),
                    semanticsLabel:
                        'Open topic ${node.topicName}, ${node.status}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isDark
                              ? AppColors.border
                              : AppLightColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.accent.withValues(
                                alpha: isDark ? 0.14 : 0.10,
                              ),
                              border: Border.all(
                                color: widget.accent.withValues(
                                  alpha: 0.40,
                                ),
                              ),
                            ),
                            child: Text(
                              '${node.sequenceNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: widget.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node.topicName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppLightColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  node.status,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.textTertiary
                                : AppLightColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
