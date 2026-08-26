import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show Sfx;
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/quiz_option.dart';
import '../providers/assessment_provider.dart';

/// ASMT-001 question runner. Stateless per the approved lifecycle.
class AssessmentRunScreen extends ConsumerStatefulWidget {
  const AssessmentRunScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<AssessmentRunScreen> createState() =>
      _AssessmentRunScreenState();
}

class _AssessmentRunScreenState extends ConsumerState<AssessmentRunScreen> {
  int _index = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(assessmentProvider(widget.subjectId).notifier).load();
      if (mounted) setState(() => _loaded = true);
    });
  }

  Future<void> _next() async {
    final state = ref.read(assessmentProvider(widget.subjectId));
    final questions = state.delivery?.questions ?? const [];
    if (_index < questions.length - 1) {
      setState(() => _index++);
      return;
    }
    // Final answer -> submit.
    final ok = await ref
        .read(assessmentProvider(widget.subjectId).notifier)
        .submit();
    if (!mounted) return;
    if (ok || state.conflict) {
      context.pushReplacement(Routes.assessmentResult(widget.subjectId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider(widget.subjectId));
    if (!_loaded && state.delivery == null && state.error == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null && state.delivery == null) {
      return Scaffold(
        body: ErrorState(
          title: 'Scan unavailable',
          message: state.error!,
          onRetry: () async {
            await ref
                .read(assessmentProvider(widget.subjectId).notifier)
                .load();
            if (mounted) setState(() => _index = 0);
          },
        ),
      );
    }
    final delivery = state.delivery;
    if (delivery == null || delivery.questions.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.quiz_outlined,
          title: 'Nothing to scan',
          message: 'This world has no assessable content yet.',
        ),
      );
    }

    final questions = delivery.questions;
    final question = questions[_index];
    final selected = state.answers[question.questionId];
    final isLast = _index == questions.length - 1;

    return PopScope(
      canPop: !state.submitting,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: Text('SCAN ${_index + 1}/${questions.length}'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuestionProgress(
                  total: questions.length,
                  current: _index,
                  answeredFlags: [
                    for (final q in questions)
                      state.answers.containsKey(q.questionId),
                  ],
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.normal,
                    switchInCurve: AppMotion.easeOut,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(
                      key: ValueKey(question.questionId),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DifficultyBadge(difficulty: question.difficulty),
                          const SizedBox(height: 14),
                          Text(
                            question.questionText,
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 19.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 22),
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
                                  ref
                                      .read(
                                        assessmentProvider(
                                          widget.subjectId,
                                        ).notifier,
                                      )
                                      .select(
                                        question.questionId,
                                        question.options[i],
                                      );
                                },
                              ),
                            ),
                          if (state.error != null && !state.submitting)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                state.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                PrimaryGameButton(
                  label: isLast ? 'Finish scan' : 'Next',
                  busy: state.submitting,
                  onTap: selected == null ? null : _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
