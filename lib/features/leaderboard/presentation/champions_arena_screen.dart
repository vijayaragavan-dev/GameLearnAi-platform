import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show Sfx;
import '../../../core/models/leaderboard_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart' show PressableScale;
import '../../../shared/widgets/responsive_layout.dart';
import '../../subjects/domain/world_context.dart';
import '../providers/leaderboard_providers.dart';
import '../widgets/leaderboard_avatar.dart';

/// Comic Neo-Brutalist Champions Arena — overall + current subject leaderboards.
/// Features top 3 animated podium, current station highlight, comic theme,
/// and smooth staggered rankings list.
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
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
    setState(() {
      _isOverall = true;
      _selectedSubjectId = null;
      _page = 1;
    });
    ref.read(selectedSubjectIdProvider.notifier).state = null;
    ref.read(overallLeaderboardProvider.notifier).refresh(page: _page, size: _size);
  }

  void _switchToSubject(String subjectId) {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
    setState(() {
      _isOverall = false;
      _selectedSubjectId = subjectId;
      _page = 1;
    });
    ref.read(selectedSubjectIdProvider.notifier).state = subjectId;
  }

  void _loadMore(int totalPages) {
    if (_page >= totalPages) return;
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
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
      backgroundColor: isDark ? const Color(0xFF151921) : const Color(0xFFF7F5EF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E232F) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF171923), width: 2.0),
        ),
        title: Text(
          'CHAMPIONS ARENA',
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 1.2,
            color: isDark ? Colors.white : const Color(0xFF171923),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(audioManagerProvider).play(Sfx.buttonTap);
              ref.read(hapticsProvider).tap();
              if (isSubjectMode && _selectedSubjectId != null) {
                ref.invalidate(subjectLeaderboardProvider);
              } else {
                ref.read(overallLeaderboardProvider.notifier).refresh(page: _page, size: _size);
              }
              ref.read(myPositionProvider.notifier).refreshOverall();
            },
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF171923)),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          RefreshIndicator(
            color: const Color(0xFF3B82F6),
            backgroundColor: isDark ? const Color(0xFF1E232F) : Colors.white,
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
                  padding: EdgeInsets.symmetric(horizontal: AppGutters.pagePadding(context), vertical: 14),
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
                            if (!_isOverall) ...[
                              _SubjectChips(
                                selectedId: _selectedSubjectId,
                                onSelect: _switchToSubject,
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 4),
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
                              // Hero with current user station
                              _YourStationCard(
                                me: data.me,
                                myPos: myPosState.data,
                                isSubject: isSubjectMode,
                              ),
                              const SizedBox(height: 18),

                              // Top 3 Podium
                              if (data.top.isNotEmpty) ...[
                                _Podium(top: data.top.take(3).toList()),
                                const SizedBox(height: 18),
                              ],

                              // Rank list (4..N)
                              _RankList(
                                entries: data.entries.length > 3 ? data.entries.sublist(3) : [],
                                currentUserRank: data.me?.rank,
                              ),
                              const SizedBox(height: 12),

                              // Nearby
                              if (data.nearby.isNotEmpty) ...[
                                const SectionHeader(title: 'NEARBY CHAMPIONS', subtitle: 'Your competitive window'),
                                const SizedBox(height: 8),
                                _NearbyList(nearby: data.nearby),
                                const SizedBox(height: 14),
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

                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF171923), width: 1.8),
                                      boxShadow: NeoBrutalShadows.hardXs,
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFD97706)),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Showing last snapshot — offline',
                                            style: TextStyle(
                                              fontFamily: AppTypography.displayFamily,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF171923),
                                            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: isDark ? Colors.white : const Color(0xFF171923),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 11.5,
              color: Color(0xFF596174),
            ),
          ),
        ],
      ],
    );
  }
}

