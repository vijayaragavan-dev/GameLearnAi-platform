import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/leaderboard_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../providers/leaderboard_providers.dart';
import '../widgets/leaderboard_avatar.dart';

/// Premium Champions Arena — overall + subject leaderboards.
/// Uses L4 data foundation, respects reduced motion, and is fully responsive.
class ChampionsArenaScreen extends ConsumerStatefulWidget {
  const ChampionsArenaScreen({super.key, this.initialSubjectId});

  final String? initialSubjectId;

  @override
  ConsumerState<ChampionsArenaScreen> createState() => _ChampionsArenaScreenState();
}

class _ChampionsArenaScreenState extends ConsumerState<ChampionsArenaScreen> {
  bool _isOverall = true;
  String? _selectedSubjectId;
  int _page = 1;
  final int _size = 20;

  @override
  void initState() {
    super.initState();
    _isOverall = widget.initialSubjectId == null;
    _selectedSubjectId = widget.initialSubjectId;
    if (_selectedSubjectId != null) {
      Future<void>.microtask(() {
        ref.read(selectedSubjectIdProvider.notifier).state = _selectedSubjectId;
      });
    }
  }

  void _switchToOverall() {
    setState(() {
      _isOverall = true;
      _selectedSubjectId = null;
      _page = 1;
    });
    ref.read(selectedSubjectIdProvider.notifier).state = null;
    ref.read(overallLeaderboardProvider.notifier).refresh(page: _page, size: _size);
  }

  void _switchToSubject(String subjectId) {
    setState(() {
      _isOverall = false;
      _selectedSubjectId = subjectId;
      _page = 1;
    });
    ref.read(selectedSubjectIdProvider.notifier).state = subjectId;
  }

