import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/gamification_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/achievement_icon.dart';
import '../../../shared/widgets/feedback.dart';

/// GAM-002 trophy room: unlocked badges glow, locked stay dark.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late Future<List<Achievement>> _future;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.dashboard);
    _future = ref.read(gamificationRepoProvider).achievements();
  }

  void _reload() => setState(() {
    _future = ref.read(gamificationRepoProvider).achievements();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TROPHY ROOM')),
      body: FutureBuilder<List<Achievement>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: SkeletonAchievementGrid(),
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
          final achievements = snap.data ?? const <Achievement>[];
          // Catalog order is backend-defined; do not re-sort semantics,
          // but present unlocked first for motivation.
          final unlocked = achievements.where((a) => a.isUnlocked).toList();
          final locked = achievements.where((a) => !a.isUnlocked).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              Row(
                children: [
                  Text(
                    '${unlocked.length}/${achievements.length} UNLOCKED',
                    style: const TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.xp,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: AppColors.xp,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, i) {
                  final a = achievements[i];
                  return _BadgeCell(
                    achievement: a,
                    onTap: () => context.push(Routes.badge(a.code), extra: a),
                  );
                },
              ),
              if (locked.isNotEmpty && unlocked.isEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Win challenges to light up your trophy room.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BadgeCell extends StatefulWidget {
  const _BadgeCell({required this.achievement, required this.onTap});

  final Achievement achievement;
  final VoidCallback onTap;

  @override
  State<_BadgeCell> createState() => _BadgeCellState();
}

class _BadgeCellState extends State<_BadgeCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: AppMotion.feature);
    if (widget.achievement.isUnlocked) _glow.repeat(reverse: true);
    _glow.forward();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_glow.value);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: a.isUnlocked
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.xp.withValues(alpha: 0.10 + 0.08 * t),
                        AppColors.surfaceElevated,
                      ],
                    )
                  : null,
              color: a.isUnlocked
                  ? null
                  : AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: a.isUnlocked
                    ? AppColors.xp.withValues(alpha: 0.4 + 0.2 * t)
                    : AppColors.border,
              ),
              boxShadow: a.isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.xp.withValues(alpha: 0.12 + 0.1 * t),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AchievementIcon(
                  iconKey: a.iconKey,
                  unlocked: a.isUnlocked,
                  size: 62,
                ),
                const SizedBox(height: 10),
                Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: a.isUnlocked
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      a.isUnlocked
                          ? Icons.check_circle_outline_rounded
                          : Icons.lock_outline_rounded,
                      size: 11,
                      color: a.isUnlocked
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      a.isUnlocked
                          ? Formatters.shortDate(a.unlockedAt)
                          : '+${a.xpReward} XP',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: a.isUnlocked
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
