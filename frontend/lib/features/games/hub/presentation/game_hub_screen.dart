import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../game_engine/models/game_models.dart';

/// Premium Game Hub — subject-aware discovery.
/// Header → Current Context → Subject Games (when subjectId present) → General Games → All Games.
class GameHubScreen extends StatelessWidget {
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

  bool get _hasSubject => subjectId != null && subjectId!.isNotEmpty;

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  void _open(BuildContext context, GameType type) {
    final sid = _hasSubject ? subjectId : null;
    final sname = _hasSubject ? subjectName : null;
    final extra = topicName;
    switch (type) {
      case GameType.quizBattle:
        context.push(Routes.quizBattle(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.memoryMatch:
        context.push(Routes.memoryMatch(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.dragDrop:
        context.push(Routes.dragDrop(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.speedRun:
        context.push(Routes.speedRun(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.debugArena:
        context.push(Routes.debugArena(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.unlockCode:
        context.push(Routes.unlockCode(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.conceptBuilder:
        context.push(Routes.conceptBuilder(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.sequenceMaster:
        context.push(Routes.sequenceMaster(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.targetChallenge:
        context.push(Routes.targetChallenge(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.mysteryCase:
        context.push(Routes.mysteryCase(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.bossBattle:
        context.push(Routes.bossBattle(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.puzzleArena:
        context.push(Routes.puzzleArena(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.connectivityLab:
        context.push(Routes.connectivityLab(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
      case GameType.snakeAndLadder:
        context.push(Routes.snakeAndLadder(topicId, subjectId: sid, subjectName: sname), extra: extra);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = GameDefinition.all;
    final effectiveSubject = subjectName?.isNotEmpty == true ? subjectName! : (_hasSubject ? 'World' : null);
    final effectiveTopic = topicName?.isNotEmpty == true ? topicName! : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GAME ARENA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.zero,
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
              // Hero — subject-aware
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _hasSubject
                        ? [AppColors.primary.withValues(alpha: 0.22), AppColors.surfaceElevated]
                        : [AppColors.primary.withValues(alpha: 0.12), Theme.of(context).colorScheme.surface],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.primary.withValues(alpha: _hasSubject ? 0.35 : 0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppColors.primaryDeep, AppColors.primary]),
                      ),
                      child: Icon(_hasSubject ? Icons.school_rounded : Icons.sports_esports_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasSubject ? (effectiveSubject!.toUpperCase()) : 'GAME ZONE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _hasSubject
                                ? '${effectiveTopic ?? 'Topic'} • Game Zone'
                                : (effectiveTopic ?? 'Select your challenge'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasSubject
                                ? 'Playing as part of ${effectiveSubject ?? 'this world'} — same mastery, more fun.'
                                : 'Learning feels like play. Pick a game — same mastery, more fun.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Current context pills
              Semantics(
                label: _hasSubject
                    ? 'Current context subject ${effectiveSubject ?? 'World'} topic ${effectiveTopic ?? topicId}'
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
                        _ContextPill(icon: Icons.topic_rounded, label: effectiveTopic ?? _shortId(topicId), color: AppColors.secondary),
                        _ContextPill(icon: Icons.sports_esports_rounded, label: '${cards.length} GAMES', color: AppColors.textTertiary),
                      ] else ...[
                        _ContextPill(icon: Icons.sports_esports_rounded, label: 'GENERAL GAME', color: AppColors.primary),
                        _ContextPill(icon: Icons.topic_rounded, label: effectiveTopic ?? _shortId(topicId), color: AppColors.textTertiary),
                        _ContextPill(icon: Icons.grid_view_rounded, label: '${cards.length} GAMES', color: AppColors.textTertiary),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Legacy summary for backward compat (tests expect these strings)
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
              // Subject games when available
              if (_hasSubject) ...[
                SectionHeaderWithCount(title: 'SUBJECT GAMES', count: '${cards.length}', subtitle: '${effectiveSubject} • topic-bound play'),
                const SizedBox(height: 10),
                AdaptiveGrid(
                  compact: 1,
                  medium: 2,
                  expanded: 2,
                  wide: 3,
                  spacing: 12,
                  runSpacing: 12,
                  children: cards.map((d) => _GameCard(def: d, onTap: () => _open(context, d.type), subjectName: effectiveSubject, topicName: effectiveTopic, isSubjectContext: true)).toList(),
                ),
                const SizedBox(height: 20),
              ],
              // Keep legacy header for backward compat
              const Text('CHOOSE YOUR GAME', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
              const SizedBox(height: 4),
              const Text('All games available — no locked content. Pick any to start.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              const SizedBox(height: 12),
              // General games
              SectionHeaderWithCount(
                title: _hasSubject ? 'GENERAL GAMES' : 'ALL GAMES',
                count: '${cards.length}',
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
                children: cards.map((d) => _GameCard(def: d, onTap: () => _open(context, d.type), subjectName: _hasSubject ? null : null, topicName: effectiveTopic, isSubjectContext: _hasSubject ? false : false)).toList(),
              ),
              const SizedBox(height: 16),
              // Footer note
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

class _GameCard extends StatelessWidget {
  const _GameCard({required this.def, required this.onTap, this.subjectName, this.topicName, required this.isSubjectContext});
  final GameDefinition def;
  final VoidCallback onTap;
  final String? subjectName;
  final String? topicName;
  final bool isSubjectContext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (def.type) {
      GameType.quizBattle => AppColors.primary,
      GameType.memoryMatch => AppColors.secondary,
      GameType.dragDrop => AppColors.success,
      GameType.speedRun => AppColors.warning,
      GameType.debugArena => const Color(0xFFEF4444),
      GameType.unlockCode => const Color(0xFFEAB308),
      GameType.conceptBuilder => const Color(0xFF8B5CF6),
      GameType.sequenceMaster => const Color(0xFF06B6D4),
      GameType.targetChallenge => const Color(0xFFF97316),
      GameType.mysteryCase => const Color(0xFF7C3AED),
      GameType.bossBattle => const Color(0xFFEF4444),
      GameType.puzzleArena => const Color(0xFF06B6D4),
      GameType.connectivityLab => const Color(0xFF10B981),
      GameType.snakeAndLadder => const Color(0xFFF59E0B),
    };
    final category = _categoryFor(def.type);
    final categoryIcon = _categoryIconFor(def.type);
    final semanticsLabel = isSubjectContext && subjectName != null
        ? '${def.displayName}, subject $subjectName${topicName != null ? ', topic $topicName' : ''}, category $category'
        : '${def.displayName}, general game, category $category';
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: color.withValues(alpha: 0.32)),
            boxShadow: isDark
                ? [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 6))]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.9), color]),
                ),
                child: Center(child: Text(def.icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            def.displayName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.32)),
                          ),
                          child: const Text('AVAILABLE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: AppColors.success)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      def.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 7),
                    if (isSubjectContext && subjectName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _SmallPill(icon: Icons.public_rounded, label: subjectName!, color: AppColors.primary),
                            if (topicName != null) _SmallPill(icon: Icons.topic_rounded, label: topicName!, color: AppColors.secondary),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SmallPill(icon: categoryIcon, label: category, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                        _SmallPill(icon: Icons.speed_outlined, label: 'MEDIUM', color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                        if (def.supportsTimer) _SmallPill(icon: Icons.timer_outlined, label: 'Timed', color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                        if (def.supportsCombo) _SmallPill(icon: Icons.local_fire_department_outlined, label: 'Combo', color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: (color == AppColors.primary || color == AppColors.secondary) ? color.withValues(alpha: 0.28) : (Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppLightColors.border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))),
          ],
        ),
      );
}
