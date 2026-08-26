import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/gamification_delta.dart';
import '../../../../core/models/quiz_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../app/router.dart';
import '../../../../shared/widgets/nova_companion.dart';
import '../../../../shared/widgets/quiz_option.dart';
import 'quiz_result_arg.dart';

/// QUIZ-001/002 challenge arena. Correctness is NEVER known to the client
/// before submission - selection only highlights.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late Future<Quiz> _future;
  int _index = 0;
  final Map<String, String> _answers = {};
  GamificationSnapshot? _preSnapshot;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.quiz);
    _future = ref.read(quizRepoProvider).quizForTopic(widget.topicId);
    _capturePreSnapshot();
  }

  Future<void> _capturePreSnapshot() async {
    final snap = await _snapshot();
    if (mounted) setState(() => _preSnapshot = snap);
  }

  Future<GamificationSnapshot?> _snapshot() => captureGamificationSnapshot(
    readSummary: () => ref.read(gamificationRepoProvider).summary(),
    readAchievements: () => ref.read(gamificationRepoProvider).achievements(),
  );

  void _retry() => setState(() {
    _index = 0;
    _answers.clear();
    _future = ref.read(quizRepoProvider).quizForTopic(widget.topicId);
  });

  Future<void> _finish(Quiz quiz) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(quizRepoProvider).submit(quiz.id, [
        for (final q in quiz.questions)
          (questionId: q.id, selectedAnswer: _answers[q.id]!),
      ]);

      // Post-submission gamification read for honest deltas.
      final post = await _snapshot();
      final delta = compareSnapshots(_preSnapshot, post);

      ref
          .read(audioManagerProvider)
          .play(result.score >= 50 ? Sfx.missionComplete : Sfx.notification);
      if (!mounted) return;
      context.pushReplacement(
        '/quiz-result',
        extra: QuizResultArg(
          result: result,
          topicName: quiz.title,
          xpGained: delta.xpGained,
          leveledUpTo: delta.leveledUpTo,
          newAchievements: delta.newAchievements,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final err = describeError(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Quiz>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final err = describeError(snap.error!);
            return ErrorState(
              title: err.title,
              message: err.message,
              onRetry: _retry,
            );
          }
          final quiz = snap.data!;
          if (quiz.questions.isEmpty) {
            return const EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No questions yet',
              message: 'This challenge has no active questions.',
            );
          }

          final question = quiz.questions[_index];
          final selected = _answers[question.id];
          final isLast = _index == quiz.questions.length - 1;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'CHALLENGE ${_index + 1} / ${quiz.questions.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            QuestionProgress(
                              total: quiz.questions.length,
                              current: _index,
                              answeredFlags: [
                                for (final q in quiz.questions)
                                  _answers.containsKey(q.id),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DifficultyBadge(difficulty: question.difficulty),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Ask Nova for a hint',
                        onPressed: () {
                          ref.read(audioManagerProvider).play(Sfx.buttonTap);
                          context.push(Routes.tutor);
                        },
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    quiz.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.secondary,
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.easeOut,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: SingleChildScrollView(
                        key: ValueKey(question.id),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.questionText,
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            for (var i = 0; i < question.options.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: QuizOption(
                                  index: i,
                                  label: question.options[i],
                                  state: selected == null
                                      ? QuizOptionState.idle
                                      : (selected == question.options[i]
                                            ? QuizOptionState.selected
                                            : QuizOptionState.idle),
                                  onTap: () {
                                    ref
                                        .read(audioManagerProvider)
                                        .play(Sfx.buttonTap);
                                    ref.read(hapticsProvider).select();
                                    setState(
                                      () => _answers[question.id] =
                                          question.options[i],
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(audioManagerProvider)
                                    .play(Sfx.buttonTap);
                                context.push(Routes.tutor);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.32,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NovaCompanion(
                                      size: 20,
                                      mood: NovaMood.idle,
                                    ),
                                    SizedBox(width: 7),
                                    Text(
                                      'Stuck? Ask Nova for a hint',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (_index > 0)
                        SecondaryGameButton(
                          label: 'Back',
                          expanded: false,
                          onTap: () => setState(() => _index--),
                        ),
                      if (_index > 0) const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryGameButton(
                          label: selected == null
                              ? 'Select an answer'
                              : (isLast ? 'Submit challenge' : 'Next'),
                          busy: _submitting,
                          onTap: selected == null
                              ? null
                              : () {
                                  if (isLast) {
                                    FocusScope.of(context).unfocus();
                                    _finish(quiz);
                                  } else {
                                    setState(() => _index++);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
