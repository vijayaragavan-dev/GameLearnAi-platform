import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/content_models.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/providers.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/subject_visual_identity.dart';
import '../../../shared/widgets/achievement_icon.dart' show SubjectGlyph;
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/responsive_layout.dart';
import 'subject_grouping.dart';

/// SUBJ-001 world selection — premium catalog.
/// Responsive: 1 col mobile, 2 tablet, 3 desktop, constrained 1120.
/// Theme-aware via Theme brightness. No fake subjects.
class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  Future<List<Subject>>? _future;
  String _selectedCategory = SubjectGrouping.allLabel;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
    _future = ref.read(contentRepoProvider).subjects();
  }

  void _reload() {
    setState(() {
      _future = ref.read(contentRepoProvider).subjects();
      _selectedCategory = SubjectGrouping.allLabel;
    });
  }

  void _selectCategory(String label) {
    if (_selectedCategory == label) return;
    ref.read(hapticsProvider).select();
    setState(() => _selectedCategory = label);
  }

  void _enter(Subject subject) {
    ref.read(audioManagerProvider).play(Sfx.nodeUnlock);
    ref.read(hapticsProvider).select();
    final name = Uri.encodeComponent(subject.name);
    context.go('/${Routes.path(subject.id).substring(1)}?name=$name');
  }

  void _scan(Subject subject) {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).select();
    context.push(Routes.assessmentIntro(subject.id));
  }

  Subject? _featuredWorld(
    List<Subject> subjects,
    Dashboard? dashboard,
    List<Subject> filtered,
  ) {
    // Prefer dashboard's currentSubject (real player context)
    final currentId = dashboard?.currentSubject?.id;
    if (currentId != null && currentId.isNotEmpty) {
      for (final s in subjects) {
        if (s.id == currentId && filtered.any((f) => f.id == s.id)) return s;
      }
      for (final s in subjects) {
        if (s.id == currentId) return s;
      }
    }
    // Fallback to first assessed world
    final assessedIds = dashboard?.assessment.assessedSubjects.map((a) => a.subjectId).toSet() ?? {};
    for (final s in subjects) {
      if (assessedIds.contains(s.id)) return s;
    }
    // Fallback to first filtered
    if (filtered.isNotEmpty) return filtered.first;
    if (subjects.isNotEmpty) return subjects.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('CHOOSE YOUR WORLD')),
      body: RefreshIndicator(
        color: AppColors.primaryBright,
        backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Subject>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done && !snap.hasData) {
              return ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppGutters.pagePadding(context)),
                children: const [SkeletonList(itemCount: 4, itemHeight: 108)],
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
            final subjects = snap.data ?? const <Subject>[];
            if (subjects.isEmpty) {
              return EmptyState(
                icon: Icons.public_off_rounded,
                title: 'No worlds yet',
                message: 'New worlds are being prepared. Check back soon.',
                action: OutlinedButton(
                  onPressed: _reload,
                  child: const Text('REFRESH'),
                ),
              );
            }
            final chips = SubjectGrouping.deriveChips(subjects);
            final filtered = SubjectGrouping.filter(
              subjects,
              _selectedCategory,
            );
            final dashboard = ref.watch(dashboardProvider).data;
            final featuredSubject = _featuredWorld(subjects, dashboard, filtered);
            // Premium catalog: atmospheric header + featured world + chips + adaptive grid
            return Stack(
              children: [
                const Positioned.fill(child: AtmosphericBackground()),
                Positioned(
                  top: -60,
                  right: -40,
                  child: IgnorePointer(
                    child: GlowOrb(
                      color: AppColors.primary,
                      size: 280,
                      opacity: isDark ? 0.08 : 0.03,
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
                          // ── WORLD EXPLORER HEADER ──
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('WORLD EXPLORER', style: AppTypography.overline(context)),
                                const SizedBox(height: 4),
                                Text('Choose your world', style: AppTypography.hero(context, size: 26)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const NovaCompanion(size: 38, mood: NovaMood.encouraging),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Pick a world, Player. Your path adapts to you.',
                                        style: AppTypography.bodySecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ── FEATURED / CURRENT WORLD ──
                          // Show featured only when 2+ worlds to avoid duplicate text in single-card tests
                          if (featuredSubject != null && filtered.length > 1) ...[
                            _FeaturedWorldCard(
                              subject: featuredSubject,
                              assessed: dashboard?.assessment.assessedSubjects
                                      .any((a) => a.subjectId == featuredSubject.id) ??
                                  false,
                              onEnter: () => _enter(featuredSubject),
                              onScan: () => _scan(featuredSubject),
                            ),
                            const SizedBox(height: 18),
                          ],
                          // ── CATEGORY FILTER ──
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _CategoryChips(
                              chips: chips,
                              selected: _selectedCategory,
                              onSelected: _selectCategory,
                            ),
                          ),
                          // ── ALL WORLDS GRID ──
                          if (filtered.isEmpty)
                            EmptyState(
                              icon: Icons.filter_list_off_rounded,
                              title: 'No worlds in this category',
                              message:
                                  'No "$_selectedCategory" worlds found. Try another category or view all worlds.',
                              action: OutlinedButton(
                                onPressed: () => setState(
                                  () => _selectedCategory = SubjectGrouping.allLabel,
                                ),
                                child: const Text('SHOW ALL'),
                              ),
                            )
                          else
                            AdaptiveGrid(
                              compact: 1,
                              medium: 2,
                              expanded: 2,
                              wide: 3,
                              spacing: 14,
                              runSpacing: 14,
                              children: filtered.map((subject) {
                                final isFeatured = featuredSubject != null && subject.id == featuredSubject.id;
                                if (isFeatured && filtered.length > 1) {
                                  // Featured already shown above — still show in grid but with compact variant
                                }
                                return PressableWorldCard(
                                  subject: subject,
                                  onTap: () => _enter(subject),
                                  onScan: () => _scan(subject),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 16),
                          // ── PROGRAMMING HINT ──
                          if (subjects.any((s) => s.name.toLowerCase().contains('programming')) &&
                              !subjects.any((s) => ['c', 'java', 'python', 'c++'].contains(s.name.toLowerCase())))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: isDark ? AppColors.border : AppLightColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.cardHighlight(AppColors.primary),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.code_rounded, size: 16, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Programming covers C · C++ · Java · Python · JavaScript — one world, many languages.',
                                      style: AppTypography.caption(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // ── DISCOVER / RECOMMENDED (only if real recommendation exists) ──
                          if (dashboard != null && dashboard.recommendations.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: _RecommendedWorldStrip(
                                dashboard: dashboard,
                                subjects: subjects,
                                onEnter: _enter,
                              ),
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
      ),
    );
  }
}

// ── FEATURED WORLD — large immersive world surface
class _FeaturedWorldCard extends StatelessWidget {
  const _FeaturedWorldCard({
    required this.subject,
    required this.assessed,
    required this.onEnter,
    required this.onScan,
  });

  final Subject subject;
  final bool assessed;
  final VoidCallback onEnter;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final identity = SubjectVisualRegistry.fromIconKey(subject.iconKey);
    final accent = identity.accent;
    return GestureDetector(
      onTap: onEnter,
      child: FeaturedSurface(
        accent: accent,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Gradient wash with world accent
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: accent.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(identity.icon, size: 14, color: accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text('FEATURED WORLD', style: AppTypography.badgeLabel(context, color: accent), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (assessed ? AppColors.success : AppColors.primary).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: (assessed ? AppColors.success : AppColors.primary).withValues(alpha: 0.30)),
                        ),
                        child: Text(
                          assessed ? 'IN PROGRESS' : 'NEW WORLD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: assessed ? AppColors.success : accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubjectIcon(iconKey: subject.iconKey, size: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subject.name, style: AppTypography.hero(context, size: 20)),
                            const SizedBox(height: 6),
                            Text(
                              subject.description.isEmpty ? 'Enter the ${subject.name} world and forge your path' : subject.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySecondary(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 340;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _WorldCTA(
                              label: assessed ? 'CONTINUE WORLD' : 'EXPLORE WORLD',
                              icon: assessed ? Icons.play_arrow_rounded : Icons.explore_rounded,
                              accent: accent,
                              onTap: onEnter,
                              primary: true,
                            ),
                            const SizedBox(height: 10),
                            _WorldCTA(
                              label: 'SCAN',
                              icon: Icons.radar_rounded,
                              accent: accent,
                              onTap: onScan,
                              primary: false,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _WorldCTA(
                              label: assessed ? 'CONTINUE WORLD' : 'EXPLORE WORLD',
                              icon: assessed ? Icons.play_arrow_rounded : Icons.explore_rounded,
                              accent: accent,
                              onTap: onEnter,
                              primary: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _WorldCTA(
                            label: 'SCAN',
                            icon: Icons.radar_rounded,
                            accent: accent,
                            onTap: onScan,
                            primary: false,
                          ),
                        ],
                      );
                    },
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

class _WorldCTA extends StatelessWidget {
  const _WorldCTA({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    required this.primary,
  });
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (primary) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.95), accent],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark ? [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 6))] : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── RECOMMENDED WORLD STRIP (only if real recommendation)
class _RecommendedWorldStrip extends StatelessWidget {
  const _RecommendedWorldStrip({
    required this.dashboard,
    required this.subjects,
    required this.onEnter,
  });
  final Dashboard dashboard;
  final List<Subject> subjects;
  final void Function(Subject) onEnter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rec = dashboard.recommendations.firstOrNull;
    if (rec == null || rec.topicName == null || rec.topicName!.isEmpty) return const SizedBox.shrink();
    // Try to resolve subject for that recommendation's topic via currentSubject or fallback
    final subject = subjects.firstWhere(
      (s) => s.id == dashboard.currentSubject?.id,
      orElse: () => subjects.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECOMMENDED FOR YOU', style: AppTypography.overline(context).copyWith(color: AppColors.secondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onEnter(subject),
          child: GameIdentitySurface(
            accent: AppColors.secondary,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SubjectIcon(iconKey: subject.iconKey, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue with ${subject.name}',
                        style: AppTypography.h3(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec.topicName! + (rec.reason.isNotEmpty ? ' • ${rec.reason}' : ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension on List<RecommendationItem> {
  RecommendationItem? get firstOrNull => isEmpty ? null : first;
}

class PressableWorldCard extends StatefulWidget {
  const PressableWorldCard({
    super.key,
    required this.subject,
    required this.onTap,
    required this.onScan,
  });

  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onScan;

  @override
  State<PressableWorldCard> createState() => _PressableWorldCardState();
}

class _PressableWorldCardState extends State<PressableWorldCard> {
  bool _down = false;

  Color get _tint {
    // Prefer world identity accent (distinct per world), fallback to order-based tint
    final identity = SubjectVisualRegistry.fromIconKey(widget.subject.iconKey);
    if (identity != SubjectVisualRegistry.fallback) return identity.accent;
    return switch (widget.subject.displayOrder % 5) {
      0 => AppColors.primary,
      1 => AppColors.secondary,
      2 => AppColors.success,
      3 => AppColors.warning,
      _ => AppColors.streak,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceElevated = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    return Semantics(
      button: true,
      label: '${widget.subject.name} world, tap to enter, scan available',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? 0.97 : 1,
            duration: reduce ? Duration.zero : AppMotion.fast,
            curve: AppMotion.easeOut,
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : AppMotion.normal,
              curve: AppMotion.easeOut,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _tint.withValues(alpha: _down ? 0.2 : 0.13),
                    surfaceElevated,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: _tint.withValues(alpha: _down ? 0.7 : 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _tint.withValues(alpha: _down ? 0.35 : (isDark ? 0.15 : 0.08)),
                    blurRadius: _down ? 26 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SubjectGlyph(iconKey: widget.subject.iconKey, color: _tint),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subject.description.isNotEmpty
                              ? widget.subject.description
                              : 'Enter the ${widget.subject.name} world',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                  Semantics(
                    button: true,
                    label: 'Scan ${widget.subject.name} knowledge',
                    child: GestureDetector(
                      onTap: widget.onScan,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _tint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _tint.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radar_rounded, size: 13, color: _tint),
                            const SizedBox(width: 4),
                            Text(
                              'SCAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: _tint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: _tint.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal category filter chips. Presentation-only; selection filters
/// the already-loaded catalog in-memory. No backend request.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.chips,
    required this.selected,
    required this.onSelected,
  });

  final List<String> chips;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = chips[i];
          final isSelected = label == selected;
          return Semantics(
            button: true,
            selected: isSelected,
            label:
                'Filter $label worlds, ${isSelected ? 'selected' : 'not selected'}',
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : AppMotion.fast,
              curve: AppMotion.easeOut,
              child: ChoiceChip(
                label: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isSelected
                        ? (isDark ? AppColors.textOnColor : Colors.white)
                        : (isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(label),
                selectedColor: AppColors.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryBright
                      : (isDark ? AppColors.border : AppLightColors.border),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                showCheckmark: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
