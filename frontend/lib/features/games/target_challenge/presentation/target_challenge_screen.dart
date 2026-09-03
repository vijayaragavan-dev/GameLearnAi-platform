import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../game_engine/engine/game_combo.dart';
import '../../../game_engine/engine/game_scoring.dart';
import '../../../game_engine/engine/game_timer.dart';
import '../../../game_engine/models/game_models.dart';
import '../../../game_engine/utils/difficulty_utils.dart';
import '../../../game_engine/widgets/game_result_screen.dart';
import '../data/target_challenges.dart';
import '../models/target_challenge.dart';

class TargetChallengeScreen extends ConsumerStatefulWidget {
  const TargetChallengeScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<TargetChallengeScreen> createState() => _TargetChallengeScreenState();
}

class _TargetChallengeScreenState extends ConsumerState<TargetChallengeScreen> {
  late List<TargetChallenge> _challenges;
  int _index = 0;
  List<String> _history = [];
  int _currentValue = 0;
  List<int> _currentState = [];
  bool _showFeedback = false;
  bool _wasCorrect = false;
  int _score = 0;
  int _lives = 3;
  int _correctCount = 0;
  late GameCombo _combo;
  late GameTimer _timer;
  GameDifficulty _difficulty = GameDifficulty.medium;
  int _timeLimit = 150;
  DateTime? _start;
  bool _paused = false;
  Timer? _feedbackTimer;
  String? _lastActionError;

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.targetChallenge);
    _challenges = TargetChallenges.session(count: 4);
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) => setState(() {});
    _timer.onComplete = () => _finishGame(timedOut: true);
    _timer.start();
    _start = DateTime.now();
    _resetCurrent();
  }

  TargetChallenge get _current => _challenges[_index];

  void _resetCurrent() {
    final ch = _current;
    _history = [];
    if (ch.isValueMode) {
      _currentValue = ch.initialValue;
    } else {
      _currentState = List<int>.from(ch.initialState!);
    }
    _lastActionError = null;
  }

  void _recomputeFromHistory() {
    final ch = _current;
    if (ch.isValueMode) {
      int? v = ch.initialValue;
      for (final aid in _history) {
        v = _simulateStep(v!, aid);
        if (v == null) break;
      }
      if (v != null) _currentValue = v;
    } else {
      var state = List<int>.from(ch.initialState!);
      for (final aid in _history) {
        final act = ch.availableActions.firstWhere((a) => a.id == aid);
        if (act.type == 'toggle' && act.toggleIndex != null) {
          state[act.toggleIndex!] = state[act.toggleIndex!] == 0 ? 1 : 0;
        }
      }
      _currentState = state;
    }
  }

  int? _simulateStep(int current, String aid) {
    final ch = _current;
    final act = ch.availableActions.firstWhere((a) => a.id == aid, orElse: () => const TargetAction(id: '', label: '', type: ''));
    if (act.id.isEmpty) return null;
    switch (act.type) {
      case 'add':
        return current + (act.value ?? 0);
      case 'subtract':
        return current - (act.value ?? 0);
      case 'multiply':
        return current * (act.value ?? 1);
      case 'divide':
        if (act.value == null || act.value == 0) return null;
        if (current % act.value! != 0) return null;
        return current ~/ act.value!;
      default:
        return null;
    }
  }

  void _onAction(TargetAction act) {
    if (_showFeedback) return;
    final ch = _current;
    // Validate division
    if (ch.isValueMode && act.type == 'divide') {
      if (_currentValue % (act.value ?? 1) != 0) {
        setState(() => _lastActionError = 'Cannot divide ${_currentValue} by ${act.value} evenly');
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(milliseconds: 1200), () => setState(() => _lastActionError = null));
        return;
      }
    }
    if (_history.length >= ch.maxActions) {
      setState(() => _lastActionError = 'Max actions reached — reset or undo');
      return;
    }
    setState(() {
      _history = [..._history, act.id];
      _lastActionError = null;
      // Apply
      if (ch.isValueMode) {
        final next = _simulateStep(_currentValue, act.id);
        if (next != null) _currentValue = next;
      } else {
        // state mode
        _currentState[act.toggleIndex!] = _currentState[act.toggleIndex!] == 0 ? 1 : 0;
      }
    });
    // Check target hit automatically
    final reached = ch.isReached(_history);
    if (reached) {
      _onTargetHit();
    } else if (_history.length >= ch.maxActions) {
      // Auto-fail when max reached without hit
      _onTargetMiss();
    }
  }

  void _onTargetHit() {
    if (_showFeedback) return;
    setState(() {
      _showFeedback = true;
      _wasCorrect = true;
    });
    _correctCount++;
    _combo.registerHit();
    final elapsedSec = _start == null ? 3 : DateTime.now().difference(_start!).inSeconds % 10;
    _score += GameScoring.scoreForHit(difficulty: _current.difficulty, combo: _combo.current, responseTimeSeconds: elapsedSec.clamp(2, 10));
    ref.read(hapticsProvider).success();
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _next();
    });
  }

  void _onTargetMiss() {
    if (_showFeedback) return;
    setState(() {
      _showFeedback = true;
      _wasCorrect = false;
    });
    _combo.registerMiss();
    _lives--;
    ref.read(hapticsProvider).error();
    if (_lives <= 0) {
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) _finishGame(outOfLives: true);
      });
      return;
    }
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      // Allow retry? For this game, we advance even on miss (like other games), but could allow retry via reset.
      // Spec: allow continue if recoverable, but we treat miss as challenge failed and move to next.
      _next();
    });
  }

  void _onUndo() {
    if (_showFeedback) return;
    if (_history.isEmpty) return;
    setState(() {
      _history = _history.sublist(0, _history.length - 1);
      _recomputeFromHistory();
      _lastActionError = null;
    });
  }

  void _onReset() {
    if (_showResultCheck()) return;
    setState(() {
      _resetCurrent();
      _lastActionError = null;
    });
  }

  bool _showResultCheck() => _showFeedback;

  void _next() {
    if (_index < _challenges.length - 1) {
      setState(() {
        _index++;
        _showFeedback = false;
        _resetCurrent();
      });
    } else {
      _finishGame();
    }
  }

  void _finishGame({bool timedOut = false, bool outOfLives = false}) {
    _timer.stop();
    final elapsed = _start == null ? 0 : DateTime.now().difference(_start!).inSeconds;
    final total = _challenges.length;
    final accuracy = total == 0 ? 0.0 : _correctCount / total * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.targetChallenge, timeLimitSeconds: _timeLimit),
      score: _score,
      accuracy: accuracy,
      correctCount: _correctCount,
      totalQuestions: total,
      timeElapsedSeconds: elapsed,
      comboMax: _combo.max,
      xpEarned: xpPreview,
      completedAt: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameResultScreen(result: result, onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TargetChallengeScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))))));
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Color _timerColor() {
    final r = _timer.remaining;
    if (r <= 10) return AppColors.error;
    if (r <= 30) return AppColors.warning;
    return AppColors.textSecondary;
  }

  double get _progressValue {
    final ch = _current;
    if (ch.isValueMode) {
      final initial = ch.initialValue.toDouble();
      final target = ch.targetValue.toDouble();
      final cur = _currentValue.toDouble();
      final totalDist = (target - initial).abs();
      if (totalDist == 0) return 1.0;
      final curDist = (target - cur).abs();
      // Progress = 1 - curDist/totalDist, clamped 0..1, but if overshoot, show 0
      final p = 1 - (curDist / totalDist);
      return p.clamp(0.0, 1.0);
    } else {
      // state mode: correct bits / total
      final target = ch.targetState!;
      int correct = 0;
      for (var i = 0; i < target.length; i++) {
        if (_currentState[i] == target[i]) correct++;
      }
      return correct / target.length;
    }
  }

  @override
  void dispose() {
    try { _timer.dispose(); } catch (_) {}
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_challenges.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('TARGET CHALLENGE')), body: const EmptyState(icon: Icons.adjust_rounded, title: 'No challenges', message: 'No target challenges available.'));
    }
    final ch = _current;
    final progress = (_index + (_showFeedback && _wasCorrect ? 1 : 0)) / _challenges.length;
    final isValue = ch.isValueMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // HUD
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.92), border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.adjust_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          const Text('TARGET CHALLENGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.warning)),
                          const Spacer(),
                          Row(children: [const Icon(Icons.star_rounded, size: 18, color: AppColors.xp), const SizedBox(width: 4), Text('$_score', style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.xp))]),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: _timerColor().withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: _timerColor().withValues(alpha: 0.4))),
                            child: Row(children: [Icon(Icons.timer_outlined, size: 14, color: _timerColor()), const SizedBox(width: 5), Text(_fmt(_timer.remaining), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _timerColor()))]),
                          ),
                          IconButton(tooltip: 'Pause', onPressed: () => setState(() { _paused = true; _timer.pause(); }), icon: const Icon(Icons.pause_rounded, size: 18), constraints: const BoxConstraints.tightFor(width: 36, height: 36), padding: EdgeInsets.zero),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress), duration: AppMotion.fast, builder: (context, value, _) => LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6, backgroundColor: AppColors.surfaceHigh, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning)))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('CHALLENGE ${_index + 1} / ${_challenges.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
                          const Spacer(),
                          _LivesIndicator(lives: _lives),
                          const SizedBox(width: 8),
                          if (_combo.current >= 2)
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(gradient: _combo.isOnFire ? AppGradients.streakFire : AppGradients.xpGold, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Text(_combo.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textOnColor))),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Target / Current
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.warning.withValues(alpha: 0.14), AppColors.surfaceElevated]), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.warning.withValues(alpha: 0.30))),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _ValueBox(label: 'TARGET', value: isValue ? '${ch.targetValue}' : ch.targetState!.join(' '), color: AppColors.warning, semantics: 'Target ${isValue ? ch.targetValue : ch.targetState!.join(' ')}'),
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textTertiary)),
                                  Expanded(
                                    child: _ValueBox(
                                      label: 'CURRENT',
                                      value: isValue ? '$_currentValue' : _currentState.join(' '),
                                      color: ch.isReached(_history) ? AppColors.success : AppColors.primary,
                                      semantics: 'Current ${isValue ? _currentValue : _currentState.join(' ')}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Target progress
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TARGET PROGRESS', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: _progressValue),
                                      duration: AppMotion.fast,
                                      builder: (context, value, _) => LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, backgroundColor: AppColors.surfaceHigh, valueColor: AlwaysStoppedAnimation<Color>(value >= 1 ? AppColors.success : AppColors.warning)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // History chips
                              if (_history.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _history.asMap().entries.map((e) {
                                    final act = ch.availableActions.firstWhere((a) => a.id == e.value);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)),
                                      child: Text('${e.key + 1}. ${act.label}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                ),
                              if (_lastActionError != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                                  child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.error), const SizedBox(width: 6), Expanded(child: Text(_lastActionError!, style: const TextStyle(fontSize: 12, color: AppColors.error)))]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Instruction + concept
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ch.title, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(ch.learningObjective, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(ch.instruction, style: const TextStyle(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600)),
                              if (ch.conceptSnippet != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderStrong)),
                                  child: SelectableText(ch.conceptSnippet!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5, color: AppColors.textPrimary)),
                                ),
                              ],
                              if (ch.hint != null && !_showFeedback) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2))),
                                  child: Row(children: [const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), Expanded(child: Text(ch.hint!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // State visual for state mode: show bits
                        if (!isValue) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CURRENT STATE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_currentState.length, (i) {
                                    final cur = _currentState[i];
                                    final tgt = ch.targetState![i];
                                    final correctBit = cur == tgt;
                                    return Container(
                                      margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _showFeedback
                                            ? (correctBit ? AppColors.success.withValues(alpha: 0.14) : AppColors.error.withValues(alpha: 0.12))
                                            : (cur == 1 ? AppColors.primary.withValues(alpha: 0.14) : AppColors.surfaceHigh),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _showFeedback ? (correctBit ? AppColors.success : AppColors.error) : (cur == 1 ? AppColors.primary : AppColors.border), width: 1.4),
                                      ),
                                      child: Text('$cur', style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 20, fontWeight: FontWeight.w700, color: _showFeedback ? (correctBit ? AppColors.success : AppColors.error) : (cur == 1 ? AppColors.primary : AppColors.textSecondary))),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(ch.targetState!.length, (i) {
                                    return Container(
                                      margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                                      width: 48,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning.withValues(alpha: 0.4))),
                                      child: Text('${ch.targetState![i]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning)),
                                    );
                                  }),
                                ),
                                const Center(child: Padding(padding: EdgeInsets.only(top: 4), child: Text('TARGET', style: TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppColors.warning)))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        // Available actions
                        Text('AVAILABLE ACTIONS', style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: ch.availableActions.map((act) {
                            final disabled = _showFeedback || _history.length >= ch.maxActions;
                            return _ActionButton(action: act, enabled: !disabled, onTap: () => _onAction(act));
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _history.isEmpty || _showFeedback ? null : _onUndo,
                                icon: const Icon(Icons.undo_rounded, size: 16),
                                label: const Text('UNDO'),
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _history.isEmpty || _showFeedback ? null : _onReset,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('RESET'),
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                              ),
                            ),
                          ],
                        ),
                        if (_showFeedback) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(_wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(_wasCorrect ? 'TARGET HIT! +${GameScoring.scoreForHit(difficulty: ch.difficulty, combo: _combo.current, responseTimeSeconds: 3)}' : 'TARGET MISSED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error))]),
                                const SizedBox(height: 6),
                                Text(ch.explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                                if (_wasCorrect && ch.correctSequence != null) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: ch.correctSequence!.map((aid) {
                                      final act = ch.availableActions.firstWhere((a) => a.id == aid, orElse: () => ch.availableActions.first);
                                      return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Text(act.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)));
                                    }).toList(),
                                  ),
                                ],
                                if (!_wasCorrect) ...[
                                  const SizedBox(height: 6),
                                  const Text('Try a different route — you can reset or undo.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _showFeedback ? null : null, // no explicit check button; auto-detect
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: Text(_showFeedback ? (_wasCorrect ? 'NEXT TARGET' : (_lives <= 0 ? 'GAME OVER' : 'CONTINUE')) : 'REACH TARGET — USE ACTIONS ABOVE', style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                        ),
                        // For testability, also provide explicit check button that is visible and tappable when not showFeedback
                        if (!_showFeedback)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Actions: ${_history.length}/${ch.maxActions} • Tap actions to move toward target', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                          ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.pop(), child: const Text('EXIT CHALLENGE')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_paused)
            Positioned.fill(
              child: Container(
                color: AppColors.scrim,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_circle_rounded, size: 48, color: AppColors.warning),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => setState(() { _paused = false; _timer.resume(); }), icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME'))),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT CHALLENGE'))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.label, required this.value, required this.color, required this.semantics});
  final String label;
  final String value;
  final Color color;
  final String semantics;
  @override
  Widget build(BuildContext context) => Semantics(
        label: semantics,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: color.withValues(alpha: 0.4))),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.enabled, required this.onTap});
  final TargetAction action;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: action.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: enabled ? AppColors.surface : AppColors.surfaceHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: enabled ? AppColors.warning.withValues(alpha: 0.55) : AppColors.border, width: 1.4),
                boxShadow: enabled ? [BoxShadow(color: AppColors.warning.withValues(alpha: 0.20), blurRadius: 10)] : null,
              ),
              child: Text(action.label, style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w700, color: enabled ? AppColors.warning : AppColors.textTertiary)),
            ),
          ),
        ),
      );
}

class _LivesIndicator extends StatelessWidget {
  const _LivesIndicator({required this.lives});
  final int lives;
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(3, (i) {
          final alive = i < lives;
          return Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 4), child: Icon(alive ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: alive ? AppColors.error : AppColors.textTertiary));
        }),
      );
}
