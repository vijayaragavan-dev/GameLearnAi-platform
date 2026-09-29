import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/models/content_models.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../../../core/theme/subject_visual_identity.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
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
/// Presentation: comic neo-brutalist — thick ink outlines, hard offset
/// shadows, saturated accent tiles and the shared display/body type scale
/// (same language as the dashboard and world catalog).
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

// ── COMIC TOKENS (shared with the dashboard / world catalog) ──────────────

const Color _comicInk = Color(0xFF171923);
const Color _comicPaper = Color(0xFFFFFFFF);
const Color _comicCardDark = Color(0xFF1E232F);
const Color _comicInsetDark = Color(0xFF151921);
const Color _comicCanvas = Color(0xFFF7F5EF);
const Color _comicSlate = Color(0xFF596174);
const Color _comicGameYellow = Color(0xFFFFD43B);

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
    final rawName = widget.subjectName.trim();
    final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(rawName);
    final safeWidgetName = (isUuid || rawName.isEmpty) ? '' : rawName;
    final displayName = subject?.name ??
        (safeWidgetName.isNotEmpty ? safeWidgetName : 'World');
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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _comicInk, width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(identity.icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                '${displayName.toUpperCase()} WORLD',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white : _comicInk,
                ),
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.push(Routes.subjects),
              child: Ink(
                decoration: BoxDecoration(
                  color: isDark ? _comicCardDark : _comicGameYellow,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _comicInk, width: 2.2),
                  boxShadow: NeoBrutalShadows.hardXs,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: isDark ? Colors.white : _comicInk,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBright,
        backgroundColor: isDark ? AppColors.surfaceElevated : _comicPaper,
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      _SyllabusSection(
                        definition: definition,
                        nodes: nodes,
                        onOpenTopic: (n) => _openTopic(n, displayName),
                      ),
                      const SizedBox(height: 20),
                      _MasterySection(
                        dashboard: dashboard,
                        nodeIds: nodeIds,
                        displayName: displayName,
                      ),
                      const SizedBox(height: 20),
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

// ── COMIC PRIMITIVES ──────────────────────────────────────────────────────

/// Thick-ink outlined card — the shared comic surface.
class _ComicCard extends StatelessWidget {
  const _ComicCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? _comicCardDark : _comicPaper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _comicInk, width: 2.5),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: child,
    );
  }
}

/// Recessed inner panel used for metadata rows inside a comic card.
class _ComicInset extends StatelessWidget {
  const _ComicInset({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.radius = 10,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? _comicInsetDark : _comicCanvas,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _comicInk, width: 1.5),
      ),
      child: child,
    );
  }
}

