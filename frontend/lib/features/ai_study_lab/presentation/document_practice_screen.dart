import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/quiz_option.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/study_lab_repository.dart';
import '../domain/study_document.dart';
import '../domain/study_practice.dart';
import 'widgets/document_card.dart';
import 'widgets/document_processing_view.dart';
import 'widgets/source_citation_card.dart';

/// AI-GENERATED DOCUMENT PRACTICE (RAG-FE-4 UI foundation).
///
/// Setup → generating → question → explanation → result → review, all
/// inside one route so back behavior is deliberate. Questions,
/// evaluations, and explanations come ONLY from
/// [StudyLabRepository]; with no service connected the flow stops at
/// honest unavailable/error states — NEVER fabricated content. This is
/// a SEPARATE content origin from official quizzes and GameContent:
/// nothing here submits game results or touches XP/mastery/streaks.
class DocumentPracticeScreen extends ConsumerStatefulWidget {
  const DocumentPracticeScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentPracticeScreen> createState() =>
      _DocumentPracticeScreenState();
}

enum _PracticePhase { setup, generating, unavailable, failure, empty, run, result }

class _DocumentPracticeScreenState
    extends ConsumerState<DocumentPracticeScreen> {
  static const List<int> questionCountOptions = [5, 10, 15];

  late Future<StudyDocument?> _docFuture;
  _PracticePhase _phase = _PracticePhase.setup;
  String? _phaseMessage;

  PracticeSetup _setup = const PracticeSetup();
  GeneratedPracticeSet? _set;
  int _index = 0;
  int? _selected;
  bool _evaluating = false;
  PracticeEvaluation? _evaluation;
  String? _evalNotice;
  final List<PracticeAttempt> _attempts = [];
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    _docFuture = ref.read(studyLabRepoProvider).documentById(widget.documentId);
  }

  void _tap() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
  }

  bool get _busy =>
      _phase == _PracticePhase.generating || _evaluating;

  /// Active practice (generated set in progress) deserves an explicit
  /// leave confirmation; terminal states pop freely.
  bool get _canPop =>
      !_busy &&
      !(_phase == _PracticePhase.run && _attempts.isNotEmpty);

  Future<void> _confirmLeave() async {
    if (_canPop) {
      if (context.canPop()) context.pop();
      return;
    }
    _tap();
    final leave = await showPremiumDialog<bool>(
      context: context,
      builder: (dialogContext) => CinematicDialog(
        accent: AppColors.secondary,
        title: const Text('Leave practice?'),
        content: const Text(
          'Your current practice session will be closed. Nothing was '
          'saved server-side.',
        ),
        actions: [
          PremiumDialogActions(
            primaryLabel: 'Leave',
            onPrimary: () => Navigator.of(dialogContext).pop(true),
            secondaryLabel: 'Stay',
            onSecondary: () => Navigator.of(dialogContext).pop(false),
            accent: AppColors.secondary,
          ),
        ],
      ),
    );
    if (leave == true && mounted && context.canPop()) context.pop();
  }

  Future<void> _generate() async {
    _tap();
    setState(() {
      _phase = _PracticePhase.generating;
      _phaseMessage = null;
    });
    PracticeGenerationResult result;
    try {
      result = await ref.read(studyLabRepoProvider).generateDocumentPractice(
        documentId: widget.documentId,
        setup: _setup,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _PracticePhase.failure;
        _phaseMessage = describeError(e).message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _PracticePhase.failure;
        _phaseMessage = 'Something went wrong. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      switch (result) {
        case PracticeSetReady(:final set):
          if (set.questions.isEmpty) {
            _phase = _PracticePhase.empty;
            _phaseMessage = 'No practice questions were generated.';
          } else {
            _set = set;
            _index = 0;
            _attempts.clear();
            _resetQuestion();
            _phase = _PracticePhase.run;
          }
        case PracticeUnavailable(:final message):
          _phase = _PracticePhase.unavailable;
          _phaseMessage = message;
        case PracticeGenerationFailure(:final message):
          _phase = _PracticePhase.failure;
          _phaseMessage = message;
        case PracticeEmpty(:final message):
          _phase = _PracticePhase.empty;
          _phaseMessage = message;
      }
    });
  }

  void _resetQuestion() {
    _selected = null;
    _evaluating = false;
    _evaluation = null;
    _evalNotice = null;
  }

  /// Explicit submit only: requires a selection, never double-sends,
  /// and never fabricates a verdict — unavailable stays on-question.
  Future<void> _submit() async {
    final set = _set;
    final selected = _selected;
    if (set == null || selected == null || _evaluating) return;
    if (_evaluation != null) return;
    final question = set.questions[_index];
    _tap();
    setState(() {
      _evaluating = true;
      _evalNotice = null;
    });
    PracticeEvaluationResult result;
    try {
      result = await ref.read(studyLabRepoProvider).evaluatePracticeAnswer(
        documentId: widget.documentId,
        questionId: question.id,
        selectedAnswer: question.options[selected],
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _evaluating = false;
        _evalNotice = describeError(e).message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _evaluating = false;
        _evalNotice = 'Something went wrong. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _evaluating = false;
      switch (result) {
        case PracticeEvaluated(:final evaluation):
          _evaluation = evaluation;
          _attempts.add(
            PracticeAttempt(
              questionId: question.id,
              selectedAnswer: question.options[selected],
              isCorrect: evaluation.isCorrect,
              correctAnswer: evaluation.correctAnswer,
            ),
          );
          if (evaluation.isCorrect) {
            ref.read(audioManagerProvider).play(Sfx.correct);
          }
        case PracticeEvaluationUnavailable(:final message):
          _evalNotice = message;
        case PracticeEvaluationFailure(:final message):
          _evalNotice = message;
      }
    });
  }

  void _next() {
    final set = _set;
    if (set == null) return;
    _tap();
    setState(() {
      if (_index + 1 >= set.questions.length) {
        _reviewing = false;
        _phase = _PracticePhase.result;
      } else {
        _index++;
        _resetQuestion();
      }
    });
  }

  void _practiceAgain() {
    _tap();
    setState(() {
      _phase = _PracticePhase.setup;
      _phaseMessage = null;
      _set = null;
      _index = 0;
      _attempts.clear();
      _resetQuestion();
      _reviewing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _canPop) return;
        await _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _confirmLeave),
          title: const Text('AI PRACTICE'),
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: AtmosphericBackground()),
            if (isDark)
              const Positioned(
                top: -60,
                right: -40,
                child: GlowOrb(
                  color: AppColors.secondary,
                  size: 240,
                  opacity: 0.10,
                ),
              ),
            // Full-screen route outside the shell (same convention as
            // Study Lab / workspace / tutor routes): SafeArea only.
            SafeArea(
              top: true,
              bottom: true,
              child: FutureBuilder<StudyDocument?>(
                future: _docFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done &&
                      !snap.hasData) {
                    return const CinematicLoading(
                      message: 'Opening AI practice...',
                    );
                  }
                  if (snap.hasError) {
                    final err = describeError(snap.error!);
                    return ErrorState(
                      title: err.title,
                      message: err.message,
                      onRetry: () => setState(() {
                        _docFuture = ref
                            .read(studyLabRepoProvider)
                            .documentById(widget.documentId);
                      }),
                    );
                  }
                  final doc = snap.data;
                  if (doc == null) {
                    return EmptyState(
                      icon: Icons.fitness_center_rounded,
                      title: 'Document unavailable',
                      message:
                          'Practice needs a document and none is available '
                          'right now.',
                      action: SecondaryGameButton(
                        label: 'Back to Study Lab',
                        icon: Icons.science_rounded,
                        expanded: false,
                        onTap: () => context.go(Routes.aiStudyLab),
                      ),
                    );
                  }
                  return _PracticeBody(
                    document: doc,
                    phase: _phase,
                    phaseMessage: _phaseMessage,
                    setup: _setup,
                    onSetupChanged: (next) =>
                        setState(() => _setup = next),
                    onGenerate: _generate,
                    onBackToWorkspace: () =>
                        context.go(Routes.aiStudyDocument(doc.id)),
                    set: _set,
                    index: _index,
                    selected: _selected,
                    onSelect: (i) => setState(() {
                      if (_evaluation == null && !_evaluating) {
                        _selected = i;
                        ref.read(audioManagerProvider).play(Sfx.buttonTap);
                      }
                    }),
                    evaluating: _evaluating,
                    evaluation: _evaluation,
                    evalNotice: _evalNotice,
                    onSubmit: _submit,
                    onNext: _next,
                    attempts: List.of(_attempts),
                    reviewing: _reviewing,
                    onToggleReview: () =>
                        setState(() => _reviewing = !_reviewing),
                    onPracticeAgain: _practiceAgain,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Practice header: AI-generated identity + document context. Rendered
/// on setup/generating/run/result so the origin is never ambiguous.
class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({required this.document});

  final StudyDocument document;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated.withValues(alpha: 0.7)
            : AppLightColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          DocumentTypeIcon(fileType: document.fileType, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI GENERATED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.secondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Based on: ${document.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  semanticsLabel:
                      'AI generated practice based on document ${document.title}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeBody extends StatelessWidget {
  const _PracticeBody({
    required this.document,
    required this.phase,
    required this.phaseMessage,
    required this.setup,
    required this.onSetupChanged,
    required this.onGenerate,
    required this.onBackToWorkspace,
    required this.set,
    required this.index,
    required this.selected,
    required this.onSelect,
    required this.evaluating,
    required this.evaluation,
    required this.evalNotice,
    required this.onSubmit,
    required this.onNext,
    required this.attempts,
    required this.reviewing,
    required this.onToggleReview,
    required this.onPracticeAgain,
  });

  final StudyDocument document;
  final _PracticePhase phase;
  final String? phaseMessage;
  final PracticeSetup setup;
  final ValueChanged<PracticeSetup> onSetupChanged;
  final VoidCallback onGenerate;
  final VoidCallback onBackToWorkspace;
  final GeneratedPracticeSet? set;
  final int index;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool evaluating;
  final PracticeEvaluation? evaluation;
  final String? evalNotice;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final List<PracticeAttempt> attempts;
  final bool reviewing;
  final VoidCallback onToggleReview;
  final VoidCallback onPracticeAgain;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveCenter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppGutters.pagePadding(context),
            8,
            AppGutters.pagePadding(context),
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PracticeHeader(document: document),
              const SizedBox(height: 14),
              switch (phase) {
                _PracticePhase.setup => _SetupView(
                  setup: setup,
                  onSetupChanged: onSetupChanged,
                  onGenerate: onGenerate,
                ),
                _PracticePhase.generating => const DocumentProcessingView(
                  title: 'Building your practice set…',
                  message:
                      'Nova is turning this document into practice '
                      'questions.',
                ),
                _PracticePhase.unavailable => _TerminalState(
                  icon: Icons.cloud_off_rounded,
                  title: 'AI practice isn’t ready yet',
                  message:
                      phaseMessage ??
                      'Practice generation will appear here once '
                          'document AI is connected.',
                  primaryLabel: 'Try Again',
                  onPrimary: onGenerate,
                  onBack: onBackToWorkspace,
                ),
                _PracticePhase.failure => _TerminalState(
                  icon: Icons.error_outline_rounded,
                  title: "We couldn't generate practice.",
                  message:
                      phaseMessage ??
                      'Something went wrong. Please try again.',
                  primaryLabel: 'Try Again',
                  onPrimary: onGenerate,
                  onBack: onBackToWorkspace,
                ),
                _PracticePhase.empty => _TerminalState(
                  icon: Icons.quiz_rounded,
                  title: 'No practice questions were generated.',
                  message:
                      'Try another topic or ask Nova to explain the '
                      'document first.',
                  primaryLabel: 'Try Again',
                  onPrimary: onGenerate,
                  onBack: onBackToWorkspace,
                ),
                _PracticePhase.run => _QuestionView(
                  set: set!,
                  index: index,
                  selected: selected,
                  onSelect: onSelect,
                  evaluating: evaluating,
                  evaluation: evaluation,
                  evalNotice: evalNotice,
                  onSubmit: onSubmit,
                  onNext: onNext,
                ),
                _PracticePhase.result => _ResultView(
                  set: set!,
                  attempts: attempts,
                  reviewing: reviewing,
                  onToggleReview: onToggleReview,
                  onPracticeAgain: onPracticeAgain,
                  onBack: onBackToWorkspace,
                ),
              },
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Setup: document context, count + difficulty preference chips,
/// Generate CTA. Preferences are frontend-only until mapped later.
class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.setup,
    required this.onSetupChanged,
    required this.onGenerate,
  });

  final PracticeSetup setup;
  final ValueChanged<PracticeSetup> onSetupChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Generate practice from this document',
          style: AppTypography.h2(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Nova builds questions from your material. Generation '
          'needs the document AI service.',
          style: AppTypography.bodySecondary(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _OptionLabel(label: 'Number of questions'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final count in _DocumentPracticeScreenState
                .questionCountOptions)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ChoiceChip(
                    label: '$count',
                    selected: setup.questionCount == count,
                    semanticsLabel:
                        '$count questions${setup.questionCount == count ? ', selected' : ''}',
                    onTap: () => onSetupChanged(
                      PracticeSetup(
                        questionCount: count,
                        difficulty: setup.difficulty,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _OptionLabel(label: 'Difficulty'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final difficulty in PracticeDifficulty.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ChoiceChip(
                    label: difficulty.label,
                    selected: setup.difficulty == difficulty,
                    semanticsLabel:
                        '${difficulty.label} difficulty${setup.difficulty == difficulty ? ', selected' : ''}',
                    onTap: () => onSetupChanged(
                      PracticeSetup(
                        questionCount: setup.questionCount,
                        difficulty: difficulty,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryGameButton(
          label: 'Generate Practice',
          icon: Icons.auto_awesome_rounded,
          onTap: onGenerate,
        ),
        const SizedBox(height: 6),
        Text(
          'AI-generated practice only — never official quiz content.',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark
                ? AppColors.textTertiary
                : AppLightColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      semanticsLabel: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: selected
              ? AppColors.secondary.withValues(alpha: isDark ? 0.16 : 0.10)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.55)
                : (isDark ? AppColors.border : AppLightColors.border),
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? AppColors.secondary
                : (isDark
                      ? AppColors.textSecondary
                      : AppLightColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Terminal setup states (unavailable/failure/empty) with retry + back.
class _TerminalState extends StatelessWidget {
  const _TerminalState({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onBack,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Icon(
          icon,
          size: 52,
          color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
          semanticLabel: title,
        ),
        const SizedBox(height: 12),
        Text(title, style: AppTypography.h3(context), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          message,
          style: AppTypography.bodySecondary(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        PrimaryGameButton(
          label: primaryLabel,
          icon: Icons.refresh_rounded,
          onTap: onPrimary,
        ),
        const SizedBox(height: 10),
        SecondaryGameButton(
          label: 'Back to Workspace',
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
      ],
    );
  }
}

/// Question view: progress header, question card, options, submit,
/// then feedback (correctness + explanation + sources) with Next.
class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.set,
    required this.index,
    required this.selected,
    required this.onSelect,
    required this.evaluating,
    required this.evaluation,
    required this.evalNotice,
    required this.onSubmit,
    required this.onNext,
  });

  final GeneratedPracticeSet set;
  final int index;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool evaluating;
  final PracticeEvaluation? evaluation;
  final String? evalNotice;
  final VoidCallback onSubmit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = set.questions[index];
    final isLast = index + 1 >= set.questions.length;
    final evaluated = evaluation != null;
    QuizOptionState stateFor(int i) {
      if (!evaluated) {
        return selected == i
            ? QuizOptionState.selected
            : QuizOptionState.idle;
      }
      final correct = evaluation!.correctAnswer;
      if (correct != null && question.options[i] == correct) {
        return QuizOptionState.correct;
      }
      if (selected == i) {
        return evaluation!.isCorrect
            ? QuizOptionState.correct
            : QuizOptionState.incorrect;
      }
      return QuizOptionState.idle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Question ${index + 1} of ${set.total}',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${index + 1} of ${set.total}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                  ),
                ),
              ),
              if (question.difficulty != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Text(
                    question.difficulty!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GameCard(
          child: SelectableText(
            question.questionText,
            style: TextStyle(
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimary
                  : AppLightColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: evaluated || evaluating,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < question.options.length; i++) ...[
                QuizOption(
                  label: question.options[i],
                  index: i,
                  state: stateFor(i),
                  onTap: () => onSelect(i),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (evaluated) ...[
          _FeedbackBanner(
            correct: evaluation!.isCorrect,
            evaluating: false,
          ),
          const SizedBox(height: 12),
          _ExplanationBlock(
            evaluation: evaluation!,
            question: question,
          ),
          const SizedBox(height: 14),
          PrimaryGameButton(
            label: isLast ? 'See Result' : 'Next Question',
            icon: isLast
                ? Icons.emoji_events_rounded
                : Icons.arrow_forward_rounded,
            onTap: onNext,
          ),
        ] else ...[
          if (evaluating)
            const _FeedbackBanner(correct: null, evaluating: true)
          else if (evalNotice != null)
            _FeedbackBanner(
              correct: null,
              evaluating: false,
              notice: evalNotice,
            ),
          const SizedBox(height: 6),
          PrimaryGameButton(
            label: 'Submit Answer',
            icon: Icons.check_rounded,
            onTap: selected == null || evaluating ? null : onSubmit,
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Correctness banner. Semantics announce the verdict; icon + text
/// (never color alone).
class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.correct,
    required this.evaluating,
    this.notice,
  });

  final bool? correct;
  final bool evaluating;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (evaluating) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Checking your answer…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    if (notice != null) {
      return EmptyMiniCard(text: notice!);
    }
    final ok = correct == true;
    final color = ok ? AppColors.success : AppColors.error;
    return Semantics(
      label: ok ? 'Correct answer' : 'Incorrect answer',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ok ? 'Correct — nicely done.' : 'Not quite — see why below.',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppLightColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Post-evaluation explanation + sources. Renders only fields the
/// evaluation actually carries — no invented content.
class _ExplanationBlock extends StatelessWidget {
  const _ExplanationBlock({required this.evaluation, required this.question});

  final PracticeEvaluation evaluation;
  final GeneratedPracticeQuestion question;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final explanation = evaluation.explanation ?? question.explanation;
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why this answer?',
            style: AppTypography.h3(context),
          ),
          if (explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              explanation,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: isDark
                    ? AppColors.textSecondary
                    : AppLightColors.textSecondary,
              ),
            ),
          ],
          if (question.sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sources',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.textTertiary
                    : AppLightColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            for (final src in question.sources) ...[
              SourceCitationCard(source: src),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

/// Result: real counts only. No XP/mastery/streak/levels anywhere.
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.set,
    required this.attempts,
    required this.reviewing,
    required this.onToggleReview,
    required this.onPracticeAgain,
    required this.onBack,
  });

  final GeneratedPracticeSet set;
  final List<PracticeAttempt> attempts;
  final bool reviewing;
  final VoidCallback onToggleReview;
  final VoidCallback onPracticeAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = PracticeResult(attempts: attempts, total: set.total);
    final sourcesExplored = {
      for (var i = 0; i < set.questions.length; i++)
        if (set.questions[i].sources.isNotEmpty) set.questions[i].id,
    }.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameCard(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.novaCore(),
                  boxShadow: AppShadows.glow(
                    AppColors.secondary,
                    alpha: isDark ? 0.35 : 0.18,
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Practice Complete',
                style: AppTypography.h2(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ResultStat(
                    label: 'Answered',
                    value: '${result.answered}',
                  ),
                  _ResultStat(
                    label: 'Correct',
                    value: '${result.correct}',
                  ),
                  _ResultStat(
                    label: 'Accuracy',
                    value: '${(result.accuracy * 100).round()}%',
                  ),
                ],
              ),
              if (sourcesExplored > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$sourcesExplored question${sourcesExplored == 1 ? '' : 's'} with document sources',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SecondaryGameButton(
          label: reviewing ? 'Hide Review' : 'Review Answers',
          icon: Icons.rate_review_rounded,
          onTap: onToggleReview,
        ),
        if (reviewing) ...[
          const SizedBox(height: 12),
          for (var i = 0; i < set.questions.length; i++)
            _ReviewCard(
              index: i,
              question: set.questions[i],
              attempt: i < attempts.length ? attempts[i] : null,
            ),
        ],
        const SizedBox(height: 14),
        PrimaryGameButton(
          label: 'Practice Again',
          icon: Icons.refresh_rounded,
          onTap: onPracticeAgain,
        ),
        const SizedBox(height: 10),
        SecondaryGameButton(
          label: 'Back to Workspace',
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '$label $value',
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimary
                  : AppLightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark
                  ? AppColors.textSecondary
                  : AppLightColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-question review: your answer vs correct answer, explanation,
/// sources — only values that actually exist.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.question,
    required this.attempt,
  });

  final int index;
  final GeneratedPracticeQuestion question;
  final PracticeAttempt? attempt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final correct = attempt?.isCorrect == true;
    final color = attempt == null
        ? (isDark ? AppColors.textTertiary : AppLightColors.textTertiary)
        : (correct ? AppColors.success : AppColors.error);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GameCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Q${index + 1}. ${question.questionText}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  attempt == null
                      ? Icons.remove_circle_outline_rounded
                      : (correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded),
                  size: 20,
                  color: color,
                  semanticLabel: attempt == null
                      ? 'Not answered'
                      : (correct ? 'Correct answer' : 'Incorrect answer'),
                ),
              ],
            ),
            if (attempt != null) ...[
              const SizedBox(height: 8),
              _ReviewLine(
                label: 'Your answer',
                value: attempt!.selectedAnswer,
                color: color,
              ),
              if (attempt!.correctAnswer != null) ...[
                const SizedBox(height: 4),
                _ReviewLine(
                  label: 'Correct answer',
                  value: attempt!.correctAnswer!,
                  color: AppColors.success,
                ),
              ],
            ],
            if (question.explanation != null &&
                question.explanation!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  question.explanation!,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                  ),
                ),
              ),
            ],
            if (question.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final src in question.sources) ...[
                SourceCitationCard(source: src),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}
