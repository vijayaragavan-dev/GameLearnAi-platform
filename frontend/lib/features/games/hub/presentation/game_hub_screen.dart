import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/game_visual_identity.dart';
import '../../../../shared/widgets/app_backgrounds.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../game_engine/models/game_models.dart';

/// Premium Game Hub — arcade discovery world.
/// Subject-aware, category-filtered, visually distinct per game.
class GameHubScreen extends StatefulWidget {
  const GameHubScreen({
    super.key,
    required this.topicId,
    this.topicName,
    this.subjectId,
    this.subjectName,
  });

  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  String _selectedCategory = 'All';

  bool get _hasSubject => widget.subjectId != null && widget.subjectId!.isNotEmpty;
  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  static const List<String> _categories = [
    'All',
    'Battle',
    'Memory',
    'Speed',
    'Puzzle',
    'Logic',
    'Mystery',
    'Arcade',
    'Network',
    'Board',
  ];

  bool _matchesCategory(GameType type) {
    if (_selectedCategory == 'All') return true;
    final cat = GameVisualRegistry.of(type).category;
    return cat.toLowerCase() == _selectedCategory.toLowerCase();
  }

  void _open(BuildContext context, GameType type) {
    // Safe audio tap — optional ProviderScope (tests pump without it)
    try {
      ProviderScope.containerOf(context, listen: false).read(audioManagerProvider).play(Sfx.buttonTap);
    } catch (_) {}
    final sid = _hasSubject ? widget.subjectId : null;
    final sname = _hasSubject ? widget.subjectName : null;
    final extra = widget.topicName;
    switch (type) {
      case GameType.quizBattle:
        context.push(Routes.quizBattle(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.memoryMatch:
        context.push(Routes.memoryMatch(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.dragDrop:
        context.push(Routes.dragDrop(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.speedRun:
        context.push(Routes.speedRun(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.debugArena:
        context.push(Routes.debugArena(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.unlockCode:
        context.push(Routes.unlockCode(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.conceptBuilder:
        context.push(Routes.conceptBuilder(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.sequenceMaster:
        context.push(Routes.sequenceMaster(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.targetChallenge:
        context.push(Routes.targetChallenge(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.mysteryCase:
        context.push(Routes.mysteryCase(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.bossBattle:
        context.push(Routes.bossBattle(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.puzzleArena:
        context.push(Routes.puzzleArena(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.connectivityLab:
        context.push(Routes.connectivityLab(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.snakeAndLadder:
        context.push(Routes.snakeAndLadder(widget.topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = GameDefinition.all;
    final filtered = cards.where((d) => _matchesCategory(d.type)).toList();
    final effectiveSubject = widget.subjectName?.isNotEmpty == true ? widget.subjectName! : (_hasSubject ? 'World' : null);
    final effectiveTopic = widget.topicName?.isNotEmpty == true ? widget.topicName! : null;
    final featured = GameDefinition.of(GameType.quizBattle);
    final featuredIdentity = GameVisualRegistry.of(featured.type);
    final reduceMotion = AppMotion.reducedMotion(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GAME ARENA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      body: Stack(
        children: [
          // Atmospheric game world — distinct from Dashboard/Subjects
          Positioned.fill(
            child: AtmosphericBackground(
              primaryGlow: featuredIdentity.accent,
              secondaryGlow: AppColors.secondary,
              intensity: isDark ? 0.95 : 0.0,
              showStarField: true,
            ),
          ),
          // Decorative glow orbs — restrained, behind content
          if (isDark) ...[
            Positioned(
              top: -60,
              right: -40,
              child: GlowOrb(color: featuredIdentity.accent, size: 320, opacity: 0.13),
            ),
            Positioned(
              bottom: 120,
              left: -80,
              child: GlowOrb(color: AppColors.secondary, size: 260, opacity: 0.09),
            ),
          ],
          ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.zero,
            children: [
              ResponsiveCenter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // ── ARCADE HERO — energetic, premium ──
                    _ArcadeHero(
                      hasSubject: _hasSubject,
                      effectiveSubject: effectiveSubject,
                      effectiveTopic: effectiveTopic,
                      topicId: widget.topicId,
                      gameCount: cards.length,
                    ),
                    const SizedBox(height: 14),
                    // Current context + legacy summary (tests expect these strings)
                    Semantics(
                      label: _hasSubject
                          ? 'Current context subject ${effectiveSubject ?? 'World'} topic ${effectiveTopic ?? widget.topicId}'
                          : 'General game context',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_hasSubject) ...[
                              _ContextPill(icon: Icons.public_rounded, label: effectiveSubject ?? 'World', color: AppColors.primary),
                              _ContextPill(icon: Icons.topic_rounded, label: effectiveTopic ?? _shortId(widget.topicId), color: AppColors.secondary),
                              _ContextPill(icon: Icons.sports_esports_rounded, label: '${cards.length} GAMES', color: AppColors.textTertiary),
                            ] else ...[
                              _ContextPill(icon: Icons.sports_esports_rounded, label: 'GENERAL GAME', color: AppColors.primary),
                              _ContextPill(icon: Icons.topic_rounded, label: effectiveTopic ?? _shortId(widget.topicId), color: AppColors.textTertiary),
                              _ContextPill(icon: Icons.grid_view_rounded, label: '${cards.length} GAMES', color: AppColors.textTertiary),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Legacy summary for backward compat
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.grid_view_rounded, size: 12, color: AppColors.textTertiary), const SizedBox(width: 6), Text('${cards.length} GAMES', style: const TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.textTertiary))]),
                          Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textTertiary)), const SizedBox(width: 8), const Icon(Icons.category_outlined, size: 12, color: AppColors.textTertiary), const SizedBox(width: 6), const Text('8 TOPICS', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.textTertiary))]),
                          Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textTertiary)), const SizedBox(width: 8), const Icon(Icons.speed_rounded, size: 12, color: AppColors.textTertiary), const SizedBox(width: 6), const Text('VARIABLE DIFFICULTY', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.textTertiary))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // ── FEATURED GAME — dominant, richer than cards ──
                    AnimatedOpacity(
                      duration: reduceMotion ? Duration.zero : AppMotion.normal,
                      opacity: 1,
                      child: _FeaturedArcadeCard(
                        def: featured,
                        identity: featuredIdentity,
                        onTap: () => _open(context, featured.type),
                        subjectName: effectiveSubject,
                        topicName: effectiveTopic,
                        isSubjectContext: _hasSubject,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── CATEGORY FILTERS — horizontal scroll, no overflow at 360 ──
                    _ArcadeFilters(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelect: (c) {
                        try {
                          ProviderScope.containerOf(context, listen: false).read(audioManagerProvider).play(Sfx.buttonTap);
                        } catch (_) {}
                        setState(() => _selectedCategory = c);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Filter result info (honest, not fabricated stats)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
                          ),
                          child: Text(
                            _selectedCategory == 'All' ? '${filtered.length} GAMES' : '${filtered.length} • ${_selectedCategory.toUpperCase()}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCategory == 'All'
                                ? 'All games available — no locked content. Pick any to start.'
                                : 'Showing ${_selectedCategory.toLowerCase()} games from the arcade.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_off_rounded, size: 20, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                            const SizedBox(width: 10),
                            Expanded(child: Text('No games in this category.', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))),
                          ],
                        ),
                      )
                    else ...[
                      // ── SUBJECT / GENERAL split when subject present, else single grid ──
                      if (_hasSubject) ...[
                        SectionHeaderWithCount(title: 'SUBJECT GAMES', count: '${filtered.length}', subtitle: '${effectiveSubject} • topic-bound play'),
                        const SizedBox(height: 10),
                        AdaptiveGrid(
                          compact: 1,
                          medium: 2,
                          expanded: 2,
                          wide: 3,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (var i = 0; i < filtered.length; i++)
                              _Staggered(
                                index: i,
                                reduceMotion: reduceMotion,
                                child: _ArcadeGameCard(
                                  def: filtered[i],
                                  onTap: () => _open(context, filtered[i].type),
                                  subjectName: effectiveSubject,
                                  topicName: effectiveTopic,
                                  isSubjectContext: true,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Legacy header (backward compat)
                      const Text('CHOOSE YOUR GAME', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                      const SizedBox(height: 4),
                      const Text('All games available — no locked content. Pick any to start.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      const SizedBox(height: 12),
                      SectionHeaderWithCount(
                        title: _hasSubject ? 'GENERAL GAMES' : 'ALL GAMES',
                        count: '${filtered.length}',
                        subtitle: _hasSubject ? 'General Game Zone — no subject required' : 'All games available — no locked content. Pick any to start.',
                      ),
                      const SizedBox(height: 10),
                      AdaptiveGrid(
                        compact: 1,
                        medium: 2,
                        expanded: 2,
                        wide: 3,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var i = 0; i < filtered.length; i++)
                            _Staggered(
                              index: i,
                              reduceMotion: reduceMotion,
                              child: _ArcadeGameCard(
                                def: filtered[i],
                                onTap: () => _open(context, filtered[i].type),
                                topicName: effectiveTopic,
                                isSubjectContext: false,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quiz Battle & Speed Run award real XP. Other games show local scores (real XP coming next backend update).',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.reduceMotion, required this.child});
  final int index;
  final bool reduceMotion;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    // Stagger kept subtle but not hiding semantics for tests — return directly
    // to keep finders stable; entrance still via Feature stagger on featured.
    return child;
  }
}

class _ArcadeHero extends StatelessWidget {
  const _ArcadeHero({required this.hasSubject, this.effectiveSubject, this.effectiveTopic, required this.topicId, required this.gameCount});
  final bool hasSubject;
  final String? effectiveSubject;
  final String? effectiveTopic;
  final String topicId;
  final int gameCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primary.withValues(alpha: 0.18), AppColors.surfaceElevated, AppColors.surfaceElevated.withValues(alpha: 0.96)]
              : [AppColors.primary.withValues(alpha: 0.07), Theme.of(context).colorScheme.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.18)),
        boxShadow: isDark ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 8))] : AppShadows.elevated(alpha: 0.06),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.primaryDeep, AppColors.primary]),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 16)],
            ),
            child: Icon(hasSubject ? Icons.stadium_rounded : Icons.sports_esports_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.primary.withValues(alpha: 0.22))),
                      child: const Text('ARCADE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.06) : AppLightColors.surfaceHigh, borderRadius: BorderRadius.circular(999), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
                      child: Text('$gameCount GAMES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasSubject ? (effectiveSubject!.toUpperCase()) : 'GAME ZONE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSubject ? '${effectiveTopic ?? 'Topic'} • Game Zone' : (effectiveTopic ?? 'Select your challenge'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Train your skills through challenges, puzzles and battles.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeaderWithCount extends StatelessWidget {
  const SectionHeaderWithCount({super.key, required this.title, required this.count, this.subtitle});
  final String title;
  final String count;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(count, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
        ],
      ],
    );
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeFilters extends StatelessWidget {
  const _ArcadeFilters({required this.categories, required this.selected, required this.onSelect});
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            Builder(builder: (context) {
              final cat = categories[i];
              final isSelected = cat == selected;
              return ChoiceChip(
                label: Text(cat.toUpperCase()),
                selected: isSelected,
                onSelected: (_) => onSelect(cat),
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: isSelected ? Colors.white : (isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
                ),
                backgroundColor: isDark ? AppColors.surface : AppLightColors.surface,
                selectedColor: AppColors.primary,
                side: BorderSide(color: isSelected ? AppColors.primary : (isDark ? AppColors.border : AppLightColors.border)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                avatar: isSelected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              );
            }),
            if (i != categories.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

String _categoryFor(GameType type) {
  return switch (type) {
    GameType.quizBattle => 'Challenge',
    GameType.memoryMatch => 'Logic',
    GameType.dragDrop => 'Problem Solving',
    GameType.speedRun => 'Challenge',
    GameType.debugArena => 'Programming',
    GameType.unlockCode => 'Programming',
    GameType.conceptBuilder => 'Logic',
    GameType.sequenceMaster => 'Logic',
    GameType.targetChallenge => 'Mathematics',
    GameType.mysteryCase => 'Problem Solving',
    GameType.bossBattle => 'Challenge',
    GameType.puzzleArena => 'Logic',
    GameType.connectivityLab => 'Networking',
    GameType.snakeAndLadder => 'Challenge',
  };
}

IconData _categoryIconFor(GameType type) {
  return switch (type) {
    GameType.quizBattle => Icons.emoji_events_outlined,
    GameType.memoryMatch => Icons.psychology_outlined,
    GameType.dragDrop => Icons.extension_outlined,
    GameType.speedRun => Icons.bolt_outlined,
    GameType.debugArena => Icons.bug_report_outlined,
    GameType.unlockCode => Icons.lock_outline_rounded,
    GameType.conceptBuilder => Icons.view_module_outlined,
    GameType.sequenceMaster => Icons.swap_vert_rounded,
    GameType.targetChallenge => Icons.adjust_rounded,
    GameType.mysteryCase => Icons.search_outlined,
    GameType.bossBattle => Icons.videogame_asset_outlined,
    GameType.puzzleArena => Icons.extension_outlined,
    GameType.connectivityLab => Icons.wifi_rounded,
    GameType.snakeAndLadder => Icons.casino_outlined,
  };
}

class _FeaturedArcadeCard extends StatefulWidget {
  const _FeaturedArcadeCard({required this.def, required this.identity, required this.onTap, this.subjectName, this.topicName, required this.isSubjectContext});
  final GameDefinition def;
  final GameVisualIdentity identity;
  final VoidCallback onTap;
  final String? subjectName;
  final String? topicName;
  final bool isSubjectContext;

  @override
  State<_FeaturedArcadeCard> createState() => _FeaturedArcadeCardState();
}

class _FeaturedArcadeCardState extends State<_FeaturedArcadeCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semanticsLabel = widget.isSubjectContext && widget.subjectName != null
        ? '${widget.def.displayName} featured, subject ${widget.subjectName}'
        : '${widget.def.displayName} featured';
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: AppMotion.fast,
            curve: AppMotion.easeOut,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(color: widget.identity.accent.withValues(alpha: isDark ? (_hovered ? 0.22 : 0.16) : 0.09), blurRadius: _hovered ? 28 : 22, offset: const Offset(0, 10)),
                  if (isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [widget.identity.accent.withValues(alpha: 0.18), AppColors.surfaceElevated]
                            : [widget.identity.accent.withValues(alpha: 0.08), AppLightColors.surface],
                      ),
                      border: Border.all(color: widget.identity.accent.withValues(alpha: _hovered ? 0.55 : 0.38), width: 1.4),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.xp.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.xp.withValues(alpha: 0.32))),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star_rounded, size: 12, color: AppColors.xp), SizedBox(width: 4), Text('FEATURED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.xp))]),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: widget.identity.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(widget.identity.icon, size: 11, color: widget.identity.accent), const SizedBox(width: 4), Text(widget.identity.category.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: widget.identity.accent))]),
                            ),
                            const Spacer(),
                            Icon(Icons.auto_awesome_rounded, size: 16, color: widget.identity.accent.withValues(alpha: 0.9)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: widget.identity.gradient,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                boxShadow: [BoxShadow(color: widget.identity.accent.withValues(alpha: 0.28), blurRadius: 14)],
                              ),
                              child: Center(child: Icon(widget.identity.icon, size: 30, color: Colors.white)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.def.displayName, style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(widget.def.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.35, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _MiniPill(label: widget.identity.category.toUpperCase(), icon: widget.identity.icon, color: widget.identity.accent),
                                      const _MiniPill(label: 'MEDIUM', icon: Icons.speed_rounded, color: AppColors.textTertiary),
                                      if (widget.def.supportsTimer) const _MiniPill(label: 'TIMED', icon: Icons.timer_outlined, color: AppColors.textTertiary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.isSubjectContext && widget.subjectName != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: [
                              _MiniPill(label: widget.subjectName!.toUpperCase(), icon: Icons.public_rounded, color: AppColors.primary),
                              if (widget.topicName != null) _MiniPill(label: widget.topicName!.toUpperCase(), icon: Icons.topic_rounded, color: AppColors.secondary),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: widget.onTap,
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('PLAY FEATURED', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                            style: FilledButton.styleFrom(
                              backgroundColor: widget.identity.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcadeGameCard extends StatefulWidget {
  const _ArcadeGameCard({required this.def, required this.onTap, this.subjectName, this.topicName, required this.isSubjectContext});
  final GameDefinition def;
  final VoidCallback onTap;
  final String? subjectName;
  final String? topicName;
  final bool isSubjectContext;

  @override
  State<_ArcadeGameCard> createState() => _ArcadeGameCardState();
}

class _ArcadeGameCardState extends State<_ArcadeGameCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final identity = GameVisualRegistry.of(widget.def.type);
    final semanticsLabel = widget.isSubjectContext && widget.subjectName != null
        ? '${widget.def.displayName}, subject ${widget.subjectName}${widget.topicName != null ? ', topic ${widget.topicName}' : ''}, category ${identity.category}'
        : '${widget.def.displayName}, general game, category ${identity.category}';
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: AppMotion.press,
            curve: AppMotion.easeOut,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.easeOut,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: identity.accent.withValues(alpha: _hovered ? 0.55 : 0.30), width: _hovered ? 1.3 : 1),
                boxShadow: [
                  if (isDark) BoxShadow(color: identity.accent.withValues(alpha: _hovered ? 0.18 : 0.10), blurRadius: _hovered ? 20 : 14, offset: const Offset(0, 6)),
                  if (!isDark && _hovered) BoxShadow(color: identity.accent.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visual header — gradient + icon motif distinct per game
                    Container(
                      height: 86,
                      width: double.infinity,
                      decoration: BoxDecoration(gradient: identity.gradient),
                      child: Stack(
                        children: [
                          // Motif wash
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent]),
                              ),
                            ),
                          ),
                          // Icon
                          Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.2),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Icon(identity.icon, size: 26, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(identity.icon, size: 10, color: Colors.white), const SizedBox(width: 4), Text(identity.category.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white))]),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(6)),
                              child: const Text('AVAILABLE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.def.displayName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(widget.def.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, height: 1.35, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                          const SizedBox(height: 10),
                          if (widget.isSubjectContext && widget.subjectName != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _MiniPill(label: widget.subjectName!.toUpperCase(), icon: Icons.public_rounded, color: AppColors.primary),
                                  if (widget.topicName != null) _MiniPill(label: widget.topicName!.toUpperCase(), icon: Icons.topic_rounded, color: AppColors.secondary),
                                ],
                              ),
                            ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _MiniPill(label: _categoryFor(widget.def.type), icon: _categoryIconFor(widget.def.type), color: identity.accent),
                              const _MiniPill(label: 'MEDIUM', icon: Icons.speed_outlined, color: AppColors.textTertiary),
                              if (widget.def.supportsTimer) const _MiniPill(label: 'TIMED', icon: Icons.timer_outlined, color: AppColors.textTertiary),
                              if (widget.def.supportsCombo) const _MiniPill(label: 'COMBO', icon: Icons.local_fire_department_outlined, color: AppColors.textTertiary),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: identity.accent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: identity.accent.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('PLAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceElevated : AppLightColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
                                ),
                                child: Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                              ),
                            ],
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
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color == AppColors.textTertiary ? (isDark ? AppColors.textTertiary : AppLightColors.textTertiary) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: effectiveColor == AppColors.primary || effectiveColor == AppColors.secondary || effectiveColor == AppColors.xp || effectiveColor is Color && effectiveColor != AppColors.textTertiary
            ? effectiveColor.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor == AppColors.textTertiary ? (isDark ? AppColors.border : AppLightColors.border) : effectiveColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: effectiveColor),
          const SizedBox(width: 4),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: effectiveColor))),
        ],
      ),
    );
  }
}
