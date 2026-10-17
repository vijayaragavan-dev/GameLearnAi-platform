import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../../../core/models/mascot_character.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../avatar/providers/active_mascot_provider.dart';
import '../../avatar/widgets/cartoon_mascot_view.dart';
import '../providers/leaderboard_providers.dart';

/// Compact dashboard teaser — uses GET /api/v1/me/leaderboard-position
/// via dashboardLeaderboardProvider. Never fetches full leaderboard.
class DashboardLeaderboardTeaser extends ConsumerWidget {
  const DashboardLeaderboardTeaser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(myPositionProvider);
    final data = posAsync.data;
    final error = posAsync.error;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (posAsync.showLoading && data == null) {
      return Container(
        height: 88,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
        ),
        child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (error != null && data == null) {
      return GameChallengeSurface(
        accent: AppColors.primary,
        title: 'CHAMPIONS ARENA',
        icon: Icons.emoji_events_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arena offline', style: AppTypography.bodySecondary(context)),
            const SizedBox(height: 8),
            GameChip(label: 'RETRY', icon: Icons.refresh_rounded, onTap: () => ref.read(myPositionProvider.notifier).refreshOverall()),
          ],
        ),
      );
    }

    // No data and no error (e.g. reset/invalidation race): never render
    // a fabricated #0 rank. Show the honest unavailable state instead.
    if (data == null) {
      return GameChallengeSurface(
        accent: AppColors.primary,
        title: 'CHAMPIONS ARENA',
        icon: Icons.emoji_events_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rank unavailable right now',
              style: AppTypography.bodySecondary(context),
            ),
            const SizedBox(height: 8),
            GameChip(label: 'RETRY', icon: Icons.refresh_rounded, onTap: () => ref.read(myPositionProvider.notifier).refreshOverall()),
          ],
        ),
      );
    }

    final activeMascot = ref.watch(activeMascotProvider);
    final rank = data.rank;
    final xp = data.totalXp;
    final xpToNext = data.xpToNextRank;
    final top = data.top;

    return Semantics(
      label: 'Champions Arena teaser, rank $rank, $xp XP',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: const Color(0xFF171923), width: 2.5),
          boxShadow: NeoBrutalShadows.hard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B82F6),
                    border: Border.all(color: const Color(0xFF171923), width: 2),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CHAMPIONS ARENA',
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFF171923),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE9FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF171923), width: 1.5),
                  ),
                  child: Text(
                    rank == 1 ? 'TOP OF THE ARENA' : 'YOUR RANK',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF171923),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF171923), width: 2.2),
                        boxShadow: NeoBrutalShadows.hardXs,
                      ),
                      alignment: Alignment.center,
                      child: CartoonMascotView(
                        character: activeMascot.character,
                        accessory: activeMascot.accessory,
                        mood: MascotMood.idle,
                        size: 42,
                        isAnimated: false,
                      ),
                    ),
                    Positioned(
                      right: -5,
                      bottom: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD43B),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF171923), width: 1.5),
                          boxShadow: NeoBrutalShadows.hardXs,
                        ),
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF171923),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rank == 1 ? 'YOU\'RE #1' : 'YOU\'RE #$rank',
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF171923),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$xp XP${xpToNext != null ? ' • $xpToNext XP to #${rank - 1}' : ''}',
                        style: const TextStyle(
                          fontFamily: AppTypography.bodyFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF596174),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push(Routes.arena),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD43B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF171923), width: 2.0),
                      boxShadow: NeoBrutalShadows.hardXs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFF171923)),
                        SizedBox(width: 4),
                        Text(
                          'VIEW ARENA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF171923),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (top.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  for (int i = 0; i < top.length && i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5EF),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: const Color(0xFF171923), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '#${top[i].rank}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF596174),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                top[i].displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF171923),
                                ),
                              ),
                              Text(
                                '${top[i].totalXp} XP',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF596174),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (xpToNext != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _progress(xp, xpToNext),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _progress(int myXp, int xpToNext) {
    final above = myXp + xpToNext - 1;
    if (above <= 0) return 0;
    return (myXp / above).clamp(0.0, 1.0);
  }
}
