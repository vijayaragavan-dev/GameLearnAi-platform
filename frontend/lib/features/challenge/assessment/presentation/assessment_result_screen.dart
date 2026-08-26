import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/models/assessment_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/celebrations.dart' show ConfettiEffect;
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/nova_companion.dart';
import '../../../../shared/widgets/recommendation_card.dart' show SectionHeader;
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
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
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
                        const Text(
                          '% accuracy',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    outcome.assessed
                        ? 'The Game Master has calibrated your missions.'
                        : 'Take the scan to unlock calibration.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.topicName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_levelLabel(t.masteryLevel)} · ${t.currentDifficulty}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
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
                  PrimaryGameButton(
                    label: 'View my path',
                    icon: Icons.map_rounded,
                    onTap: () async {
                      ref.read(audioManagerProvider).play(Sfx.missionComplete);
                      context.go(Routes.home);
                    },
                  ),
                ],
              ),
              if (outcome.assessed)
                const Positioned.fill(child: ConfettiEffect(particleCount: 50)),
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
