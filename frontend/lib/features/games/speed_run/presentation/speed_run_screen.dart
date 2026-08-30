import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/gamification_delta.dart';
import '../../../../core/models/quiz_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/quiz_option.dart';
import '../../../game_engine/audio/game_sound_controller.dart';
import '../../../game_engine/engine/game_combo.dart';
import '../../../game_engine/engine/game_scoring.dart';
import '../../../game_engine/engine/game_timer.dart';
import '../../../game_engine/models/game_models.dart';
import '../../../game_engine/utils/difficulty_utils.dart';
import '../../../game_engine/widgets/game_scaffold.dart';
import '../../../game_engine/widgets/game_result_screen.dart';

/// Speed Run: rapid-fire quiz with tight global countdown, streak & speed bonuses.
class SpeedRunScreen extends ConsumerStatefulWidget {
  const SpeedRunScreen({super.key, required this.topicId, this.topicName});
  final String topicId;
  final String? topicName;
  @override
  ConsumerState<SpeedRunScreen> createState() => _SpeedRunScreenState();
}

class _SpeedRunScreenState extends ConsumerState<SpeedRunScreen> {
  late Future<Quiz> _future;
  Quiz? _quiz;
  int _index = 0;
  final Map<String, String> _answers = {};
  final Map<String, int> _times = {};
  GamificationSnapshot? _preSnap;
  bool _submitting = false;
  late GameCombo _combo;
  late GameTimer _timer;
  int _score = 0;
  GameDifficulty _difficulty = GameDifficulty.medium;
  int _timeLimit = 45;
  DateTime? _questionStart;
  bool _soundEnabled = true;
  String? _flash; // 'correct' / 'incorrect' for micro-feedback (local preview)
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _soundEnabled = ref.read(audioManagerProvider).sfxEnabled;
    ref.read(audioManagerProvider).playContext(MusicContext.quiz);
    _future = _load();
    _capture();
  }

  Future<Quiz> _load() async {
    final q = await ref.read(quizRepoProvider).quizForTopic(widget.topicId);
    _quiz = q;
    _difficulty = DifficultyUtils.resolve(topicDifficulty: q.difficulty);
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.speedRun);
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) => setState(() {});
    _timer.onComplete = _onTimeout;
    _timer.start();
    _questionStart = DateTime.now();
    return q;
  }

  Future<void> _capture() async {
    final s = await captureGamificationSnapshot(readSummary: () => ref.read(gamificationRepoProvider).summary(), readAchievements: () => ref.read(gamificationRepoProvider).achievements());
    if (mounted) setState(() => _preSnap = s);
  }

  void _onTimeout() {
    // Time ran out - auto-submit with whatever answers we have
    _submit();
  }

  void _onSelect(String option) async {
    if (_quiz == null || _submitting) return;
    final q = _quiz!.questions[_index];
    if (_answers.containsKey(q.id)) return;
    final elapsed = _questionStart == null ? 0 : DateTime.now().difference(_questionStart!).inSeconds;
    setState(() {
      _answers[q.id] = option;
      _times[q.id] = elapsed;
    });
    // Local scoring preview (optimistic): treat as pending but give speed feedback
    _combo.registerHit(); // temporary, will be reconciled on server submission results; for now we give immediate positive to keep adrenaline
    _score += GameScoring.scoreForHit(difficulty: _difficulty, combo: _combo.current, responseTimeSeconds: elapsed);
    ref.read(gameSoundControllerProvider).buttonTap();
    setState(() => _flash = 'hit');
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 350), () => setState(() => _flash = null));
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    if (_index < _quiz!.questions.length - 1) {
      setState(() => _index++);
      _questionStart = DateTime.now();
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_submitting || _quiz == null) return;
    _submitting = true;
    _timer.stop();
    setState(() {});
    try {
      final payload = <({String questionId, String selectedAnswer})>[];
      for (final q in _quiz!.questions) {
        payload.add((questionId: q.id, selectedAnswer: _answers[q.id] ?? ''));
      }
      final result = await ref.read(quizRepoProvider).submit(_quiz!.id, payload);
      // Reconcile local score/combo with server correctness
      int trueScore = 0;
      final trueCombo = GameCombo();
      int maxCombo = 0;
      for (final r in result.results) {
        final rt = _times[r.questionId] ?? 5;
        if (r.isCorrect) {
          trueCombo.registerHit();
          trueScore += GameScoring.scoreForHit(difficulty: _difficulty, combo: trueCombo.current, responseTimeSeconds: rt);
        } else {
          trueCombo.registerMiss();
        }
        if (trueCombo.max > maxCombo) maxCombo = trueCombo.max;
      }
      final accuracy = result.totalQuestions == 0 ? 0.0 : result.correctCount / result.totalQuestions * 100;
      final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: maxCombo);
      final post = await captureGamificationSnapshot(readSummary: () => ref.read(gamificationRepoProvider).summary(), readAchievements: () => ref.read(gamificationRepoProvider).achievements());
      final delta = compareSnapshots(_preSnap, post);
      ref.read(audioManagerProvider).play(result.score >= 50 ? Sfx.missionComplete : Sfx.notification);
      if (!mounted) return;
      final elapsed = _timeLimit - _timer.remaining;
      final gameResult = GameResult(
        config: GameConfig(topicId: widget.topicId, topicName: widget.topicName ?? _quiz!.title, difficulty: _difficulty, type: GameType.speedRun, timeLimitSeconds: _timeLimit),
        score: trueScore,
        accuracy: accuracy,
        correctCount: result.correctCount,
        totalQuestions: result.totalQuestions,
        timeElapsedSeconds: elapsed,
        comboMax: maxCombo,
        xpEarned: delta.xpGained > 0 ? delta.xpGained : xpPreview,
        completedAt: DateTime.now(),
      );
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameResultScreen(result: gameResult, gamificationDelta: delta, onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SpeedRunScreen(topicId: widget.topicId, topicName: widget.topicName))))));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _timer.resume();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e).message)));
    }
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    if (_quiz != null) _timer.dispose();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Quiz>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return Scaffold(appBar: AppBar(title: const Text('SPEED RUN')), body: const Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          final err = describeError(snap.error!);
          return Scaffold(appBar: AppBar(title: const Text('SPEED RUN')), body: ErrorState(title: err.title, message: err.message, onRetry: () => setState(() => _future = _load())));
        }
        final quiz = snap.data!;
        if (quiz.questions.isEmpty) {
          return Scaffold(appBar: AppBar(title: const Text('SPEED RUN')), body: const EmptyState(icon: Icons.flash_on_rounded, title: 'No questions', message: 'This topic has no active questions.'));
        }
        final q = quiz.questions[_index];
        final selected = _answers[q.id];
        final progress = quiz.questions.length == 0 ? 0.0 : (_index + (selected != null ? 1 : 0)) / quiz.questions.length;
        final urgent = _timer.remaining <= 10;
        return GameScaffold(
          config: GameConfig(topicId: widget.topicId, topicName: widget.topicName ?? quiz.title, difficulty: _difficulty, type: GameType.speedRun),
          score: _score,
          progress: progress,
          progressLabel: 'RUSH ${_index + 1} / ${quiz.questions.length}',
          timeLabel: _fmt(_timer.remaining),
          combo: _combo,
          soundEnabled: _soundEnabled,
          onSoundToggle: () async {
            final audio = ref.read(audioManagerProvider);
            await audio.setSfxEnabled(!audio.sfxEnabled);
            setState(() => _soundEnabled = audio.sfxEnabled);
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Urgency banner
                    if (urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withValues(alpha: 0.4))),
                        child: Row(children: [const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error), const SizedBox(width: 8), const Expanded(child: Text('HURRY UP! Time is running out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)))]),
                      ),
                    if (urgent) const SizedBox(height: 10),
                    ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: _timer.progress, minHeight: 8, backgroundColor: AppColors.surfaceHigh, valueColor: AlwaysStoppedAnimation<Color>(urgent ? AppColors.error : _timer.remaining <= 20 ? AppColors.warning : AppColors.secondary))),
                    const SizedBox(height: 12),
                    Text(q.questionText, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 20, fontWeight: FontWeight.w600, height: 1.3)),
                    const SizedBox(height: 18),
                    for (var i = 0; i < q.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: QuizOption(
                          index: i,
                          label: q.options[i],
                          state: selected == null ? QuizOptionState.idle : (selected == q.options[i] ? QuizOptionState.selected : QuizOptionState.idle),
                          onTap: selected != null || _submitting ? () {} : () => _onSelect(q.options[i]),
                        ),
                      ),
                    const Spacer(),
                    if (selected != null && !_submitting)
                      Text('Answered • ${_timer.remaining}s left • Next in a moment…', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary), textAlign: TextAlign.center),
                    if (_submitting) const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              if (_flash != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 80),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.xp.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.xp.withValues(alpha: 0.5), blurRadius: 16)]),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.bolt_rounded, size: 16, color: AppColors.textOnColor), const SizedBox(width: 6), Text('+${GameScoring.scoreForHit(difficulty: _difficulty, combo: _combo.current, responseTimeSeconds: _times[q.id] ?? 2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textOnColor))]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
