import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_manager.dart' show MusicContext;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/gamification_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/stat_card.dart';

/// GAM-003 streak visualization. Motivating, never pressuring.
class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  late Future<StreakState> _future;
  late Future<GamificationSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.dashboard);
    final repo = ref.read(gamificationRepoProvider);
    _future = repo.streak();
    _summaryFuture = repo.summary();
  }

  void _reload() => setState(() {
    final repo = ref.read(gamificationRepoProvider);
    _future = repo.streak();
    _summaryFuture = repo.summary();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STREAK')),
      body: RefreshIndicator(
        color: AppColors.streak,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([_future, _summaryFuture]),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done && !snap.hasData) {
              return ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [SkeletonList(itemCount: 3, itemHeight: 110)],
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
            final streak = snap.data![0] as StreakState;
            final summary = snap.data![1] as GamificationSummary;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: AppMotion.feature,
                    curve: AppMotion.spring,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: _Flame(days: streak.currentStreakDays),
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '${streak.currentStreakDays} ',
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: AppColors.streak,
                          ),
                        ),
                        const TextSpan(text: 'day streak'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _motivation(streak.currentStreakDays),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Milestone track (3/7/14/30 are the documented one-shot
                // bonus days; rendered as visual markers only).
                GameCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MOMENTUM TRACK',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (final m in const [3, 7, 14, 30])
                            Expanded(
                              child: _MilestoneMarker(
                                day: m,
                                reached: streak.currentStreakDays >= m,
                                isLongest:
                                    streak.longestStreakDays >= m &&
                                    streak.currentStreakDays < m,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'LONGEST',
                        value: '${streak.longestStreakDays}',
                        sub: 'days',
                        tint: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'TOTAL XP',
                        value: Formatters.count(summary.totalXp),
                        sub: 'collected',
                        tint: AppColors.xp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (streak.lastLearningDate != null)
                  Text(
                    'Last activity: ${Formatters.shortDate(streak.lastLearningDate)} Â· '
                    'Timezone ${streak.timezone}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  )
                else
                  const Text(
                    'Complete a challenge to start your streak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _motivation(int days) => switch (days) {
    0 => 'Every legend starts at zero.',
    < 3 => 'The flame is lit - keep it burning.',
    < 7 => 'Momentum building. Three-day rhythm unlocked.',
    < 14 => 'A full week of learning. Impressive discipline.',
    < 30 => 'Two weeks strong. You are on fire.',
    _ => 'Legendary consistency.',
  };
}

class _Flame extends StatelessWidget {
  const _Flame({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final active = days > 0;
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? null
            : const LinearGradient(
                colors: [AppColors.surfaceHigh, AppColors.surface],
              ),
        boxShadow: [
          BoxShadow(
            color: (active ? AppColors.streak : AppColors.locked).withValues(
              alpha: 0.35,
            ),
            blurRadius: 44,
            spreadRadius: 4,
          ),
        ],
        border: Border.all(
          color: active
              ? AppColors.streak.withValues(alpha: 0.7)
              : AppColors.border,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.local_fire_department_rounded,
        size: 62,
        color: active ? AppColors.streak : AppColors.textTertiary,
      ),
    );
  }
}

class _MilestoneMarker extends StatelessWidget {
  const _MilestoneMarker({
    required this.day,
    required this.reached,
    required this.isLongest,
  });

  final int day;
  final bool reached;
  final bool isLongest;

  @override
  Widget build(BuildContext context) {
    final tint = reached
        ? AppColors.streak
        : (isLongest ? AppColors.secondary : AppColors.locked);
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached
                ? AppColors.streak.withValues(alpha: 0.25)
                : AppColors.surfaceHigh,
            border: Border.all(color: tint.withValues(alpha: 0.7)),
          ),
          child: reached
              ? const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: AppColors.streak,
                )
              : Center(
                  child: Text(
                    '$day',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text('${day}d', style: TextStyle(fontSize: 10, color: tint)),
      ],
    );
  }
}
