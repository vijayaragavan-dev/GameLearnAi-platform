import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/models/assessment_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/celebrations.dart' show ConfettiEffect;
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/nova_companion.dart';
import '../../../../shared/widgets/recommendation_card.dart' show SectionHeader;
import '../../../../shared/widgets/responsive_layout.dart';
import '../providers/assessment_provider.dart';

/// ASMT-003 result reveal. Assessment never awards XP - the celebration is
/// deliberately calm (MEDIUM tier): insight, not jackpot.
class AssessmentResultScreen extends ConsumerStatefulWidget {
  const AssessmentResultScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<AssessmentResultScreen> createState() =>
      _AssessmentResultScreenState();
}

class _AssessmentResultScreenState
    extends ConsumerState<AssessmentResultScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.celebration);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider(widget.subjectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAN RESULTS'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<AssessmentOutcome>(
        future: ref.read(assessmentRepoProvider).result(widget.subjectId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final err = describeError(snap.error!);
            // R-GUARD conflict path still allows viewing via submit result.
            if (!state.hasResult) {
              return ErrorState(
                title: err.title,
                message: err.message,
                onRetry: () => setState(() {}),
              );
            }
          }

          final outcome = snap.data ?? state.resultToOutcome(widget.subjectId);
          final submission = state.result;

          return Stack(
            children: [
              ResponsiveCenter(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppGutters.pagePadding(context),
                    vertical: 8,
                  ).copyWith(bottom: 32),
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: NovaCompanion(
                        size: 76,
                        mood: outcome.assessed
                            ? NovaMood.celebrating
                            : NovaMood.encouraging,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      outcome.assessed ? 'Baseline established' : 'No scan yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppLightColors.textPrimary,
                      ),
                    ),
                    if (submission != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: AppMotion.normal,
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                            child: Text(submission.score.toStringAsFixed(0)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '% accuracy',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppLightColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      outcome.assessed
                          ? 'The Game Master has calibrated your missions for this world.'
                          : 'Take the scan to unlock calibration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppLightColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subject context pill — truthful, uses actual subjectId.
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? AppColors.border
                                : AppLightColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.textTertiary
                                  : AppLightColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'World • ${widget.subjectId.substring(0, 8)}…',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: isDark
                                      ? AppColors.textTertiary
                                      : AppLightColors.textTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (outcome.assessed) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your personalized path is ready. View where you are and continue the next topic.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppLightColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),

                    // WHAT HAPPENED / TOPIC BREAKDOWN
                    if (outcome.topics.isNotEmpty) ...[
                      const SectionHeader(title: 'Topic baselines'),
                      for (final t in outcome.topics)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GameCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.topicName.isEmpty
                                            ? 'Topic ${t.topicId.substring(0, 8)}'
                                            : t.topicName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isDark
                                              ? AppColors.textPrimary
                                              : AppLightColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_levelLabel(t.masteryLevel)} · ${t.currentDifficulty}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppLightColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _ScoreRing(score: t.masteryScore),
                              ],
                            ),
                          ),
                        ),
                    ],

                    if (outcome.topics.isEmpty) ...[
                      const EmptyMiniCard(
                        text: 'Baselines appear here after your first scan.',
                      ),
                    ],
                    const SizedBox(height: 22),
                    Semantics(
                      button: true,
                      label:
                          'View my personalized learning path for this world',
                      child: PrimaryGameButton(
                        label: 'View my path',
                        icon: Icons.map_rounded,
                        onTap: () {
                          ref
                              .read(audioManagerProvider)
                              .play(Sfx.missionComplete);
                          // PRIMARY FIX UI-5: navigate to subject-specific personalized path
                          context.go(Routes.path(widget.subjectId));
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      button: true,
                      label: 'Return to home dashboard',
                      child: SecondaryGameButton(
                        label: 'Back to home',
                        icon: Icons.home_rounded,
                        onTap: () => context.go(Routes.home),
                      ),
                    ),
                    if (!outcome.assessed) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Your learning path is not available yet. Complete the scan to generate it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textTertiary
                              : AppLightColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (outcome.assessed)
                const Positioned.fill(
                  child: IgnorePointer(child: ConfettiEffect(particleCount: 50)),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _levelLabel(String level) => switch (level) {
    'MASTERED' => 'Mastered',
    'PROFICIENT' => 'Proficient',
    'DEVELOPING' => 'Developing',
    'BEGINNER' => 'Beginner',
    _ => level,
  };
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final tint = score >= 80
        ? AppColors.success
        : score >= 50
        ? AppColors.warning
        : AppColors.error;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
            color: tint,
            backgroundColor: AppColors.surfaceHigh,
          ),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

extension on AssessmentState {
  bool get hasResult => result != null;

  /// Builds an outcome view from a fresh ASMT-002 response when ASMT-003
  /// cannot be fetched yet.
  AssessmentOutcome resultToOutcome(String subjectId) => AssessmentOutcome(
    subjectId: subjectId,
    assessed: true,
    overallMastery: result!.overallMastery,
    topics: [
      for (final t in result!.topics)
        AssessmentTopicResult(
          topicId: t.topicId,
          topicName: '',
          masteryScore: t.accuracy,
          masteryLevel: t.masteryLevel,
          currentDifficulty: t.currentDifficulty,
        ),
    ],
  );
}
