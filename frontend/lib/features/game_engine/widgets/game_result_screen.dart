import 'dart:convert';
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
import '../../../shared/widgets/celebrations.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/xp_bar.dart';
import '../../gamification/data/gamification_repository.dart';
import '../../gamification/models/game_result_models.dart';
import '../models/game_models.dart';

/// Polished result screen for all games. Displays score/accuracy/xp/combo/time.
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

class _GameResultScreenState extends ConsumerState<GameResultScreen> with TickerProviderStateMixin {
  bool _shown = false;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.celebration);
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    ref.read(hapticsProvider).celebrate();
    _submitResultPersistent();
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
      await AchievementUnlockOverlay.show(context, name: a.name, description: a.description, iconKey: a.iconKey, xpReward: a.xpReward);
    }
  }

  Future<void> _submitResultPersistent() async {
    final r = widget.result;
    final gameType = r.config.type.id;
    final clientRequestId = _deterministicClientRequestId(gameType, r.score, r.timeElapsedSeconds, r.comboMax);
    final submission = GameResultSubmission(
      clientRequestId: clientRequestId,
      gameType: gameType,
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

  String _deterministicClientRequestId(String gameType, int score, int durationSeconds, int bestCombo) {
    final prefix = '$gameType-${score}-${durationSeconds}-${bestCombo}';
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    // UUID v4 layout: set version (6) and variant (8)
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

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final d = widget.gamificationDelta;
    final atPerfect = r.isPerfect;

    return Scaffold(
      appBar: AppBar(title: const Text('MISSION COMPLETE'), automaticallyImplyLeading: false),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              const SizedBox(height: 10),
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
                          duration: AppMotion.celebration,
                          curve: AppMotion.decelerate,
                          builder: (context, value, _) => CircularProgressIndicator(
                            value: value,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            color: _scoreColor(r.accuracy),
                            backgroundColor: AppColors.surfaceHigh,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(r.performanceLabel), size: 18, color: _scoreColor(r.accuracy)),
                          const SizedBox(height: 4),
                          AnimatedCounter(value: r.accuracy.round(), style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 52, fontWeight: FontWeight.w700, color: _scoreColor(r.accuracy)), suffix: '%'),
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
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${r.config.type.displayName} • ${r.config.difficulty.displayName.toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                ),
              ),
              if (r.config.topicName != null) ...[
                const SizedBox(height: 4),
                Center(child: Text(r.config.topicName!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 17, fontWeight: FontWeight.w700))),
              ],
              const SizedBox(height: 18),
              // Score + details grid
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
              // XP card (backend delta if available, else local preview)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.xp.withValues(alpha: 0.12), AppColors.surfaceElevated]),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.xp.withValues(alpha: 0.4)),
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
                          if (d?.leveledUpTo != null) Text('Level up! → ${d!.leveledUpTo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBright)),
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
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.35))),
                  child: const Row(children: [Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.success), SizedBox(width: 8), Text('NEW PERSONAL BEST!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 1))]),
                ),
              ],
              const SizedBox(height: 22),
              if (widget.onReplay != null)
                SecondaryGameButton(label: 'Play again', icon: Icons.replay_rounded, onTap: widget.onReplay!),
              const SizedBox(height: 10),
              PrimaryGameButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onTap: widget.onContinue ?? () => context.go(Routes.home),
              ),
              if (widget.onReplay != null) const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('RETURN TO BASE'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
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
