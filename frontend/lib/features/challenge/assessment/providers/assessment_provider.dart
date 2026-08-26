import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/assessment_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';

/// ASMT flow state: delivery -> local answers -> submit result.
class AssessmentState {
  const AssessmentState({
    this.delivery,
    this.answers = const {},
    this.submitting = false,
    this.result,
    this.conflict = false,
    this.error,
  });

  final AssessmentDelivery? delivery;
  final Map<String, String> answers; // questionId -> selectedAnswer
  final bool submitting;
  final AssessmentSubmissionResult? result;
  final bool conflict; // R-GUARD 409: baseline already exists
  final String? error;

  AssessmentState copyWith({
    AssessmentDelivery? delivery,
    Map<String, String>? answers,
    bool clearAnswers = false,
    bool? submitting,
    AssessmentSubmissionResult? result,
    bool clearResult = false,
    bool? conflict,
    String? error,
    bool clearError = false,
  }) => AssessmentState(
    delivery: delivery ?? this.delivery,
    answers: clearAnswers ? const {} : (answers ?? this.answers),
    submitting: submitting ?? this.submitting,
    result: clearResult ? null : (result ?? this.result),
    conflict: conflict ?? this.conflict,
    error: clearError ? null : (error ?? this.error),
  );
}

final assessmentProvider =
    NotifierProvider.family<AssessmentController, AssessmentState, String>(
      AssessmentController.new,
    );

class AssessmentController extends Notifier<AssessmentState> {
  AssessmentController(this.subjectId);

  final String subjectId;

  @override
  AssessmentState build() => const AssessmentState();

  Future<void> load() async {
    try {
      final delivery = await ref.read(assessmentRepoProvider).fetch(subjectId);
      state = state.copyWith(delivery: delivery, clearError: true);
    } catch (_) {
      state = state.copyWith(error: 'Could not load the scan');
    }
  }

  void select(String questionId, String answer) {
    state = state.copyWith(answers: {...state.answers, questionId: answer});
  }

  /// ASMT-002. Returns true on success; sets [conflict] on R-GUARD 409.
  Future<bool> submit() async {
    final delivery = state.delivery;
    if (delivery == null || state.submitting) return false;
    if (state.answers.length < delivery.questions.length) return false;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final result = await ref.read(assessmentRepoProvider).submit(subjectId, [
        for (final q in delivery.questions)
          (
            questionId: q.questionId,
            selectedAnswer: state.answers[q.questionId]!,
          ),
      ]);
      state = state.copyWith(
        submitting: false,
        result: result,
        conflict: false,
      );
      return true;
    } on ConflictException {
      state = state.copyWith(
        submitting: false,
        conflict: true,
        error: 'Your placement is already established.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        submitting: false,
        error: 'Submission failed. Try again.',
      );
      return false;
    }
  }
}
