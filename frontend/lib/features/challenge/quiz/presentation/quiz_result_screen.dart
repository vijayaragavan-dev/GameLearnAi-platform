import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/models/quiz_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/celebrations.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/nova_companion.dart';
import '../../../../shared/widgets/xp_bar.dart' show AnimatedCounter;
import 'quiz_result_arg.dart';

/// QUIZ-002 result: WHAT HAPPENED -> WHAT YOU EARNED -> WHAT'S NEXT.
/// Every number comes from the backend submission response or GAM reads.
class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key, required this.arg});

  final QuizResultArg arg;

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen>
    with TickerProviderStateMixin {
  bool _celebrationShown = false;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.celebration);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCelebrations());
    ref.read(hapticsProvider).celebrate();
  }

  Future<void> _playCelebrations() async {
    if (_celebrationShown) return;
    _celebrationShown = true;
    // Queue: level-up first, then achievements (EPIC tier, sequential).
    final level = widget.arg.leveledUpTo;
    if (level != null) {
      ref.read(audioManagerProvider).play(Sfx.levelUp);
      await LevelUpOverlay.show(context, newLevel: level);
    }
    for (final a in widget.arg.newAchievements) {
      if (!mounted) return;
      ref.read(audioManagerProvider).play(Sfx.achievementUnlock);
      await AchievementUnlockOverlay.show(
        context,
        name: a.name,
        description: a.description,
        iconKey: a.iconKey,
        xpReward: a.xpReward,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.arg.result;
    final perfect =
        result.correctCount == result.totalQuestions &&
        result.totalQuestions > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHALLENGE COMPLETE'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              const SizedBox(height: 10),

              // ---- WHAT HAPPENED -------------------------------------
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 168,
                      height: 168,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: result.score / 100),
                        duration: AppMotion.celebration,
                        curve: AppMotion.decelerate,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 9,
                              strokeCap: StrokeCap.round,
                              color: scoreColor(result.score),
                              backgroundColor: AppColors.surfaceHigh,
                            ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedCounter(
                          value: result.score.round(),
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: scoreColor(result.score),
                          ),
                          suffix: '%',
                        ),
                        Text(
                          '${result.correctCount} / ${result.totalQuestions} CORRECT',
                          style: const TextStyle(
                            fontSize: 11.5,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  widget.arg.topicName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // ---- WHAT YOU EARNED -----------------------------------
              Container(
                margin: const EdgeInsets.only(top: 26),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.xp.withValues(alpha: 0.12),
                      AppColors.surfaceElevated,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.xp.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const NovaCompanion(size: 44, mood: NovaMood.celebrating),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'XP COLLECTED',
                            style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.xp,
                            ),
                          ),
                          const SizedBox(height: 3),
                          widget.arg.xpGained > 0
                              ? Text(
                                  '+${widget.arg.xpGained} XP',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.displayFamily,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.xp,
                                  ),
                                )
                              : const Text(
                                  'Syncing your rewards...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Adaptive outcome (backend-derived).
              if (result.adaptive != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _AdaptiveOutcomeCard(adaptive: result.adaptive!),
                ),

              // ---- ANSWER REVIEW --------------------------------------
              if (result.results.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'REVIEW',
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final r in result.results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AnswerReviewTile(review: r),
                  ),
              ],

              const SizedBox(height: 26),
              PrimaryGameButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onTap: () async {
                  ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
                  context.go(Routes.home);
                },
              ),
            ],
          ),
          if (perfect || widget.arg.xpGained > 0)
            const Positioned.fill(child: ConfettiEffect()),
        ],
      ),
    );
  }

  Color scoreColor(double score) => score >= 80
      ? AppColors.success
      : score >= 50
      ? AppColors.warning
      : AppColors.error;
}

/// Renders the backend adaptive insight verbatim - never recomputed.
class _AdaptiveOutcomeCard extends StatelessWidget {
  const _AdaptiveOutcomeCard({required this.adaptive});

  final AdaptiveInsight adaptive;

  @override
  Widget build(BuildContext context) {
    final trendUp = adaptive.trend == 'IMPROVING';
    return GameCardLike(
      tint: trendUp ? AppColors.success : AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.insights_rounded,
                size: 15,
                color: AppColors.secondary,
              ),
              SizedBox(width: 7),
              Text(
                'AI GAME MASTER',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Stat(
                label: 'MASTERY',
                value: '${adaptive.masteryScore.toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 18),
              _Stat(label: 'LEVEL', value: adaptive.masteryLevel),
              const SizedBox(width: 18),
              _Stat(label: 'NEXT DIFFICULTY', value: adaptive.nextDifficulty),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                trendUp ? Icons.north_east_rounded : Icons.drag_handle_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Trend: ${adaptive.trend.toLowerCase()} Â· Next: '
                  '${adaptive.recommendedActivity.toLowerCase().replaceAll('_', ' ')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 9.5,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontFamily: AppTypography.displayFamily,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class GameCardLike extends StatelessWidget {
  const GameCardLike({super.key, required this.tint, required this.child});

  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [tint.withValues(alpha: 0.1), AppColors.surfaceElevated],
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: tint.withValues(alpha: 0.35)),
    ),
    child: child,
  );
}

class _AnswerReviewTile extends StatelessWidget {
  const _AnswerReviewTile({required this.review});

  final AnswerReview review;

  @override
  Widget build(BuildContext context) {
    final ok = review.isCorrect;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok
            ? AppColors.success.withValues(alpha: 0.07)
            : AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (ok ? AppColors.success : AppColors.error).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                size: 15,
                color: ok ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Your answer: ${review.selectedAnswer.isEmpty ? '-' : review.selectedAnswer}',
                  style: const TextStyle(fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!ok && review.correctAnswer.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Correct: ${review.correctAnswer}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.success.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (review.explanation.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              review.explanation,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