// Hero banner
class _HeaderHero extends StatelessWidget {
  const _HeaderHero({required this.isOverall, required this.onToggle});
  final bool isOverall;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD43B), // Game Yellow
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF171923), width: 1.8),
              boxShadow: NeoBrutalShadows.hardXs,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded, size: 13, color: Color(0xFF171923)),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'RISE THROUGH THE RANKS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: Color(0xFF171923),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Champions Arena',
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: isDark ? Colors.white : const Color(0xFF171923),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compete by learning — every XP is earned, never bought.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF596174),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Leaderboard segment selector',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151921) : const Color(0xFFF7F5EF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF171923), width: 2.5),
          boxShadow: NeoBrutalShadows.hardSm,
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
    return Semantics(
      button: true,
      selected: selected,
      label: '$label leaderboard',
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B82F6) : Colors.transparent, // Electric Blue
            borderRadius: BorderRadius.circular(999),
            border: selected ? Border.all(color: const Color(0xFF171923), width: 2.0) : null,
            boxShadow: selected ? NeoBrutalShadows.hardXs : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: selected ? Colors.white : const Color(0xFF596174),
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
    final async = ref.watch(subjectsProvider);
    return async.when(
      loading: () => const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (subjects) {
        if (subjects.isEmpty) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: subjects.map((s) {
              final id = s.id;
              final name = s.name;
              final isSel = id == selectedId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PressableScale(
                  onTap: () => onSelect(id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF06B6D4) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF171923), width: 2.0),
                      boxShadow: isSel ? NeoBrutalShadows.hardXs : null,
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isSel ? Colors.white : const Color(0xFF171923),
                      ),
                    ),
                  ),
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
  final bool isSubject;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (me == null) {
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
            const Text(
              'YOUR STATION',
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text('Play to join the arena', style: AppTypography.bodySecondary(context)),
          ],
        ),
      );
    }

    final isTop = me!.rank == 1;
    final xpToNext = myPos?.xpToNextRank;

    return Semantics(
      label: 'Your position rank ${me!.rank}, level ${me!.level}, ${me!.totalXp} XP',
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD43B), // Game Yellow
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF171923), width: 2.0),
                    boxShadow: NeoBrutalShadows.hardXs,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_rounded, size: 14, color: Color(0xFF171923)),
                      SizedBox(width: 4),
                      Text(
                        'YOUR STATION',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Color(0xFF171923),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '#${me!.rank} • LEVEL ${me!.level}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF596174),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                LeaderboardAvatarView(
                  avatar: me!.avatar,
                  displayName: me!.displayName,
                  size: 54,
                  showGlow: isTop,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        me!.displayName,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF171923),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSubject ? '${me!.subjectXp ?? 0} Subject XP' : '${me!.totalXp} XP',
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD43B),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF171923), width: 1.5),
                          ),
                          child: const Text(
                            'TOP OF THE ARENA',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Color(0xFF171923),
                            ),
                          ),
                        )
                      else if (xpToNext != null)
                        Text(
                          '$xpToNext XP TO #${me!.rank - 1}',
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFF596174),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD43B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF171923), width: 2.0),
                    boxShadow: NeoBrutalShadows.hardXs,
                  ),
                  child: Text(
                    '#${me!.rank}',
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF171923),
                    ),
                  ),
                ),
              ],
            ),
            if (!isTop && xpToNext != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151921) : const Color(0xFFF7F5EF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF171923), width: 1.8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: _progressToNext(me!.totalXp, xpToNext)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _progressToNext(int myXp, int xpToNext) {
    if (xpToNext <= 0) return 1;
    final above = myXp + xpToNext - 1;
    if (above <= 0) return 0;
    return (myXp / above).clamp(0.0, 1.0);
  }
}

/// The top 3 Podium with dynamic comic pedestals and bounce entrance animation.
class _Podium extends StatelessWidget {
  const _Podium({required this.top});
  final List<LeaderboardEntry> top;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reducedMotion(context);
    final items = top.take(3).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
              child: _PodiumRowCard(
                entry: items[i],
                isFirst: items[i].rank == 1,
                rank: items[i].rank,
                index: i,
                reduceMotion: reduce,
              ),
            ),
        ],
      );
    }

    // Order: #2 on left, #1 in center, #3 on right
    final ordered = <LeaderboardEntry>[];
    if (items.length >= 2) ordered.add(items[1]); // #2
    if (items.isNotEmpty) ordered.add(items[0]); // #1
    if (items.length >= 3) ordered.add(items[2]); // #3
    while (ordered.length < items.length) {
      ordered.add(items[ordered.length]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < ordered.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 8,
                right: i == ordered.length - 1 ? 0 : 8,
                bottom: ordered[i].rank == 1 ? 0 : 14,
              ),
              child: _PodiumCard(
                entry: ordered[i],
                isFirst: ordered[i].rank == 1,
                rank: ordered[i].rank,
                index: i,
                reduceMotion: reduce,
              ),
            ),
          ),
      ],
    );
  }
}

