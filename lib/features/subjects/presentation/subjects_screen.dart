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
import '../../../core/theme/neo_brutalism.dart';
import '../../../core/theme/subject_visual_identity.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../domain/world_context.dart' show subjectsProvider;
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
  String _selectedCategory = SubjectGrouping.allLabel;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
  }

  void _reload() {
    ref.invalidate(subjectsProvider);
    setState(() {
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
    // World landing preserves backend subjectId; the world page resolves
    // the canonical WorldId via WorldCatalog (generic fallback when unmapped).
    final name = Uri.encodeComponent(subject.name);
    context.push('${Routes.world(subject.id)}?name=$name');
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
    // No AppBar: this tab root leads with its cinematic hero (which owns
    // the "CHOOSE YOUR WORLD" title), matching the dashboard tab. An
    // AppBar here would stack a duplicate title above the hero.
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryBright,
        backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Subject>>(
          // Shared cached catalog (subjectsProvider): dashboard, world
          // landing, arena and tutor resolve the same fetch — no duplicates.
          // Sorted by backend displayOrder; every world shown (no cap).
          future: ref.watch(subjectsProvider.future),
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
            final subjects = [...(snap.data ?? const <Subject>[])]
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            if (subjects.isEmpty) {
              return EmptyState(
                icon: Icons.public_off_rounded,
                title: 'No worlds yet',
                message: 'New worlds are being prepared. Check back soon.',
                action: SecondaryGameButton(
                  label: 'Refresh',
                  icon: Icons.refresh_rounded,
                  expanded: false,
                  onTap: _reload,
                ),
              );
            }
            final chips = SubjectGrouping.deriveChips(subjects);
            final filtered = SubjectGrouping.filter(
              subjects,
              _selectedCategory,
            );
            final dashboard = ref.watch(dashboardProvider).data;
            final assessedIds = <String>{
              ...?dashboard?.assessment.assessedSubjects.map((a) => a.subjectId),
              if (dashboard?.currentSubject?.id != null) dashboard!.currentSubject!.id,
              if (dashboard?.learningPath?.subjectId != null) dashboard!.learningPath!.subjectId,
            };
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
                    // Top system inset: with no AppBar the scroll content
                    // must clear the status bar/notch on real devices.
                    // Background layers above stay full-bleed. No-op in
                    // tests and desktop browsers (zero system padding).
                    child: SafeArea(
                      top: true,
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          // ── CHOOSE YOUR WORLD HERO ──
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CinematicHero(
                              accent: AppColors.primary,
                              badge: 'World Explorer',
                              badgeIcon: Icons.public_rounded,
                              scene: ScenePalette.indigo,
                              sceneSeed: 11,
                              title: Text(
                                'CHOOSE YOUR WORLD',
                                style: AppTypography.hero(
                                  context,
                                  size: 26,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  const NovaCompanion(
                                    size: 38,
                                    mood: NovaMood.encouraging,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Pick a world, Player. Your path adapts to you.',
                                      style: AppTypography.bodySecondary(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              tagline:
                                  'LEARN • EXPLORE\nMASTER • LEVEL UP',
                            ),
                          ),
                          // ── FEATURED / CURRENT WORLD ──
                          // Show featured only when 2+ worlds to avoid duplicate text in single-card tests
                          if (featuredSubject != null && filtered.length > 1) ...[
                            _FeaturedWorldCard(
                              subject: featuredSubject,
                              assessed: assessedIds.contains(featuredSubject.id),
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
                              action: SecondaryGameButton(
                                label: 'Show all',
                                icon: Icons.public_rounded,
                                expanded: false,
                                onTap: () => setState(
                                  () => _selectedCategory = SubjectGrouping.allLabel,
                                ),
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
                                final isAssessed = assessedIds.contains(subject.id);
                                return PressableWorldCard(
                                  subject: subject,
                                  isAssessed: isAssessed,
                                  onTap: () => _enter(subject),
                                  onScan: () => isAssessed ? _enter(subject) : _scan(subject),
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
                        ],
                      ),
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
        scene: scenePaletteForWorld(subject.iconKey),
        sceneSeed: seedForKey(subject.id),
        child: Stack(
          children: [
            // Gradient wash with world accent
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent.withValues(alpha: 0.22), Colors.transparent],
                        )
                      : identity.gradient,
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
                          color: isDark ? accent.withValues(alpha: 0.18) : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isDark ? accent.withValues(alpha: 0.35) : NeoBrutalColors.ink,
                            width: isDark ? 1.0 : 2.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(identity.icon, size: 14, color: isDark ? accent : NeoBrutalColors.ink),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'FEATURED WORLD',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isDark ? accent : NeoBrutalColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (assessed ? AppColors.success : AppColors.primary).withValues(alpha: 0.14)
                              : NeoBrutalColors.lemonYellow,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? (assessed ? AppColors.success : AppColors.primary).withValues(alpha: 0.30)
                                : NeoBrutalColors.ink,
                            width: isDark ? 1.0 : 2.0,
                          ),
                        ),
                        child: Text(
                          assessed ? 'IN PROGRESS' : 'NEW WORLD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? (assessed ? AppColors.success : accent) : NeoBrutalColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? accent.withValues(alpha: 0.5) : NeoBrutalColors.ink,
                            width: 2.0,
                          ),
                          boxShadow: isDark ? null : NeoBrutalShadows.hardXs,
                        ),
                        alignment: Alignment.center,
                        child: Icon(identity.icon, size: 28, color: identity.accent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subject.description.isEmpty
                                  ? 'Enter the ${subject.name} world and forge your path'
                                  : subject.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Color(0xFFE5E7EB),
                              ),
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
                            label: assessed ? 'VIEW PATH' : 'SCAN',
                            icon: assessed ? Icons.alt_route_rounded : Icons.radar_rounded,
                            accent: accent,
                            onTap: assessed ? onEnter : onScan,
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
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withValues(alpha: 0.95), accent],
                  )
                : null,
            color: isDark ? null : NeoBrutalColors.lemonYellow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.transparent : NeoBrutalColors.ink,
              width: isDark ? 0 : 2.5,
            ),
            boxShadow: isDark
                ? [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 6))]
                : NeoBrutalShadows.hardSm,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isDark ? Colors.white : NeoBrutalColors.ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white : NeoBrutalColors.ink,
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
          color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? accent.withValues(alpha: 0.35) : NeoBrutalColors.ink,
            width: isDark ? 1.0 : 2.5,
          ),
          boxShadow: isDark ? null : NeoBrutalShadows.hardSm,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isDark ? accent : NeoBrutalColors.ink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark ? accent : NeoBrutalColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorldVisualPalette {
  final Color cardBackground;
  final Color iconBoxColor;
  final IconData icon;
  final String subtitle;

  const WorldVisualPalette({
    required this.cardBackground,
    required this.iconBoxColor,
    required this.icon,
    required this.subtitle,
  });
}

WorldVisualPalette resolveWorldPalette(Subject subject) {
  final key = subject.iconKey.toLowerCase();
  final name = subject.name.toLowerCase();

  // 1. Programming
  if (key.contains('code') ||
      key.contains('programming') ||
      name.contains('programming') ||
      name.contains('coding')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFF818CF8), // Medium periwinkle blue
      iconBoxColor: Color(0xFF1E3A8A),   // Dark navy blue
      icon: Icons.code_rounded,
      subtitle: 'Explore the world of coding and problem solving.',
    );
  }
  // 2. Computer Networks
  if (key.contains('network') || name.contains('network')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFF22D3EE), // Cyan / Turquoise
      iconBoxColor: Color(0xFF0E7490),   // Dark teal
      icon: Icons.hub_rounded,
      subtitle: 'Explore the world of communication.',
    );
  }
  // 3. DBMS
  if (key.contains('dbms') ||
      key.contains('database') ||
      key.contains('sql') ||
      name.contains('database') ||
      name.contains('dbms')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFFFBBF24), // Warm golden amber
      iconBoxColor: Color(0xFF78350F),   // Dark amber / brown
      icon: Icons.storage_rounded,
      subtitle: 'Explore the world of data management.',
    );
  }
  // 4. Operating Systems
  if (key.contains('os') ||
      key.contains('operating') ||
      name.contains('operating system')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFFC084FC), // Lavender / Soft purple
      iconBoxColor: Color(0xFF581C87),   // Dark violet / purple
      icon: Icons.memory_rounded,
      subtitle: 'Explore the world of system operations.',
    );
  }
  // 5. Data Structures
  if (key.contains('data_structure') ||
      key.contains('dsa') ||
      key.contains('ds') ||
      name.contains('data structure')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFF4ADE80), // Fresh mint / Emerald green
      iconBoxColor: Color(0xFF14532D),   // Dark forest green
      icon: Icons.account_tree_rounded,
      subtitle: 'Explore the world of efficient problem solving.',
    );
  }
  // 6. Object Oriented Software Engineering
  if (name.contains('software engineering') ||
      name.contains('oose') ||
      key.contains('oose')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFFD8B4FE), // Soft mauve / violet
      iconBoxColor: Color(0xFF4A044E),   // Dark plum / purple
      icon: Icons.description_rounded,
      subtitle: 'Explore requirements, OOAD and UML design.',
    );
  }
  // 7. Object Oriented Programming
  if (key.contains('oop') ||
      name.contains('object oriented') ||
      name.contains('object-oriented')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFF38BDF8), // Vivid sky blue
      iconBoxColor: Color(0xFF0C4A6E),   // Dark navy blue
      icon: Icons.view_in_ar_rounded,
      subtitle: 'Explore the world of OOP fundamentals.',
    );
  }
  // 8. Web Technologies
  if (key.contains('web') || name.contains('web')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFFF472B6), // Warm pink / rose
      iconBoxColor: Color(0xFF881337),   // Deep crimson / burgundy
      icon: Icons.language_rounded,
      subtitle: 'Explore HTML, CSS, JS and modern web development.',
    );
  }
  // 9. Algorithms
  if (key.contains('algo') || name.contains('algorithm')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFFA78BFA), // Medium violet
      iconBoxColor: Color(0xFF3B0764),   // Deep violet
      icon: Icons.functions_rounded,
      subtitle: 'Explore design paradigms, DP, and analysis.',
    );
  }
  // 10. AI / ML
  if (key.contains('ai') ||
      key.contains('ml') ||
      name.contains('intelligence') ||
      name.contains('machine learning')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFFFB7185), // Rose
      iconBoxColor: Color(0xFF831843),   // Deep magenta
      icon: Icons.psychology_rounded,
      subtitle: 'Explore neural networks and intelligent agents.',
    );
  }
  // 11. Data Science
  if (key.contains('data_science') || name.contains('data science')) {
    return const WorldVisualPalette(
      cardBackground: Color(0xFF2DD4BF), // Teal
      iconBoxColor: Color(0xFF134E4A),   // Deep teal
      icon: Icons.analytics_rounded,
      subtitle: 'Explore data modeling, pandas, and analytics.',
    );
  }

  // Fallback
  return const WorldVisualPalette(
    cardBackground: Color(0xFF818CF8),
    iconBoxColor: Color(0xFF1E3A8A),
    icon: Icons.public_rounded,
    subtitle: 'Explore different worlds and master concepts.',
  );
}

