import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext;
import '../../../core/gamification_delta.dart';
import '../../../core/models/gamification_models.dart';
import '../../../core/providers.dart';
import '../../gamification/providers/game_results_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/intelligence/learner_intelligence.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../shared/widgets/adaptive_next_action.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/theme/game_visual_identity.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/celebrations.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/xp_bar.dart';
import '../../gamification/models/game_result_models.dart';
import '../models/game_models.dart';

/// Premium result screen for all games. Displays score/accuracy/xp/combo/time with game identity.
class GameResultScreen extends ConsumerStatefulWidget {
  const GameResultScreen({
    super.key,
    required this.result,
    this.gamificationDelta,
    this.onReplay,
    this.onContinue,
  });

  final GameResult result;
  final GamificationDelta? gamificationDelta;
  final VoidCallback? onReplay;
  final VoidCallback? onContinue;

  @override
  ConsumerState<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends ConsumerState<GameResultScreen>
    with TickerProviderStateMixin {
  bool _shown = false;
  bool _submitted = false;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.celebration);
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    ref.read(hapticsProvider).celebrate();
    _submitResultPersistent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Idempotent guard: hot-reload or re-parent must not re-submit same result.
    // Submission is owned by initState only; didChangeDependencies is no-op by design.
  }

  Future<void> _celebrate() async {
    if (_shown) return;
    _shown = true;
    final d = widget.gamificationDelta;
    if (d?.leveledUpTo != null) {
      await LevelUpOverlay.show(context, newLevel: d!.leveledUpTo!);
    }
    for (final Achievement a in d?.newAchievements ?? const <Achievement>[]) {
      if (!mounted) return;
      await AchievementUnlockOverlay.show(
        context,
        name: a.name,
        description: a.description,
        iconKey: a.iconKey,
        xpReward: a.xpReward,
      );
    }
  }

  Future<void> _submitResultPersistent() async {
    if (_submitted) return;
    _submitted = true;
    final r = widget.result;
    final gameType = r.config.type.id;
    final clientRequestId = _deterministicClientRequestId(
      gameType,
      r.score,
      r.timeElapsedSeconds,
      r.comboMax,
    );
    final submission = GameResultSubmission(
      clientRequestId: clientRequestId,
      gameType: gameType,
      difficulty: r.config.difficulty.apiValue,
      completed: true,
      score: r.score,
      durationSeconds: r.timeElapsedSeconds,
      bestCombo: r.comboMax,
    );
    try {
      await ref.read(gameResultsProvider.notifier).submit(submission);
    } catch (_) {
      // Network blip: dashboard refetches on next read; never block the player.
    }
  }

  String _deterministicClientRequestId(
    String gameType,
    int score,
    int durationSeconds,
    int bestCombo,
  ) {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  IconData _statusIcon(String label) {
    return switch (label) {
      'LEGENDARY' => Icons.emoji_events_rounded,
      'EXCELLENT' => Icons.star_rounded,
      'GOOD' => Icons.thumb_up_rounded,
      'FAIR' => Icons.trending_up_rounded,
      _ => Icons.replay_rounded,
    };
  }

  int _starsForAccuracy(double acc) {
    if (acc >= 90) return 5;
    if (acc >= 75) return 4;
    if (acc >= 50) return 3;
    if (acc >= 30) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final d = widget.gamificationDelta;
    final atPerfect = r.isPerfect;
    final isVictory = r.isSuccess;
    final identity = GameVisualRegistry.of(r.config.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = AppMotion.reducedMotion(context);
    final stars = _starsForAccuracy(r.accuracy);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MISSION COMPLETE'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Atmospheric game world
          Positioned.fill(
            child: AtmosphericBackground(
              primaryGlow: identity.accent,
              secondaryGlow: AppColors.secondary,
              intensity: isDark ? 0.68 : 0.0,
              showStarField: true,
            ),
          ),
          if (isDark) ...[
            Positioned(top: -30, right: -20, child: GlowOrb(color: identity.accent, size: 240, opacity: 0.10)),
            Positioned(bottom: 100, left: -40, child: GlowOrb(color: AppColors.secondary, size: 200, opacity: 0.06)),
          ],
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              ResponsiveCenter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Game identity header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [identity.accent.withValues(alpha: isDark ? 0.14 : 0.07), Theme.of(context).colorScheme.surface]),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: identity.accent.withValues(alpha: isDark ? 0.28 : 0.18)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: identity.gradient, border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
                            child: Icon(identity.icon, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.config.type.displayName.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: identity.accent)),
                                Text(r.config.topicName ?? r.config.topicId, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh, borderRadius: BorderRadius.circular(999), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
                            child: Text(r.config.difficulty.displayName.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Victory / Completion hero
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isVictory
                              ? (isDark ? [identity.accent.withValues(alpha: 0.16), AppColors.surfaceElevated] : [identity.accent.withValues(alpha: 0.07), AppLightColors.surface])
                              : (isDark ? [AppColors.error.withValues(alpha: 0.10), AppColors.surfaceElevated] : [AppColors.error.withValues(alpha: 0.06), AppLightColors.surface]),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: (isVictory ? identity.accent : AppColors.error).withValues(alpha: isDark ? 0.32 : 0.20), width: 1.2),
                        boxShadow: [BoxShadow(color: (isVictory ? identity.accent : AppColors.error).withValues(alpha: isDark ? 0.14 : 0.06), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isVictory ? AppColors.success : AppColors.error).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: (isVictory ? AppColors.success : AppColors.error).withValues(alpha: 0.32)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isVictory ? Icons.emoji_events_rounded : Icons.replay_rounded, size: 14, color: isVictory ? AppColors.success : AppColors.error),
                                const SizedBox(width: 6),
                                Text(isVictory ? 'VICTORY' : 'MISSION COMPLETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: isVictory ? AppColors.success : AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Stars — deterministic from accuracy
                          Semantics(
                            label: '$stars of 5 stars',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                final filled = i < stars;
                                final delay = reduceMotion ? Duration.zero : AppMotion.staggerDelay(i);
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: reduceMotion ? Duration.zero : AppMotion.normal + delay,
                                  curve: AppMotion.easeOut,
                                  builder: (context, v, child) => Opacity(opacity: v, child: Transform.scale(scale: 0.85 + 0.15 * v, child: child)),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                                    child: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, size: 28, color: filled ? AppColors.xp : (isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Score dominant
                          Semantics(
                            label: 'Score ${r.score}',
                            child: AnimatedCounter(
                              value: r.score,
                              duration: reduceMotion ? Duration.zero : AppMotion.celebration,
                              style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 48, fontWeight: FontWeight.w800, color: isVictory ? identity.accent : AppColors.textSecondary),
                            ),
                          ),
                          Text('SCORE', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
                          const SizedBox(height: 10),
                          // Accuracy ring + metrics row
                          Center(
                            child: Semantics(
                              label: 'Accuracy ${r.accuracy.round()} percent, ${r.performanceLabel}',
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 168,
                                    height: 168,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: r.accuracy / 100),
                                      duration: reduceMotion ? Duration.zero : AppMotion.celebration,
                                      curve: AppMotion.decelerate,
                                      builder: (context, value, _) => CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 9,
                                        strokeCap: StrokeCap.round,
                                        color: _scoreColor(r.accuracy),
                                        backgroundColor: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_statusIcon(r.performanceLabel), size: 18, color: _scoreColor(r.accuracy)),
                                      const SizedBox(height: 4),
                                      AnimatedCounter(
                                        value: r.accuracy.round(),
                                        style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 52, fontWeight: FontWeight.w700, color: _scoreColor(r.accuracy)),
                                        suffix: '%',
                                      ),
                                      Text('${r.correctCount} / ${r.totalQuestions} CORRECT', style: const TextStyle(fontSize: 11.5, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _scoreColor(r.accuracy).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: _scoreColor(r.accuracy).withValues(alpha: 0.4))),
                                        child: Text(r.performanceLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _scoreColor(r.accuracy))),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text('${r.config.type.displayName} • ${r.config.difficulty.displayName.toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.secondary, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                    ),
                    if (r.config.topicName != null) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: Text(r.config.topicName!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    // Metrics grid — real data only
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'SCORE', value: '${r.score}', icon: Icons.star_rounded, color: AppColors.xp)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(label: 'COMBO', value: 'x${r.comboMax}', icon: Icons.local_fire_department_rounded, color: AppColors.streak)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(label: 'TIME', value: _fmt(r.timeElapsedSeconds), icon: Icons.timer_rounded, color: AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // XP reward — real delta or local preview, never fabricated
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.xp.withValues(alpha: isDark ? 0.12 : 0.07), isDark ? AppColors.surfaceElevated : AppLightColors.surface]),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.xp.withValues(alpha: isDark ? 0.32 : 0.20)),
                        boxShadow: isDark ? [BoxShadow(color: AppColors.xp.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 4))] : null,
                      ),
                      child: Row(
                        children: [
                          const NovaCompanion(size: 44, mood: NovaMood.celebrating),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('XP EARNED', style: TextStyle(fontSize: 10.5, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.xp)),
                                const SizedBox(height: 3),
                                if (d != null && d.xpGained > 0)
                                  Text('+${d.xpGained} XP', style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.xp))
                                else if (r.xpEarned > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('+${r.xpEarned} XP', style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.xp)),
                                      if (r.config.type != GameType.quizBattle && r.config.type != GameType.speedRun)
                                        const Text('Local preview • Quiz games award real XP', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                    ],
                                  )
                                else
                                  const Text('No XP this run', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                if (d?.leveledUpTo != null)
                                  Text('Level up! → ${d!.leveledUpTo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBright)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (r.bestScore != null && r.score >= r.bestScore!) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.32))),
                        child: const Row(children: [Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.success), SizedBox(width: 8), Text('NEW PERSONAL BEST!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 1))]),
                      ),
                    ],
                    // Adaptive: mastery updated + personalized next (A6)
                    const SizedBox(height: 14),
                    _AdaptiveResultInsight(result: r),
                    const SizedBox(height: 22),
                    // What's next — premium actions with contextual navigation (no dead-end)
                    Text("WHAT'S NEXT?", style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
                    const SizedBox(height: 10),
                    if (widget.onReplay != null)
                      SecondaryGameButton(label: 'Play again', icon: Icons.replay_rounded, onTap: widget.onReplay!),
                    if (widget.onReplay != null) const SizedBox(height: 10),
                    Semantics(
                      button: true,
                      label: 'Continue to next learning action',
                      child: PrimaryGameButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        onTap: widget.onContinue ?? () {
                          final sid = r.config.subjectId;
                          final sname = r.config.subjectName;
                          if (sid != null && sid.isNotEmpty) {
                            context.go(Routes.gameHub(r.config.topicId, subjectId: sid, subjectName: sname), extra: r.config.topicName);
                          } else {
                            context.go(Routes.home);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: 'Return to dashboard',
                      child: TextButton(
                        onPressed: () => context.go(Routes.home),
                        child: const Text('RETURN TO BASE'),
                      ),
                    ),
                    // Contextual secondary: back to arena when subject available
                    if (r.config.subjectId != null && r.config.subjectId!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () => context.go(Routes.gameHub(r.config.topicId, subjectId: r.config.subjectId, subjectName: r.config.subjectName), extra: r.config.topicName),
                        icon: const Icon(Icons.stadium_rounded, size: 16),
                        label: Text('BACK TO ARENA • ${r.config.subjectName ?? 'World'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (atPerfect || (d?.xpGained ?? 0) > 0) const Positioned.fill(child: ConfettiEffect()),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Color _scoreColor(double s) => s >= 80 ? AppColors.success : s >= 50 ? AppColors.warning : AppColors.error;
}

class _AdaptiveResultInsight extends ConsumerWidget {
  const _AdaptiveResultInsight({required this.result});
  final GameResult result;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Dashboard? dash;
    try {
      dash = ref.watch(dashboardProvider).data as Dashboard?;
    } catch (_) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (dash == null) return const SizedBox.shrink();
    final intel = AdaptiveEngine.fromDashboard(dash);
    // Show mastery updated or next difficulty hint
    final isWeak = intel.weakTopics.any((w) => w.topicId == result.config.topicId);
    final isStrong = intel.strongTopics.any((s) => s.topicId == result.config.topicId);
    String masteryLine = 'Mastery ${intel.overallMastery.round()}% • ${intel.trend.replaceAll('_', ' ')}';
    String nextLine;
    if (isWeak && result.accuracy < 60) {
      nextLine = 'This concept needs a little more practice — try an easier challenge or ask Tutor.';
    } else if (isStrong && result.accuracy >= 80) {
      nextLine = 'Challenge increased — you are ready for ${intel.nextDifficulty}.';
    } else if (result.accuracy >= 85) {
      nextLine = 'Great work — ready for a harder challenge?';
    } else if (result.accuracy < 50) {
      nextLine = 'Review this concept — a quick practice will help.';
    } else {
      nextLine = 'Keep practicing to build consistency.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.psychology_rounded, size: 14, color: AppColors.primary), const SizedBox(width: 6), Text('YOUR PERFORMANCE INSIGHT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.primary))]),
            const SizedBox(height: 8),
            Text(masteryLine, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
            const SizedBox(height: 4),
            Text(nextLine, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
            const SizedBox(height: 8),
            AdaptiveNextActionCard(
              title: isWeak ? 'Practice ${result.config.topicName ?? 'this topic'}' : (isStrong ? 'Challenge ${result.config.topicName ?? 'next level'}' : 'Continue learning'),
              reason: isWeak ? 'Based on your recent performance' : (isStrong ? 'Strong mastery — level up your challenge' : 'Recommended next step'),
              topicName: result.config.topicName,
              subjectName: result.config.subjectName,
              gameType: isWeak ? 'quiz_battle' : (isStrong ? 'boss_battle' : null),
              difficulty: intel.nextDifficulty,
              actionLabel: isWeak ? 'Practice' : (isStrong ? 'Challenge' : 'Continue'),
              onAction: () {
                if (isWeak) {
                  context.push(Routes.tutorWithContext(topicId: result.config.topicId, topicName: result.config.topicName, focus: result.config.topicName));
                } else if (result.config.subjectId != null) {
                  context.go(Routes.gameHub(result.config.topicId, subjectId: result.config.subjectId, subjectName: result.config.subjectName), extra: result.config.topicName);
                } else {
                  context.go(Routes.home);
                }
              },
            ),
          ]),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppLightColors.border)),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
