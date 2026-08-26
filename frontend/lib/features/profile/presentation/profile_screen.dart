import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/gamification_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/xp_bar.dart' show XPBar;

/// USER-001 player profile. Only backend-provided fields are displayed.
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
      body: RefreshIndicator(
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
              return ErrorState(
                title: err.title,
                message: err.message,
                onRetry: _reload,
              );
            }
            final (profile, summary) = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                const SizedBox(height: 6),
                Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5B21B6), AppColors.primary],
                            ),
                            border: Border.all(
                              color: AppColors.primaryBright,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 26,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              profile.displayName.isEmpty
                                  ? '?'
                                  : profile.displayName[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const NovaCompanion(size: 30, mood: NovaMood.idle),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      profile.email,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: LevelBadge(level: profile.currentLevel, size: 58),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: XPBar(
                        currentLevel: profile.currentLevel,
                        totalXp: profile.totalXp,
                        xpToNextLevel: summary.xpToNextLevel,
                        showLabels: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'TOTAL XP',
                        value: Formatters.count(profile.totalXp),
                        tint: AppColors.xp,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go(Routes.streak),
                        child: StatCard(
                          label: 'STREAK',
                          value: '${summary.currentStreakDays}',
                          sub: 'days',
                          tint: AppColors.streak,
                        ),
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
                        child: StatCard(
                          label: 'BADGES',
                          value: '${summary.unlockedAchievements}',
                          tint: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'MASTERY',
                        value: Formatters.percent(profile.overallMastery),
                        tint: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
