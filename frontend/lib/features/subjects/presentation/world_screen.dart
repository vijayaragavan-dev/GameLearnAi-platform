import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/models/content_models.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/subject_visual_identity.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../learning/path/providers/path_provider.dart';
import '../domain/canonical_worlds.dart';
import '../domain/world_context.dart';
import '../domain/world_syllabus.dart';

/// WORLD LANDING — the genuine world experience behind "CHOOSE YOUR WORLD".
///
/// One backend subject ([subjectId]) rendered through its canonical
/// [WorldDefinition]: identity hero, backend-driven progress (PATH-001
/// nodes), static syllabus outline where available, world-scoped CTAs
/// (Continue → Topic, Arena → GameHub with subject context, Tutor with
/// subject/topic context), world-filtered mastery/activity, global level +
/// achievements labeled honestly as global.
///
/// Rules: no fabricated syllabus, no fake percentages, unknown worlds fall
/// back to generic presentation (never throws). Static syllabus defines
/// identity/order only — taps navigate solely via backend topicIds.
class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key, required this.subjectId, this.subjectName = ''});

  final String subjectId;
  final String subjectName;

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
    Future.microtask(() {
      if (mounted) ref.read(pathProvider(widget.subjectId).notifier).load();
    });
  }

  Future<void> _reload() async {
    await ref.read(pathProvider(widget.subjectId).notifier).load();
  }

  void _openTopic(PathNode node, String subjectName) {
    ref.read(hapticsProvider).select();
    context.push(Routes.topic(node.topicId));
  }

  void _openArena(PathNode? node, String subjectId, String subjectName) {
    if (node == null) return;
    ref.read(audioManagerProvider).play(Sfx.nodeUnlock);
    context.push(
      Routes.gameHub(node.topicId, subjectId: subjectId, subjectName: subjectName),
      extra: node.topicName,
    );
  }

  void _openTutor({String? topicId, String? topicName}) {
    ref.read(hapticsProvider).select();
    context.push(
      Routes.tutorWithContext(
        subjectId: widget.subjectId,
        topicId: topicId,
        topicName: topicName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = ref.watch(subjectByIdProvider(widget.subjectId));
    final displayName = subject?.name ??
        (widget.subjectName.isNotEmpty ? widget.subjectName : 'World');
    final description = subject?.description ?? '';
    final definition = subject != null
        ? WorldCatalog.resolveSubject(subject)
        : WorldCatalog.resolveDisplayName(displayName);
    final identity = definition != null
        ? SubjectVisualRegistry.fromIconKey(definition.iconKeys.first)
        : SubjectVisualRegistry.fromName(displayName);
    final accent = identity.accent;

    final pathState = ref.watch(pathProvider(widget.subjectId));
    final activePath = pathState.activePath;
    final nodes = activePath?.nodes ?? const <PathNode>[];
    final nodeIds = nodes.map((n) => n.topicId).toSet();
    final current = _currentNode(nodes);
    final recommended = _recommendedNode(nodes);
    final dashboard = ref.watch(dashboardProvider).data;

    return Scaffold(
      appBar: AppBar(
        title: Text('${displayName.toUpperCase()} WORLD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to worlds',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.subjects),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBright,
        backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
        onRefresh: _reload,
        child: Stack(
          children: [
            const Positioned.fill(child: AtmosphericBackground()),
            Positioned(
              top: -60,
              right: -40,
              child: IgnorePointer(
                child: GlowOrb(
                  color: accent,
                  size: 280,
                  opacity: isDark ? 0.10 : 0.04,
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveCenter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WorldHero(
                        displayName: displayName,
                        description: description.isEmpty
                            ? (definition?.description ??
                                'Enter the $displayName world and forge your path')
                            : description,
                        tagline: definition?.tagline,
                        identity: identity,
                        accent: accent,
                        availability: definition?.availability,
                      ),
                      const SizedBox(height: 18),
                      _ContinueSection(
                        loading: pathState.showLoading,
                        error: pathState.error,
                        nodes: nodes,
                        current: current,
                        recommended: recommended,
                        generating: pathState.generating,
                        onRetry: _reload,
                        onOpenTopic: (n) => _openTopic(n, displayName),
                        onOpenPath: () => context.push(
                          '${Routes.path(widget.subjectId)}?name=${Uri.encodeComponent(displayName)}',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ArenaSection(
                        accent: accent,
                        displayName: displayName,
                        hasTopic: recommended != null,
                        onEnter: () => _openArena(
                          recommended,
                          widget.subjectId,
                          displayName,
                        ),
                        onTutor: () => _openTutor(
                          topicId: current?.topicId,
                          topicName: current?.topicName,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SyllabusSection(
                        definition: definition,
                        nodes: nodes,
                        onOpenTopic: (n) => _openTopic(n, displayName),
                      ),
                      const SizedBox(height: 18),
                      _MasterySection(
                        dashboard: dashboard,
                        nodeIds: nodeIds,
                        displayName: displayName,
                      ),
                      const SizedBox(height: 18),
                      _ActivitySection(
                        dashboard: dashboard,
                        nodeIds: nodeIds,
                        accent: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

PathNode? _currentNode(List<PathNode> nodes) {
  for (final n in nodes) {
    if (n.status == 'IN_PROGRESS') return n;
  }
  for (final n in nodes) {
    if (n.status == 'AVAILABLE') return n;
  }
  return null;
}

PathNode? _recommendedNode(List<PathNode> nodes) {
  for (final n in nodes) {
    if (n.status == 'AVAILABLE') return n;
  }
  for (final n in nodes) {
    if (n.status == 'IN_PROGRESS') return n;
  }
  return null;
}

// ── HERO ────────────────────────────────────────────────────────────────

class _WorldHero extends StatelessWidget {
  const _WorldHero({
    required this.displayName,
    required this.description,
    required this.tagline,
    required this.identity,
    required this.accent,
    required this.availability,
  });

  final String displayName;
  final String description;
  final String? tagline;
  final SubjectVisualIdentity identity;
  final Color accent;
  final WorldAvailability? availability;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '$displayName world',
      child: FeaturedSurface(
        accent: accent,
        padding: EdgeInsets.zero,
        scene: scenePaletteForWorld(identity.iconKey),
        sceneSeed: seedForKey(displayName),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [accent.withValues(alpha: 0.22), Colors.transparent]
                        : [accent.withValues(alpha: 0.08), Colors.transparent],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SubjectIcon(iconKey: identity.iconKey, size: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTypography.hero(context, size: 22),
                            ),
                            if (tagline != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                tagline!,
                                style: AppTypography.caption(context).copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: AppTypography.bodySecondary(context),
                  ),
                  if (availability == WorldAvailability.comingSoon) ...[
                    const SizedBox(height: 10),
                    const _Pill(
                      label: 'WORLD PREPARATION IN PROGRESS',
                      color: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CONTINUE / PROGRESS (backend-driven, never fabricated) ───────────────

class _ContinueSection extends StatelessWidget {
  const _ContinueSection({
    required this.loading,
    required this.error,
    required this.nodes,
    required this.current,
    required this.recommended,
    required this.generating,
    required this.onRetry,
    required this.onOpenTopic,
    required this.onOpenPath,
  });

  final bool loading;
  final String? error;
  final List<PathNode> nodes;
  final PathNode? current;
  final PathNode? recommended;
  final bool generating;
  final VoidCallback onRetry;
  final ValueChanged<PathNode> onOpenTopic;
  final VoidCallback onOpenPath;

  @override
  Widget build(BuildContext context) {
    // Promote once for closure-safe access below.
    final PathNode? next = recommended;
    final PathNode? inProgress = current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTINUE LEARNING', style: AppTypography.overline(context)),
        const SizedBox(height: 8),
        if (loading)
          const SkeletonList(itemCount: 2, itemHeight: 72)
        else if (error != null)
          ErrorState(title: 'Path unavailable', message: error!, onRetry: onRetry)
        else if (nodes.isEmpty)
          EmptyState(
            icon: Icons.route_outlined,
            title: 'No learning path yet',
            message:
                'Generate your personalized path to unlock topics, games and recommendations for this world.',
            action: PrimaryGameButton(
              label: generating ? 'Generating…' : 'View path',
              onTap: generating ? null : onOpenPath,
              busy: generating,
            ),
          )
        else ...[
          _NodeProgressRow(nodes: nodes),
          const SizedBox(height: 10),
          if (next != null)
            GameIdentitySurface(
              accent: AppColors.success,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const NovaCompanion(size: 40, mood: NovaMood.encouraging),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NEXT UP', style: AppTypography.overline(context)),
                        const SizedBox(height: 2),
                        Text(
                          next.topicName,
                          style: AppTypography.h3(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _statusLabel(next.status),
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              final continueBtn = PrimaryGameButton(
                label: next != null ? 'Continue' : 'Open path',
                icon: Icons.play_arrow_rounded,
                onTap: next != null
                    ? () => onOpenTopic(next)
                    : onOpenPath,
              );
              final pathBtn = SecondaryGameButton(
                label: 'Full path',
                onTap: onOpenPath,
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [continueBtn, const SizedBox(height: 8), pathBtn],
                );
              }
              return Row(
                children: [
                  Expanded(child: continueBtn),
                  const SizedBox(width: 10),
                  Expanded(child: pathBtn),
                ],
              );
            },
          ),
          if (inProgress != null && inProgress != next) ...[
            const SizedBox(height: 8),
            Text(
              'In progress: ${inProgress.topicName}',
              style: AppTypography.caption(context),
            ),
          ],
        ],
      ],
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'IN_PROGRESS' => 'In progress — pick up where you left off',
      'AVAILABLE' => 'Available — ready to start',
      'COMPLETED' => 'Completed — review anytime',
      _ => 'Locked — complete earlier topics first',
    };

class _NodeProgressRow extends StatelessWidget {
  const _NodeProgressRow({required this.nodes});
  final List<PathNode> nodes;

  @override
  Widget build(BuildContext context) {
    final done = nodes.where((n) => n.status == 'COMPLETED').length;
    final active =
        nodes.where((n) => n.status == 'AVAILABLE' || n.status == 'IN_PROGRESS').length;
    final locked = nodes.length - done - active;
    return Semantics(
      label:
          '${nodes.length} path topics, $done completed, $active available, $locked locked',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Pill(label: '$done DONE', color: AppColors.success),
          _Pill(label: '$active OPEN', color: AppColors.secondary),
          _Pill(label: '$locked LOCKED', color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

// ── WORLD ARENA + TUTOR ─────────────────────────────────────────────────

class _ArenaSection extends StatelessWidget {
  const _ArenaSection({
    required this.accent,
    required this.displayName,
    required this.hasTopic,
    required this.onEnter,
    required this.onTutor,
  });

  final Color accent;
  final String displayName;
  final bool hasTopic;
  final VoidCallback onEnter;
  final VoidCallback onTutor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WORLD ARENA', style: AppTypography.overline(context)),
        const SizedBox(height: 8),
        GameIdentitySurface(
          accent: accent,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  '$displayName // WORLD ARENA',
                  style: AppTypography.h3(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasTopic
                    ? 'Every game here plays $displayName content only.'
                    : 'The arena unlocks once your path has a topic.',
                style: AppTypography.caption(context),
              ),
              const SizedBox(height: 12),
              PrimaryGameButton(
                label: 'Enter game arena',
                icon: Icons.sports_esports_rounded,
                color: accent,
                onTap: hasTopic ? onEnter : null,
              ),
              const SizedBox(height: 8),
              SecondaryGameButton(
                label: 'Ask Nova tutor',
                icon: Icons.psychology_outlined,
                onTap: onTutor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── SYLLABUS (static outline + backend taps) ────────────────────────────

class _SyllabusSection extends StatelessWidget {
  const _SyllabusSection({
    required this.definition,
    required this.nodes,
    required this.onOpenTopic,
  });

  final WorldDefinition? definition;
  final List<PathNode> nodes;
  final ValueChanged<PathNode> onOpenTopic;

  @override
  Widget build(BuildContext context) {
    final worldId = definition?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SYLLABUS', style: AppTypography.overline(context)),
        const SizedBox(height: 8),
        if (worldId == null)
          const EmptyMiniCard(
            text: 'Syllabus appears once this world is mapped.',
          )
        else if (WorldSyllabusCatalog.of(worldId).isPending)
          const EmptyState(
            icon: Icons.hourglass_empty_rounded,
            title: 'Content arriving',
            message:
                'This world exists, but its syllabus is still being prepared. Your path and arena unlock with backend content.',
          )
        else if (definition?.syllabusSource == SyllabusSource.backend)
          _BackendSyllabus(nodes: nodes, onOpenTopic: onOpenTopic)
        else
          _StaticSyllabus(
            syllabus: WorldSyllabusCatalog.of(worldId),
            nodes: nodes,
            onOpenTopic: onOpenTopic,
          ),
      ],
    );
  }
}

class _BackendSyllabus extends StatelessWidget {
  const _BackendSyllabus({required this.nodes, required this.onOpenTopic});
  final List<PathNode> nodes;
  final ValueChanged<PathNode> onOpenTopic;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const EmptyMiniCard(
        text: 'Topics appear here once your path is generated.',
      );
    }
    return Column(
      children: [
        for (final n in nodes)
          _TopicRow(node: n, onTap: () => onOpenTopic(n)),
      ],
    );
  }
}

class _StaticSyllabus extends StatelessWidget {
  const _StaticSyllabus({
    required this.syllabus,
    required this.nodes,
    required this.onOpenTopic,
  });

  final WorldSyllabus syllabus;
  final List<PathNode> nodes;
  final ValueChanged<PathNode> onOpenTopic;

  PathNode? _match(String title) {
    final lower = title.toLowerCase().trim();
    for (final n in nodes) {
      if (n.topicName.toLowerCase().trim() == lower) return n;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final units = syllabus.orderedUnits();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final unit in units) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Text(
              'UNIT ${unit.unitNumber} • ${unit.title.toUpperCase()}',
              style: AppTypography.label(context),
            ),
          ),
          for (final topic in unit.topics)
            _StaticTopicRow(
              title: topic.title,
              node: _match(topic.title),
              onOpenTopic: onOpenTopic,
            ),
        ],
      ],
    );
  }
}

class _StaticTopicRow extends StatelessWidget {
  const _StaticTopicRow({
    required this.title,
    required this.node,
    required this.onOpenTopic,
  });

  final String title;
  final PathNode? node;
  final ValueChanged<PathNode> onOpenTopic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final match = node;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: match == null ? null : () => onOpenTopic(match),
        child: Semantics(
          button: match != null,
          label: match != null
              ? '$title, ${match.status.toLowerCase()}, tap to open'
              : '$title, syllabus outline',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark ? AppColors.border : AppLightColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTypography.body(context)),
                ),
                if (match != null) ...[
                  _StatusDot(status: match.status),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.node, required this.onTap});
  final PathNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '${node.topicName}, ${node.status.toLowerCase()}, tap to open',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark ? AppColors.border : AppLightColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    node.topicName,
                    style: AppTypography.body(context),
                  ),
                ),
                _StatusDot(status: node.status),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'COMPLETED' => AppColors.success,
      'IN_PROGRESS' => AppColors.warning,
      'AVAILABLE' => AppColors.secondary,
      _ => AppColors.locked,
    };
    return Semantics(
      label: 'Status $status',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// ── WORLD MASTERY (filtered by this world's backend topics) ─────────────

class _MasterySection extends StatelessWidget {
  const _MasterySection({
    required this.dashboard,
    required this.nodeIds,
    required this.displayName,
  });

  final Dashboard? dashboard;
  final Set<String> nodeIds;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final topics = (dashboard?.mastery.recentTopics ?? const [])
        .where((t) => nodeIds.contains(t.topicId))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WORLD MASTERY', style: AppTypography.overline(context)),
        const SizedBox(height: 8),
        if (dashboard == null)
          const EmptyMiniCard(text: 'Mastery unavailable right now.')
        else if (topics.isEmpty)
          const EmptyMiniCard(
            text: 'No mastery data for this world yet. Play or take the scan.',
          )
        else
          Column(
            children: [
              for (final t in topics.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.topicName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(context),
                        ),
                      ),
                      Text(
                        '${t.masteryScore.toStringAsFixed(0)}%',
                        style: AppTypography.monoNumber(context, size: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ── RECENT ACTIVITY (world-filtered) + GLOBAL LEVEL ─────────────────────

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.dashboard,
    required this.nodeIds,
    required this.accent,
  });

  final Dashboard? dashboard;
  final Set<String> nodeIds;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final quizzes = (dashboard?.recentActivity.quizzes ?? const [])
        .where((q) => nodeIds.contains(q.topicId))
        .take(3)
        .toList();
    final gamification = dashboard?.gamification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROGRESS & ACTIVITY', style: AppTypography.overline(context)),
        const SizedBox(height: 8),
        if (gamification != null)
          Semantics(
            label:
                'Level ${gamification.currentLevel}, ${gamification.totalXp} total XP across all worlds',
            child: GameIdentitySurface(
              accent: AppColors.xp,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 22, color: AppColors.xp),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Level ${gamification.currentLevel} • ${gamification.totalXp} XP',
                      style: AppTypography.h3(context),
                    ),
                  ),
                  Text(
                    'ALL WORLDS',
                    style: AppTypography.caption(context),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        if (quizzes.isEmpty)
          const EmptyMiniCard(
            text: 'No recent world activity. Your games and quizzes show here.',
          )
        else
          Column(
            children: [
              for (final q in quizzes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          q.topicName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(context),
                        ),
                      ),
                      Text(
                        '${q.correctCount}/${q.totalQuestions}',
                        style: AppTypography.monoNumber(context, size: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ── SHARED BITS ─────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: AppTypography.badgeLabel(context, color: color),
      ),
    );
  }
}