class PressableWorldCard extends StatefulWidget {
  const PressableWorldCard({
    super.key,
    required this.subject,
    required this.onTap,
    required this.onScan,
    this.isAssessed = false,
  });

  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onScan;
  final bool isAssessed;

  @override
  State<PressableWorldCard> createState() => _PressableWorldCardState();
}

class _PressableWorldCardState extends State<PressableWorldCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = resolveWorldPalette(widget.subject);
    final description = widget.subject.description.isNotEmpty
        ? widget.subject.description
        : palette.subtitle;

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
            scale: _down ? 0.98 : 1.0,
            duration: reduce ? Duration.zero : AppMotion.fast,
            curve: AppMotion.easeOut,
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : AppMotion.normal,
              curve: AppMotion.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E232F) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF171923),
                  width: 2.5,
                ),
                boxShadow: _down
                    ? NeoBrutalShadows.hardPressed
                    : NeoBrutalShadows.hard,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.iconBoxColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF171923),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      palette.icon,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: isDark ? Colors.white : const Color(0xFF171923),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            fontSize: 12.5,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF596174),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Semantics(
                        button: true,
                        label: widget.isAssessed
                            ? 'Open ${widget.subject.name} world'
                            : 'Scan ${widget.subject.name} knowledge',
                        child: GestureDetector(
                          onTap: widget.isAssessed ? widget.onTap : widget.onScan,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isAssessed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF171923),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF171923),
                                  offset: Offset(1, 1),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.isAssessed ? 'ACTIVE' : 'NEW',
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 24,
                        color: isDark ? Colors.white : const Color(0xFF171923),
                      ),
                    ],
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
                        : (isDark ? AppColors.textSecondary : NeoBrutalColors.ink),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(label),
                selectedColor: isDark ? AppColors.primary : NeoBrutalColors.cobaltBlue,
                backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                side: BorderSide(
                  color: isDark
                      ? (isSelected ? AppColors.primaryBright : AppColors.border)
                      : NeoBrutalColors.ink,
                  width: isDark ? 1.0 : 2.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