  void _loadMore(int totalPages) {
    if (_page >= totalPages) return;
    setState(() => _page += 1);
    if (_isOverall) {
      ref.read(overallLeaderboardProvider.notifier).load(page: _page, size: _size);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overallState = ref.watch(overallLeaderboardProvider);
    final subjectAsync = ref.watch(subjectLeaderboardProvider);
    final myPosState = ref.watch(myPositionProvider);

    final isSubjectMode = !_isOverall && _selectedSubjectId != null;
    final LeaderboardResponse? data = isSubjectMode
        ? subjectAsync.value
        : overallState.data;
    final Object? error = isSubjectMode ? subjectAsync.error : overallState.error;
    final bool isLoading = isSubjectMode ? subjectAsync.isLoading : overallState.showLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHAMPIONS ARENA'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              if (isSubjectMode && _selectedSubjectId != null) {
                ref.invalidate(subjectLeaderboardProvider);
              } else {
                ref.read(overallLeaderboardProvider.notifier).refresh(page: _page, size: _size);
              }
              ref.read(myPositionProvider.notifier).refreshOverall();
            },
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          if (isDark) ...[
            Positioned(top: -40, right: -30, child: GlowOrb(color: AppColors.primary, size: 220, opacity: 0.07)),
            Positioned(bottom: 100, left: -20, child: GlowOrb(color: AppColors.secondary, size: 180, opacity: 0.05)),
          ],
          RefreshIndicator(
            color: AppColors.primaryBright,
            backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
            onRefresh: () async {
              if (isSubjectMode) {
                ref.invalidate(subjectLeaderboardProvider);
              } else {
                await ref.read(overallLeaderboardProvider.notifier).refresh(page: _page, size: _size);
              }
              await ref.read(myPositionProvider.notifier).refreshOverall();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppGutters.pagePadding(context), vertical: 12),
                  sliver: SliverList.list(
                    children: [
                      ResponsiveCenter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeaderHero(isOverall: _isOverall, onToggle: (v) => v ? _switchToOverall() : null),
                            const SizedBox(height: 14),
                            _SegmentControl(
                              isOverall: _isOverall,
                              onOverall: _switchToOverall,
                              onSubject: () {
                                setState(() => _isOverall = false);
                              },
                            ),
                            const SizedBox(height: 12),
                            if (!_isOverall) _SubjectChips(
                              selectedId: _selectedSubjectId,
                              onSelect: _switchToSubject,
                            ),
                            const SizedBox(height: 16),
                            if (isLoading && data == null)
                              const _SkeletonArena()
                            else if (error != null && data == null)
                              ErrorState(
                                title: 'ARENA CONNECTION INTERRUPTED',
                                message: 'We couldn\'t load the rankings. Check your connection and try again.',
                                onRetry: () {
                                  if (isSubjectMode) {
                                    ref.invalidate(subjectLeaderboardProvider);
                                  } else {
                                    ref.read(overallLeaderboardProvider.notifier).refresh(page: _page, size: _size);
                                  }
                                },
                              )
                            else if (data == null || (data.entries.isEmpty && data.top.isEmpty))
                              _EmptyState(isSubject: isSubjectMode, subjectName: data?.subjectName)
                            else ...[
                              // Hero with current user
                              _YourStationCard(
                                me: data.me,
                                myPos: myPosState.data,
                                isSubject: isSubjectMode,
                              ),
                              const SizedBox(height: 16),
                              // Podium
                              if (data.top.isNotEmpty) ...[
                                _Podium(top: data.top.take(3).toList()),
                                const SizedBox(height: 16),
                              ],
                              // Rank list (4..N)
                              _RankList(
                                entries: data.entries.length > 3 ? data.entries.sublist(3) : [],
                                currentUserRank: data.me?.rank,
                              ),
                              const SizedBox(height: 12),
                              // Nearby
                              if (data.nearby.isNotEmpty) ...[
                                SectionHeader(title: 'NEARBY CHAMPIONS', subtitle: 'Your competitive window'),
                                const SizedBox(height: 8),
                                _NearbyList(nearby: data.nearby),
                                const SizedBox(height: 12),
                              ],
                              // Pagination
                              _PaginationBar(
                                page: data.page,
                                totalPages: data.totalPages,
                                totalPlayers: data.totalPlayers,
                                onLoadMore: () => _loadMore(data.totalPages),
                                onRefresh: () {
                                  if (isSubjectMode) {
                                    ref.invalidate(subjectLeaderboardProvider);
                                  } else {
                                    ref.read(overallLeaderboardProvider.notifier).refresh(page: 1, size: _size);
                                    setState(() => _page = 1);
                                  }
                                },
                              ),
                              if (error != null && data != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Showing last snapshot — offline',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.overline(context).copyWith(letterSpacing: 1.2)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTypography.caption(context)),
        ],
      ],
    );
  }
}

// Hero
class _HeaderHero extends StatelessWidget {
  const _HeaderHero({required this.isOverall, required this.onToggle});
  final bool isOverall;
  final ValueChanged<bool> onToggle;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FeaturedSurface(
      accent: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RISE THROUGH THE RANKS', style: AppTypography.overline(context).copyWith(color: AppColors.primaryBright)),
          const SizedBox(height: 4),
          Text('Champions Arena', style: AppTypography.hero(context, size: 22)),
          const SizedBox(height: 6),
          Text(
            'Compete by learning — every XP is earned, never bought.',
            style: AppTypography.bodySecondary(context).copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _SegmentControl extends StatelessWidget {
  const _SegmentControl({required this.isOverall, required this.onOverall, required this.onSubject});
  final bool isOverall;
  final VoidCallback onOverall;
  final VoidCallback onSubject;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Leaderboard segment selector',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppLightColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegmentChip(label: 'OVERALL', selected: isOverall, onTap: onOverall),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _SegmentChip(label: 'SUBJECT', selected: !isOverall, onTap: onSubject),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label leaderboard',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: selected ? Colors.white : (isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectChips extends ConsumerWidget {
  const _SubjectChips({required this.selectedId, required this.onSelect});
  final String? selectedId;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use contentRepo subjects; while loading, show placeholder
    final subjectsAsync = ref.watch(contentRepoProvider);
    // contentRepoProvider is a Provider<ContentRepository>, not async; we need to fetch
    // Do a FutureBuilder for subjects
    return FutureBuilder(
      future: ref.read(contentRepoProvider).subjects(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 36, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))));
        }
        final subjects = (snap.data as List).take(6).toList();
        if (subjects.isEmpty) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: subjects.map((s) {
              final id = (s as dynamic).id as String;
              final name = (s as dynamic).name as String;
              final isSel = id == selectedId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSel ? Colors.white : null)),
                  selected: isSel,
                  onSelected: (_) => onSelect(id),
                  selectedColor: AppColors.primary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(color: isSel ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppLightColors.border)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _YourStationCard extends StatelessWidget {
  const _YourStationCard({required this.me, required this.myPos, required this.isSubject});
  final LeaderboardEntry? me;
  final LeaderboardPosition? myPos;
  @override
  final bool isSubject;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (me == null) {
      return GameChallengeSurface(
        accent: AppColors.primary,
        title: 'YOUR STATION',
        icon: Icons.emoji_events_rounded,
        subtitle: isSubject ? 'SUBJECT' : 'OVERALL',
        child: Text('Play to join the arena', style: AppTypography.bodySecondary(context)),
      );
    }
    final isTop = me!.rank == 1;
    final xpToNext = myPos?.xpToNextRank;
    return Semantics(
      label: 'Your position rank ${me!.rank}, level ${me!.level}, ${me!.totalXp} XP',
      child: GameChallengeSurface(
        accent: isTop ? AppColors.xp : AppColors.primary,
        title: 'YOUR STATION',
        icon: Icons.person_rounded,
        subtitle: '#${me!.rank} • LEVEL ${me!.level}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LeaderboardAvatarView(avatar: me!.avatar, displayName: me!.displayName, size: 56, showGlow: isTop),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(me!.displayName, style: AppTypography.h3(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        isSubject ? '${me!.subjectXp ?? 0} Subject XP' : '${me!.totalXp} XP',
                        style: AppTypography.xpLabel(context, size: 11),
                      ),
                      const SizedBox(height: 4),
                      if (isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.xp.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.xp.withValues(alpha: 0.3))),
                          child: const Text('TOP OF THE ARENA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.xp)),
                        )
                      else if (xpToNext != null)
                        Text('$xpToNext XP TO #${me!.rank - 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.primary.withValues(alpha: 0.25))),
                  child: Text('#${me!.rank}', style: AppTypography.levelNumber(context, size: 16)),
                ),
              ],
            ),
            if (!isTop && xpToNext != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _progressToNext(me!.totalXp, xpToNext),
                  minHeight: 6,
                  backgroundColor: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _progressToNext(int myXp, int xpToNext) {
    // xpToNext = aboveXp - myXp +1, so progress = myXp / aboveXp approx
    // Use 1 - xpToNext/(xpToNext+myXp) as visual, clamped 0..1
    if (xpToNext <= 0) return 1;
    final above = myXp + xpToNext - 1;
    if (above <= 0) return 0;
    return (myXp / above).clamp(0.0, 1.0);
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top});
  final List<LeaderboardEntry> top;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = AppMotion.reducedMotion(context);
    final items = top.take(3).toList();
    // Order for visual: #2, #1, #3 on desktop; stacked on mobile
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10, top: i == 0 ? 0 : 0),
              child: _PodiumCard(entry: items[i], isFirst: items[i].rank == 1, index: i, reduceMotion: reduce),
            ),
        ],
      );
    }
    // Desktop: row with #1 elevated
    final ordered = <LeaderboardEntry>[];
    if (items.length >= 2) ordered.add(items[1]); // #2
    if (items.isNotEmpty) ordered.add(items[0]); // #1
    if (items.length >= 3) ordered.add(items[2]); // #3
    // fill if less than 3
    while (ordered.length < items.length) ordered.add(items[ordered.length]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < ordered.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8, right: i == ordered.length - 1 ? 0 : 8, bottom: ordered[i].rank == 1 ? 0 : 12),
              child: _PodiumCard(entry: ordered[i], isFirst: ordered[i].rank == 1, index: i, reduceMotion: reduce),
            ),
          ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry, required this.isFirst, required this.index, required this.reduceMotion});
  final LeaderboardEntry entry;
  final bool isFirst;
  final int index;
  final bool reduceMotion;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delay = AppMotion.staggerDelay(index);
    Widget card = Container(
      padding: EdgeInsets.all(isFirst ? 14 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFirst
              ? [AppColors.xp.withValues(alpha: 0.22), Theme.of(context).colorScheme.surface]
              : [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isFirst ? AppColors.xp.withValues(alpha: 0.45) : (isDark ? AppColors.border : AppLightColors.border), width: isFirst ? 1.5 : 1),
        boxShadow: isFirst && isDark ? [BoxShadow(color: AppColors.xp.withValues(alpha: 0.18), blurRadius: 18)] : null,
      ),
      child: Column(
        children: [
          if (isFirst)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.xp, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: const Text('CHAMPION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.black)),
            ),
          if (isFirst) const SizedBox(height: 8),
          LeaderboardAvatarView(avatar: entry.avatar, displayName: entry.displayName, size: isFirst ? 64 : 52, showGlow: isFirst),
          const SizedBox(height: 8),
          Text('#${entry.rank}', style: TextStyle(fontSize: isFirst ? 13 : 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: isFirst ? AppColors.xp : (isDark ? AppColors.textSecondary : AppLightColors.textSecondary))),
          const SizedBox(height: 2),
          Text(entry.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isFirst ? 14 : 13, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
          const SizedBox(height: 2),
          Text('${entry.totalXp} XP • Lv ${entry.level}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
          if (entry.streakDays != null && entry.streakDays! >= 2) ...[
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.local_fire_department_rounded, size: 12, color: AppColors.streak), const SizedBox(width: 4), Text('${entry.streakDays}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.streak))]),
          ],
        ],
      ),
    );

    if (reduceMotion) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.normal + delay,
      curve: AppMotion.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child)),
      child: card,
    );
  }
}

