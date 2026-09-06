import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/gamification_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/xp_bar.dart' show XPBar;
import '../../avatar/providers/avatar_providers.dart';
import '../../avatar/widgets/avatar_visual.dart';

/// USER-001 player profile with premium progression clarity — only backend-provided fields.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<(LearnerProfile, GamificationSummary)> _future;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.menu);
    _reload();
  }

  void _reload() {
    setState(() {
      final repo = ref.read(gamificationRepoProvider);
      _future = () async {
        final profile = await repo.profile();
        final summary = await repo.summary();
        return (profile, summary);
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PLAYER PROFILE'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined, size: 21),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AtmosphericBackground(
              primaryGlow: AppColors.primary,
              secondaryGlow: AppColors.secondary,
              intensity: isDark ? 0.52 : 0.0,
              showStarField: true,
            ),
          ),
          if (isDark) ...[
            Positioned(top: -30, right: -20, child: GlowOrb(color: AppColors.primary, size: 220, opacity: 0.08)),
            Positioned(bottom: 120, left: -30, child: GlowOrb(color: AppColors.secondary, size: 180, opacity: 0.05)),
          ],
          RefreshIndicator(
            color: AppColors.primaryBright,
            backgroundColor: AppColors.surfaceElevated,
            onRefresh: () async => _reload(),
            child: FutureBuilder<(LearnerProfile, GamificationSummary)>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done && !snap.hasData) {
                  return ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: const [SkeletonList(itemCount: 3, itemHeight: 120)],
                  );
                }
                if (snap.hasError) {
                  final err = describeError(snap.error!);
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [ErrorState(title: err.title, message: err.message, onRetry: _reload)],
                  );
                }
                final (profile, summary) = snap.data!;
                final atMax = summary.atMaxLevel;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  children: [
                    ResponsiveCenter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 6),
                          // YOUR CHARACTER hero — premium, real avatar
                          Consumer(
                            builder: (context, ref, _) {
                              final avatarState = ref.watch(profileAvatarProvider);
                              final avatar = avatarState.data;
                              final displayName = avatar?.avatar?.displayName ?? 'Nova Spark';
                              final rarity = avatar?.avatar?.rarity ?? 'INITIATE';
                              final assetKey = avatar?.avatar?.assetKey ?? 'characters/nova_spark';
                              return Column(
                                children: [
                                  Semantics(
                                    label: 'Your character $displayName, $rarity',
                                    child: FeaturedSurface(
                                      accent: rarity.toLowerCase() == 'legendary' ? AppColors.xp : AppColors.primary,
                                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                                      child: Column(
                                        children: [
                                          Text('YOUR CHARACTER', style: AppTypography.overline(context).copyWith(color: AppColors.primaryBright, letterSpacing: 1.4)),
                                          const SizedBox(height: 12),
                                          Stack(
                                            clipBehavior: Clip.none,
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              AvatarVisual(assetKey: assetKey, displayName: displayName, rarity: rarity, size: 92, showGlow: true, showRarityBadge: true),
                                              const Positioned(bottom: -2, right: -2, child: NovaCompanion(size: 28, mood: NovaMood.idle)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(displayName.toUpperCase(), style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5), textAlign: TextAlign.center),
                                          Text(rarity.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primary)),
                                          const SizedBox(height: 8),
                                          Text(profile.displayName, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 15, fontWeight: FontWeight.w700)),
                                          Text(profile.email, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.primary.withValues(alpha: 0.22))),
                                            child: Text('LEVEL ${profile.currentLevel} • ${Formatters.count(profile.totalXp)} XP', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primary)),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton.icon(
                                              onPressed: () => context.push('/profile/characters'),
                                              icon: const Icon(Icons.collections_rounded, size: 16),
                                              label: const Text('CHANGE CHARACTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                                              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          // Level / XP — consistent language XP / LEVEL everywhere
                          GameChallengeSurface(
                            accent: AppColors.primary,
                            title: 'PROGRESSION',
                            icon: Icons.trending_up_rounded,
                            subtitle: atMax ? 'MAX LEVEL' : 'LEVEL ${profile.currentLevel} → ${profile.currentLevel + 1}',
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    LevelBadge(level: profile.currentLevel, size: 58),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: XPBar(
                                        currentLevel: profile.currentLevel,
                                        totalXp: profile.totalXp,
                                        xpToNextLevel: summary.xpToNextLevel,
                                        showLabels: true,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!atMax && summary.xpToNextLevel != null) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('${summary.xpToNextLevel} XP TO NEXT LEVEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
                                  ),
                                ],
                                if (atMax) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: AppColors.xp.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.xp.withValues(alpha: 0.24))),
                                    child: Row(children: [const Icon(Icons.emoji_events_rounded, size: 14, color: AppColors.xp), const SizedBox(width: 6), const Expanded(child: Text('MAX LEVEL REACHED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.xp)))]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(label: 'TOTAL XP', value: Formatters.count(profile.totalXp), tint: AppColors.xp),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => context.go(Routes.streak),
                                  child: StatCard(label: 'STREAK', value: '${summary.currentStreakDays}', sub: 'days', tint: AppColors.streak),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => context.go(Routes.achievements),
                                  child: StatCard(label: 'BADGES', value: '${summary.unlockedAchievements}', tint: AppColors.secondary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(label: 'MASTERY', value: Formatters.percent(profile.overallMastery), tint: AppColors.success),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Longest streak + clear next action when real data minimal
                          if (summary.longestStreakDays > summary.currentStreakDays)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
                              child: Row(children: [Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.streak), const SizedBox(width: 6), Text('LONGEST STREAK ${summary.longestStreakDays} DAYS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))]),
                            ),
                          if (summary.currentStreakDays == 0 && summary.unlockedAchievements == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [Icon(Icons.rocket_launch_rounded, size: 16, color: AppColors.primary), const SizedBox(width: 8), const Text("WHAT'S NEXT?", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textTertiary))]),
                                    const SizedBox(height: 8),
                                    Text('Complete your first game to earn XP and unlock your first badge. Your streak starts with a single day of learning.', style: TextStyle(fontSize: 12.5, height: 1.4, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