/// Mobile podium card with comic champion badges and full responsive flex.
class _PodiumRowCard extends StatelessWidget {
  const _PodiumRowCard({
    required this.entry,
    required this.isFirst,
    required this.rank,
    required this.index,
    required this.reduceMotion,
  });

  final LeaderboardEntry entry;
  final bool isFirst;
  final int rank;
  final int index;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const ink = Color(0xFF171923);

    final Color pedestalBg;
    final Color accentColor;
    final IconData badgeIcon;

    if (rank == 1) {
      pedestalBg = isDark ? const Color(0xFF2A2315) : const Color(0xFFFFF9E6);
      accentColor = const Color(0xFFFFD43B); // Game Yellow
      badgeIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      pedestalBg = isDark ? const Color(0xFF1A2333) : const Color(0xFFEDF4FF);
      accentColor = const Color(0xFF06B6D4); // Bright Cyan
      badgeIcon = Icons.military_tech_rounded;
    } else {
      pedestalBg = isDark ? const Color(0xFF251A33) : const Color(0xFFF9F3FF);
      accentColor = const Color(0xFF7C3AED); // Vivid Purple
      badgeIcon = Icons.workspace_premium_rounded;
    }

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: pedestalBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ink, width: isFirst ? 2.8 : 2.2),
        boxShadow: isFirst ? NeoBrutalShadows.hard : NeoBrutalShadows.hardSm,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: ink, width: 2.0),
              boxShadow: NeoBrutalShadows.hardXs,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF171923),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          LeaderboardAvatarView(
            avatar: entry.avatar,
            displayName: entry.displayName,
            size: 42,
            showGlow: isFirst,
          ),
          const SizedBox(width: 10),

          // Name and Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: isFirst ? 14.5 : 13.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : ink,
                        ),
                      ),
                    ),
                    if (isFirst) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD43B),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: ink, width: 1.5),
                        ),
                        child: const Text(
                          'CHAMPION',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF171923),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.totalXp} XP • Lv ${entry.level}',
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF596174),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Icon(badgeIcon, size: 22, color: accentColor),

          if (entry.streakDays != null && entry.streakDays! >= 2) ...[
            const SizedBox(width: 8),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 2),
                Text(
                  '${entry.streakDays}',
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (reduceMotion) return card;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, 14 * (1 - t)),
        child: Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: card,
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.isFirst,
    required this.rank,
    required this.index,
    required this.reduceMotion,
  });

  final LeaderboardEntry entry;
  final bool isFirst;
  final int rank;
  final int index;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const ink = Color(0xFF171923);

    final Color pedestalBg;
    final Color accentColor;
    final IconData badgeIcon;
    final String rankLabel = '#$rank';

    if (rank == 1) {
      pedestalBg = isDark ? const Color(0xFF2A2315) : const Color(0xFFFFF9E6);
      accentColor = const Color(0xFFFFD43B); // Game Yellow
      badgeIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      pedestalBg = isDark ? const Color(0xFF1A2333) : const Color(0xFFEDF4FF);
      accentColor = const Color(0xFF06B6D4); // Bright Cyan
      badgeIcon = Icons.military_tech_rounded;
    } else {
      pedestalBg = isDark ? const Color(0xFF251A33) : const Color(0xFFF9F3FF);
      accentColor = const Color(0xFF7C3AED); // Vivid Purple
      badgeIcon = Icons.workspace_premium_rounded;
    }

    final card = Container(
      padding: EdgeInsets.fromLTRB(4, isFirst ? 14 : 10, 4, isFirst ? 16 : 12),
      decoration: BoxDecoration(
        color: pedestalBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink, width: isFirst ? 2.8 : 2.2),
        boxShadow: isFirst ? NeoBrutalShadows.hard : NeoBrutalShadows.hardSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFirst) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD43B),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ink, width: 2.0),
                boxShadow: NeoBrutalShadows.hardXs,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 12, color: Color(0xFF171923)),
                  SizedBox(width: 2),
                  Text(
                    'CHAMPION',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Color(0xFF171923),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Avatar with badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ink, width: 2.5),
                  boxShadow: isFirst
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.45),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: LeaderboardAvatarView(
                  avatar: entry.avatar,
                  displayName: entry.displayName,
                  size: isFirst ? 54 : 44,
                  showGlow: isFirst,
                ),
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ink, width: 1.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 10, color: const Color(0xFF171923)),
                      const SizedBox(width: 2),
                      Text(
                        rankLabel,
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF171923),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Player name
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: isFirst ? 13 : 11.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : ink,
            ),
          ),

          const SizedBox(height: 2),

          // Total XP & Level
          Text(
            '${entry.totalXp} XP • Lv ${entry.level}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF596174),
            ),
          ),

          if (entry.streakDays != null && entry.streakDays! >= 2) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 13,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 2),
                Text(
                  '${entry.streakDays}',
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (reduceMotion) return card;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (rank == 1 ? 0 : 150)),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - t)),
        child: Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: child,
        ),
      ),
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
        for (int i = 0; i < entries.length; i++)
          _PlayerCard(
            entry: entries[i],
            index: i,
            isMe: entries[i].rank == currentUserRank,
          ),
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
    const ink = Color(0xFF171923);

    final card = Semantics(
      label: 'Rank ${entry.rank}, ${entry.displayName}, Level ${entry.level}, ${entry.totalXp} XP',
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? (isDark ? const Color(0xFF1E2B45) : const Color(0xFFEDF4FF))
              : (isDark ? const Color(0xFF1E232F) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe ? const Color(0xFF3B82F6) : ink,
            width: isMe ? 2.5 : 2.0,
          ),
          boxShadow: isMe ? NeoBrutalShadows.hardSm : NeoBrutalShadows.hardXs,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isMe ? const Color(0xFF3B82F6) : (isDark ? Colors.white70 : ink),
                ),
              ),
            ),
            LeaderboardAvatarView(avatar: entry.avatar, displayName: entry.displayName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lv ${entry.level} • ${entry.totalXp} XP',
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF596174),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (entry.isMe)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6), // Electric Blue
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ink, width: 1.8),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              )
            else if (entry.rankDelta != null)
              _RankDelta(delta: entry.rankDelta!),
            if (entry.streakDays != null && entry.streakDays! >= 2) ...[
              const SizedBox(width: 6),
              const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFEF4444)),
              const SizedBox(width: 2),
              Text(
                '${entry.streakDays}',
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (reduce) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppMotion.fast + Duration(milliseconds: index * 30),
      curve: AppMotion.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: child,
        ),
      ),
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
    final color = isUp
        ? const Color(0xFF10B981) // Emerald Green
        : (isDown ? const Color(0xFFEF4444) : const Color(0xFF596174));
    final label = isUp ? '↑ $delta' : (isDown ? '↓ ${delta.abs()}' : '—');
    return Semantics(
      label: isUp ? 'rank up $delta' : (isDown ? 'rank down ${delta.abs()}' : 'rank unchanged'),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.displayFamily,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
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
        for (int i = 0; i < nearby.length; i++)
          _PlayerCard(
            entry: nearby[i],
            index: i,
            isMe: nearby[i].isMe,
          ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalPlayers,
    required this.onLoadMore,
    required this.onRefresh,
  });
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
        Expanded(
          child: Text(
            '$totalPlayers champions • Page $page of $totalPages',
            style: const TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF596174),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (!isLast)
          PressableScale(
            onTap: onLoadMore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF171923), width: 2.0),
                boxShadow: NeoBrutalShadows.hardXs,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LOAD MORE',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.expand_more_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          )
        else
          PressableScale(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD43B),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF171923), width: 2.0),
                boxShadow: NeoBrutalShadows.hardXs,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'REFRESH',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF171923),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF171923)),
                ],
              ),
            ),
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
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E232F)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF171923), width: 2.0),
                boxShadow: NeoBrutalShadows.hardXs,
              ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF171923), width: 2.5),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD43B), // Game Yellow
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF171923), width: 2.5),
              boxShadow: NeoBrutalShadows.hardXs,
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 32, color: Color(0xFF171923)),
          ),
          const SizedBox(height: 14),
          Text(
            isSubject ? 'NO CHAMPIONS YET' : 'NO CHAMPIONS YET',
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF171923),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isSubject && subjectName != null
                ? 'Be the first champion of $subjectName. Take the assessment or play to join.'
                : 'Start your learning journey and become the first champion.',
            style: const TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 13,
              color: Color(0xFF596174),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PressableScale(
            onTap: () => context.go(Routes.subjects),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF171923), width: 2.0),
                boxShadow: NeoBrutalShadows.hardXs,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Explore worlds',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