class _RankList extends StatelessWidget {
  const _RankList({required this.entries, this.currentUserRank});
  final List<LeaderboardEntry> entries;
  final int? currentUserRank;
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) _PlayerCard(entry: entries[i], index: i, isMe: entries[i].rank == currentUserRank),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.entry, required this.index, this.isMe = false});
  final LeaderboardEntry entry;
  final int index;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = AppMotion.reducedMotion(context);
    Widget card = Semantics(
      label: 'Rank ${entry.rank}, ${entry.displayName}, Level ${entry.level}, ${entry.totalXp} XP',
      button: true,
      child: Container(
        margin: EdgeInsets.only(bottom: index == 0 ? 0 : 8, top: index == 0 ? 0 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isMe ? AppColors.primary.withValues(alpha: 0.45) : (isDark ? AppColors.border : AppLightColors.border), width: isMe ? 1.5 : 1),
          boxShadow: isMe && isDark ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 12)] : null,
        ),
        child: Row(
          children: [
            SizedBox(width: 32, child: Text('#${entry.rank}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))),
            LeaderboardAvatarView(avatar: entry.avatar, displayName: entry.displayName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Lv ${entry.level} • ${entry.totalXp} XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (entry.isMe)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: const Text('YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
              )
            else if (entry.rankDelta != null)
              _RankDelta(delta: entry.rankDelta!),
            if (entry.streakDays != null && entry.streakDays! >= 2) ...[
              const SizedBox(width: 6),
              Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.streak),
              Text('${entry.streakDays}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.streak)),
            ],
          ],
        ),
      ),
    );
    if (reduce) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.fast + Duration(milliseconds: index * 30),
      curve: AppMotion.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child)),
      child: card,
    );
  }
}