/// Section header — accent icon tile + uppercase display title + badge.
class _ComicHeader extends StatelessWidget {
  const _ComicHeader({
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
              border: Border.all(color: _comicInk, width: 2),
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
                color: isDark ? Colors.white : _comicInk,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? _comicInsetDark : _comicCanvas,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _comicInk, width: 1.5),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: _comicInk,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Flat pastel status chip with ink outline.
class _ComicPill extends StatelessWidget {
  const _ComicPill({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _comicInk, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comic CTA — chunky ink-outlined button with press-scale feedback.
enum _ComicButtonStyle { primary, secondary, accent }

class _ComicButton extends StatelessWidget {
  const _ComicButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.style = _ComicButtonStyle.primary,
    this.fill,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final _ComicButtonStyle style;
  final Color? fill;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onTap != null && !busy;

    Color background;
    Color foreground;
    switch (style) {
      case _ComicButtonStyle.primary:
        background = _comicGameYellow;
        foreground = _comicInk;
      case _ComicButtonStyle.secondary:
        background = isDark ? _comicCardDark : _comicPaper;
        foreground = isDark ? Colors.white : _comicInk;
      case _ComicButtonStyle.accent:
        background = fill ?? AppColors.primary;
        foreground = Colors.white;
    }
    if (!enabled) {
      background = isDark ? const Color(0xFF2A3140) : const Color(0xFFEFECE3);
      foreground = isDark ? const Color(0xFF6B7488) : const Color(0xFF9AA1AF);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.75,
      child: PressableScale(
        onTap: enabled ? onTap : null,
        enabled: enabled,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _comicInk, width: 2.5),
            boxShadow: enabled ? NeoBrutalShadows.hardSm : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: foreground,
                  ),
                )
              else ...[
                if (icon != null) ...[
                  Icon(icon, size: 19, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── HERO ──────────────────────────────────────────────────────────────────

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
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? _comicCardDark : _comicPaper,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _comicInk, width: 3),
          boxShadow: NeoBrutalShadows.hard,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Accent banner across the top of the hero.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 9,
              child: ColoredBox(color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _comicInk, width: 2.5),
                          boxShadow: NeoBrutalShadows.hardXs,
                        ),
                        alignment: Alignment.center,
                        child: Icon(identity.icon, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                color: isDark ? Colors.white : _comicInk,
                              ),
                            ),
                            if (tagline != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                tagline!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: accent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ComicInset(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    radius: 12,
                    child: Text(
                      description,
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : _comicSlate,
                      ),
                    ),
                  ),
                  if (availability == WorldAvailability.comingSoon) ...[
                    const SizedBox(height: 12),
                    const _ComicPill(
                      label: 'WORLD PREPARATION IN PROGRESS',
                      foreground: Color(0xFFB45309),
                      background: Color(0xFFFEF3C7),
                      icon: Icons.hourglass_empty_rounded,
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
        _ComicHeader(
          title: 'Continue learning',
          icon: Icons.play_circle_outline_rounded,
          accent: AppColors.primary,
          badge: nodes.isEmpty ? null : '${nodes.length} TOPICS',
        ),
        if (loading)
          const SkeletonList(itemCount: 2, itemHeight: 72)
        else if (error != null)
          ErrorState(title: 'Path unavailable', message: error!, onRetry: onRetry)
        else if (nodes.isEmpty)
          _NoPathCard(generating: generating, onOpenPath: onOpenPath)
        else ...[
          _ProgressBlock(nodes: nodes),
          const SizedBox(height: 12),
          if (next != null) _NextUpCard(node: next),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              final continueBtn = _ComicButton(
                label: next != null ? 'Continue' : 'Open path',
                icon: Icons.play_arrow_rounded,
                onTap: next != null ? () => onOpenTopic(next) : onOpenPath,
              );
              final pathBtn = _ComicButton(
                label: 'Full path',
                icon: Icons.map_rounded,
                style: _ComicButtonStyle.secondary,
                onTap: onOpenPath,
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [continueBtn, const SizedBox(height: 10), pathBtn],
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
            const SizedBox(height: 10),
            _ComicInset(
              child: Row(
                children: [
                  const Icon(
                    Icons.timelapse_rounded,
                    size: 15,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'In progress: ${inProgress.topicName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _comicSlate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _NoPathCard extends StatelessWidget {
  const _NoPathCard({required this.generating, required this.onOpenPath});

  final bool generating;
  final VoidCallback onOpenPath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ComicCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _comicInk, width: 2.5),
              boxShadow: NeoBrutalShadows.hardXs,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.route_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No learning path yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : _comicInk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate your personalized path to unlock topics and games for this world.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : _comicSlate,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: SizedBox(
              width: double.infinity,
              child: _ComicButton(
                label: generating ? 'Generating…' : 'View path',
                icon: Icons.map_rounded,
                busy: generating,
                onTap: generating ? null : onOpenPath,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Backend-derived completion bar + status chips for this world's path.
class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.nodes});

  final List<PathNode> nodes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = nodes.where((n) => n.status == 'COMPLETED').length;
    final active =
        nodes.where((n) => n.status == 'AVAILABLE' || n.status == 'IN_PROGRESS').length;
    final locked = nodes.length - done - active;
    final progress = nodes.isEmpty ? 0.0 : done / nodes.length;

    return _ComicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(progress * 100).round()}% COMPLETED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$done of ${nodes.length} finished',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _comicSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label:
                '${nodes.length} path topics, $done completed, $active available, $locked locked',
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? _comicInsetDark : _comicCanvas,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _comicInk, width: 2),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ComicPill(
                label: '$done DONE',
                foreground: const Color(0xFF047857),
                background: const Color(0xFFD1FAE5),
                icon: Icons.check_circle_rounded,
              ),
              _ComicPill(
                label: '$active OPEN',
                foreground: const Color(0xFF1D4ED8),
                background: const Color(0xFFDCE9FF),
                icon: Icons.lock_open_rounded,
              ),
              _ComicPill(
                label: '$locked LOCKED',
                foreground: const Color(0xFF475569),
                background: const Color(0xFFE2E8F0),
                icon: Icons.lock_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.node});

  final PathNode node;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Next up: ${node.topicName}, ${_statusLabel(node.status)}',
      child: _ComicCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const NovaCompanion(size: 40, mood: NovaMood.encouraging),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT UP',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    node.topicName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _comicInk,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _statusLabel(node.status),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _comicSlate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'IN_PROGRESS' => 'In progress — pick up where you left off',
      'AVAILABLE' => 'Available — ready to start',
      'COMPLETED' => 'Completed — review anytime',
      _ => 'Locked — complete earlier topics first',
    };

// ── WORLD ARENA + TUTOR ───────────────────────────────────────────────────

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
        _ComicHeader(
          title: 'World arena',
          icon: Icons.sports_esports_rounded,
          accent: accent,
        ),
        _ComicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _comicInk, width: 2.2),
                      boxShadow: NeoBrutalShadows.hardXs,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        '$displayName // WORLD ARENA',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : _comicInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasTopic
                    ? 'Every game here plays $displayName content only.'
                    : 'The arena unlocks once your path has a topic.',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : _comicSlate,
                ),
              ),
              const SizedBox(height: 14),
              _ComicButton(
                label: 'Enter game arena',
                icon: Icons.sports_esports_rounded,
                style: _ComicButtonStyle.accent,
                fill: accent,
                onTap: hasTopic ? onEnter : null,
              ),
              const SizedBox(height: 10),
              _ComicButton(
                label: 'Ask Nova Tutor',
                icon: Icons.psychology_outlined,
                style: _ComicButtonStyle.secondary,
                onTap: onTutor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── SYLLABUS (static outline + backend taps) ──────────────────────────────

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
        const _ComicHeader(
          title: 'Syllabus',
          icon: Icons.menu_book_rounded,
          accent: AppColors.purple,
        ),
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
              style: const TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: _comicSlate,
              ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: match == null ? null : () => onOpenTopic(match),
        child: Semantics(
          button: match != null,
          label: match != null
              ? '$title, ${match.status.toLowerCase()}, tap to open'
              : '$title, syllabus outline',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? _comicCardDark : _comicPaper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _comicInk,
                width: match != null ? 2.2 : 1.5,
              ),
              boxShadow: match != null ? NeoBrutalShadows.hardXs : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : _comicInk,
                    ),
                  ),
                ),
                if (match != null) ...[
                  _StatusDot(status: match.status),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark ? Colors.white : _comicInk,
                  ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '${node.topicName}, ${node.status.toLowerCase()}, tap to open',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? _comicCardDark : _comicPaper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _comicInk, width: 2.2),
              boxShadow: NeoBrutalShadows.hardXs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    node.topicName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : _comicInk,
                    ),
                  ),
                ),
                _StatusDot(status: node.status),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? Colors.white : _comicInk,
                ),
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
      'AVAILABLE' => AppColors.primary,
      _ => AppColors.locked,
    };
    return Semantics(
      label: 'Status $status',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: _comicInk, width: 1.6),
        ),
      ),
    );
  }
}

