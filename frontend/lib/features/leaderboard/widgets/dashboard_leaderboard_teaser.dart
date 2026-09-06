import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../providers/leaderboard_providers.dart';
import 'leaderboard_avatar.dart';

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
            OutlinedButton(
              onPressed: () => ref.read(myPositionProvider.notifier).refreshOverall(),
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    final rank = data?.rank ?? 0;
    final xp = data?.totalXp ?? 0;
    final xpToNext = data?.xpToNextRank;
    final top = data?.top ?? [];

    return Semantics(
      label: 'Champions Arena teaser, rank $rank, $xp XP',
      child: GameChallengeSurface(
        accent: AppColors.primary,
        title: 'CHAMPIONS ARENA',
        icon: Icons.emoji_events_rounded,
        subtitle: rank == 1 ? 'TOP OF THE ARENA' : 'YOUR RANK',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (data?.avatar != null)
                  LeaderboardAvatarView(
                    avatar: data!.avatar!,
                    displayName: 'You',
                    size: 44,
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
                      border: Border.all(color: AppColors.primaryBright, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text('#$rank', style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rank == 1 ? 'YOU\'RE #1' : 'YOU\'RE #$rank', style: AppTypography.h3(context)),
                      const SizedBox(height: 2),
                      Text('$xp XP${xpToNext != null ? ' • $xpToNext XP to #${rank - 1}' : ''}', style: AppTypography.caption(context)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.push(Routes.arena),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('VIEW ARENA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ),
              ],
            ),
            if (top.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int i = 0; i < top.length && i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
                          ),
                          child: Column(
                            children: [
                              Text('#${top[i].rank}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
                              const SizedBox(height: 2),
                              Text(top[i].displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                              Text('${top[i].totalXp} XP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (xpToNext != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _progress(xp, xpToNext),
                  minHeight: 4,
                  backgroundColor: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