class _RankDelta extends StatelessWidget {
  const _RankDelta({required this.delta});
  final int delta;
  @override
  Widget build(BuildContext context) {
    final isUp = delta > 0;
    final isDown = delta < 0;
    final color = isUp ? AppColors.success : (isDown ? AppColors.textTertiary : AppColors.textSecondary);
    final label = isUp ? '↑ $delta' : (isDown ? '↓ ${delta.abs()}' : '—');
    return Semantics(
      label: isUp ? 'rank up $delta' : (isDown ? 'rank down ${delta.abs()}' : 'rank unchanged'),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _NearbyList extends StatelessWidget {
  const _NearbyList({required this.nearby});
  final List<LeaderboardEntry> nearby;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < nearby.length; i++) _PlayerCard(entry: nearby[i], index: i, isMe: nearby[i].isMe),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.page, required this.totalPages, required this.totalPlayers, required this.onLoadMore, required this.onRefresh});
  final int page;
  final int totalPages;
  final int totalPlayers;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    final isLast = page >= totalPages;
    return Row(
      children: [
        Expanded(child: Text('$totalPlayers champions • Page $page of $totalPages', style: AppTypography.caption(context))),
        const SizedBox(width: 12),
        if (!isLast)
          FilledButton(
            onPressed: onLoadMore,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            child: const Text('LOAD MORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          )
        else
          OutlinedButton(
            onPressed: onRefresh,
            child: const Text('REFRESH'),
          ),
      ],
    );
  }
}

class _SkeletonArena extends StatelessWidget {
  const _SkeletonArena();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == 4 ? 0 : 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppLightColors.border)),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSubject, this.subjectName});
  final bool isSubject;
  final String? subjectName;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.22))),
            child: const Icon(Icons.emoji_events_outlined, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(isSubject ? 'NO CHAMPIONS YET' : 'NO CHAMPIONS YET', style: AppTypography.h3(context), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            isSubject && subjectName != null ? 'Be the first champion of $subjectName. Take the assessment or play to join.' : 'Start your learning journey and become the first champion.',
            style: AppTypography.bodySecondary(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => context.go('/subjects'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('EXPLORE WORLDS'),
          ),
        ],
      ),
    );
  }
}