// ── WORLD MASTERY (filtered by this world's backend topics) ───────────────

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
        const _ComicHeader(
          title: 'World mastery',
          icon: Icons.workspace_premium_rounded,
          accent: AppColors.success,
        ),
        if (dashboard == null)
          const EmptyMiniCard(text: 'Mastery unavailable right now.')
        else if (topics.isEmpty)
          const EmptyMiniCard(
            text: 'No mastery data for this world yet. Play or take the scan.',
          )
        else
          _ComicCard(
            child: Column(
              children: [
                for (var i = 0; i < topics.length && i < 5; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 8),
                    Container(height: 1.5, color: _comicInk),
                    const SizedBox(height: 8),
                  ],
                  _MasteryRow(topic: topics[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _MasteryRow extends StatelessWidget {
  const _MasteryRow({required this.topic});

  final RecentTopicMastery topic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = topic.masteryScore;
    return Row(
      children: [
        Expanded(
          child: Text(
            topic.topicName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : _comicInk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _comicInk, width: 1.5),
          ),
          child: Text(
            '${score.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF047857),
            ),
          ),
        ),
      ],
    );
  }
}

// ── RECENT ACTIVITY (world-filtered) + GLOBAL LEVEL ──────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizzes = (dashboard?.recentActivity.quizzes ?? const [])
        .where((q) => nodeIds.contains(q.topicId))
        .take(3)
        .toList();
    final gamification = dashboard?.gamification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ComicHeader(
          title: 'Progress & activity',
          icon: Icons.insights_rounded,
          accent: AppColors.secondary,
        ),
        if (gamification != null)
          Semantics(
            label:
                'Level ${gamification.currentLevel}, ${gamification.totalXp} total XP across all worlds',
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? _comicCardDark : _comicGameYellow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _comicInk, width: 2.5),
                boxShadow: NeoBrutalShadows.hard,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.xp : _comicPaper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _comicInk, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 22,
                      color: isDark ? _comicInk : AppColors.xp,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'LEVEL ${gamification.currentLevel} • ${gamification.totalXp} XP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _comicInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _ComicPill(
                    label: 'ALL WORLDS',
                    foreground: Color(0xFF475569),
                    background: Color(0xFFE2E8F0),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (quizzes.isEmpty)
          const EmptyMiniCard(
            text: 'No recent world activity. Your games and quizzes show here.',
          )
        else
          _ComicCard(
            child: Column(
              children: [
                for (var i = 0; i < quizzes.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 8),
                    Container(height: 1.5, color: _comicInk),
                    const SizedBox(height: 8),
                  ],
                  _QuizRow(quiz: quizzes[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _QuizRow extends StatelessWidget {
  const _QuizRow({required this.quiz});

  final RecentQuizRun quiz;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final correct = quiz.correctCount;
    final total = quiz.totalQuestions;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _comicInk, width: 1.6),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.quiz_rounded,
            size: 15,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            quiz.topicName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : _comicInk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$correct/$total',
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : _comicInk,
          ),
        ),
      ],
    );
  }
}
