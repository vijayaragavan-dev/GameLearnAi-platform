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
import '../data/debug_challenges.dart';
import '../models/debug_challenge.dart';

/// Debug Arena: debugging simulation — identify / diagnose / fix bugs without executing code.
/// No audio in this phase; uses haptics only.
class DebugArenaScreen extends ConsumerStatefulWidget {
  const DebugArenaScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<DebugArenaScreen> createState() => _DebugArenaScreenState();
}

class _DebugArenaScreenState extends ConsumerState<DebugArenaScreen> {
  late List<DebugChallenge> _challenges;
  int _index = 0;
  String? _selected;
  bool _showResult = false;
  bool _wasCorrect = false;
  int _score = 0;
  int _lives = 3;
  late GameCombo _combo;
  late GameTimer _timer;
  GameDifficulty _difficulty = GameDifficulty.medium;
  DateTime? _start;
  int _timeLimit = 120;
  bool _paused = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    // Resolve difficulty from stored topic? For v1, default medium unless topic difficulty available via provider not yet fetched.
    // Keep extension point: if adaptive mastery read available, use it. For now medium.
    _difficulty = GameDifficulty.medium;
    // Allow caller to hint difficulty via topicName? Not needed.
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.debugArena);
    _challenges = DebugChallenges.session(count: 8, difficulty: null); // 8 challenges mix difficulties
    // If challenges empty (should not), fallback
    if (_challenges.isEmpty) _challenges = DebugChallenges.all.take(6).toList();
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) => setState(() {});
    _timer.onComplete = _onTimeUp;
    _timer.start();
    _start = DateTime.now();
    // Future adaptive integration point: read mastery to adjust difficulty
    _tryAdaptiveDifficulty();
  }

  Future<void> _tryAdaptiveDifficulty() async {
    // Extension point: attempt to read topic mastery if available via progress repo etc.
    // For v1, keep medium and document limitation. No backend change.
    try {
      // No-op; placeholder for future integration with AdaptiveLearningService reads (PROG-002)
    } catch (_) {}
  }

  void _onTimeUp() {
    _finishGame(timedOut: true);
  }

  void _onSelect(String choice) {
    if (_showResult) return;
    setState(() => _selected = choice);
  }

  int _correctCount = 0;

  void _next() {
    if (_index < _challenges.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _showResult = false;
      });
    } else {
      _finishGame();
    }
  }

  void _finishGame({bool timedOut = false, bool outOfLives = false}) {
    _timer.stop();
    final elapsed = _start == null ? 0 : DateTime.now().difference(_start!).inSeconds;
    final correctCount = _correctCount;
    final total = _challenges.length;
    final accuracy = total == 0 ? 0.0 : correctCount / total * 100;
    // XP preview local only for this phase — no backend persistence (documented)
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.debugArena, timeLimitSeconds: _timeLimit),
      score: _score,
      accuracy: accuracy,
      correctCount: correctCount,
      totalQuestions: total,
      timeElapsedSeconds: elapsed,
      comboMax: _combo.max,
      xpEarned: xpPreview,
      completedAt: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GameResultScreen(
        result: result,
        onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DebugArenaScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))),
      ),
    ));
  }

  void _onSubmit() {
    if (_selected == null || _showResult) return;
    final ch = _challenges[_index];
    final correct = ch.isCorrect(_selected!);
    setState(() {
      _showResult = true;
      _wasCorrect = correct;
    });
    if (correct) {
      _correctCount++;
      _combo.registerHit();
      final elapsedSec = _start == null ? 3 : DateTime.now().difference(_start!).inSeconds % 10;
      _score += GameScoring.scoreForHit(difficulty: ch.difficulty, combo: _combo.current, responseTimeSeconds: elapsedSec.clamp(2, 10));
      ref.read(hapticsProvider).success();
    } else {
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
    }
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _next();
    });
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    try { _timer.dispose(); } catch (_) {}
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_challenges.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('DEBUG ARENA')), body: const EmptyState(icon: Icons.bug_report_outlined, title: 'No challenges', message: 'No debug challenges available for this topic.'));
    }
    final ch = _challenges[_index];
    final progress = (_index + (_showResult ? 1 : 0)) / _challenges.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // HUD — custom for Debug Arena with lives + level
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.92), border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.primary.withValues(alpha: 0.45))),
                            child: Text('LEVEL ${ch.level.number}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.45))),
                            child: Text(ch.bugCategory.displayName.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.secondary)),
                          ),
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
                      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress), duration: AppMotion.fast, builder: (context, value, _) => LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6, backgroundColor: AppColors.surfaceHigh, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary)))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('CHALLENGE ${_index + 1} / ${_challenges.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
                          const Spacer(),
                          _LivesIndicator(lives: _lives),
                          const SizedBox(width: 8),
                          if (_combo.current >= 2)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(gradient: _combo.isOnFire ? AppGradients.streakFire : AppGradients.xpGold, borderRadius: BorderRadius.circular(AppRadius.pill)),
                              child: Text(_combo.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textOnColor)),
                            ),
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
                        // System error header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.error.withValues(alpha: 0.35))),
                          child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error.withValues(alpha: 0.18), border: Border.all(color: AppColors.error)), child: const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error)), const SizedBox(width: 10), const Expanded(child: Text('SYSTEM ERROR DETECTED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.error)))]),
                        ),
                        const SizedBox(height: 14),
                        // Topic + language badge
                        Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(ch.language.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))), const SizedBox(width: 8), Text(ch.topic, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)), const Spacer(), Text(ch.level.label, style: const TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppColors.textTertiary))]),
                        const SizedBox(height: 12),
                        // Code block
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.borderStrong)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [const Icon(Icons.code_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), Text('${ch.language} • ${ch.title}', style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600)), const Spacer(), if (ch.hint != null) const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.textTertiary)]),
                              const SizedBox(height: 10),
                              SelectableText(ch.buggyCode, style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5, height: 1.6, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (ch.hint != null && !_showResult)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2))),
                            child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), Expanded(child: Text(ch.hint!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
                          ),
                        if (ch.hint != null && !_showResult) const SizedBox(height: 14),
                        // Prompt
                        Text(ch.prompt, style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(ch.levelHelp, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        const SizedBox(height: 12),
                        // Choices
                        for (var i = 0; i < ch.choices.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChoiceCard(
                              index: i,
                              label: ch.choices[i],
                              selected: _selected == ch.choices[i],
                              showResult: _showResult,
                              isCorrect: ch.correctDiagnosis == ch.choices[i],
                              wasSelected: _selected == ch.choices[i],
                              onTap: () => _onSelect(ch.choices[i]),
                            ),
                          ),
                        // Inline feedback
                        if (_showResult) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(_wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(_wasCorrect ? 'BUG FOUND! +${GameScoring.scoreForHit(difficulty: ch.difficulty, combo: _combo.current, responseTimeSeconds: 3)}' : 'WRONG DIAGNOSIS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error))]),
                                const SizedBox(height: 6),
                                Text(ch.explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                                if (ch.fixedCode != null && _wasCorrect) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                                    child: SelectableText(ch.fixedCode!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5, color: AppColors.success)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _selected == null || _showResult ? null : _onSubmit,
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: Text(_showResult ? (_wasCorrect ? 'NEXT CHALLENGE' : (_lives <= 0 ? 'GAME OVER' : 'CONTINUE')) : 'SUBMIT DIAGNOSIS', style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.pop(), child: const Text('EXIT ARENA')),
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
                        const Icon(Icons.pause_circle_rounded, size: 48, color: AppColors.secondary),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => setState(() { _paused = false; _timer.resume(); }), icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME'))),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT ARENA'))),
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

  Color _timerColor() {
    final r = _timer.remaining;
    if (r <= 10) return AppColors.error;
    if (r <= 30) return AppColors.warning;
    return AppColors.textSecondary;
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.index, required this.label, required this.selected, required this.showResult, required this.isCorrect, required this.wasSelected, required this.onTap});
  final int index;
  final String label;
  final bool selected;
  final bool showResult;
  final bool isCorrect;
  final bool wasSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Color border;
    Color fill;
    Color glyph;
    if (showResult) {
      if (isCorrect) {
        border = AppColors.success;
        fill = AppColors.success.withValues(alpha: 0.14);
        glyph = AppColors.success;
      } else if (wasSelected && !isCorrect) {
        border = AppColors.error;
        fill = AppColors.error.withValues(alpha: 0.12);
        glyph = AppColors.error;
      } else {
        border = AppColors.border;
        fill = AppColors.surface;
        glyph = AppColors.textTertiary;
      }
    } else {
      if (selected) {
        border = AppColors.primary;
        fill = AppColors.primary.withValues(alpha: 0.16);
        glyph = AppColors.primaryBright;
      } else {
        border = AppColors.border;
        fill = AppColors.surface;
        glyph = AppColors.textTertiary;
      }
    }
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Option ${String.fromCharCode(65 + index)}: $label',
      child: GestureDetector(
        onTap: showResult ? null : onTap,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: selected || (showResult && isCorrect) ? 1.8 : 1.2),
            boxShadow: selected && !showResult ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 18)] : null,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: glyph.withValues(alpha: 0.14), border: Border.all(color: glyph.withValues(alpha: 0.5))),
                child: showResult && isCorrect
                    ? const Icon(Icons.check_rounded, size: 15, color: AppColors.success)
                    : showResult && wasSelected && !isCorrect
                        ? const Icon(Icons.close_rounded, size: 15, color: AppColors.error)
                        : Text(String.fromCharCode(65 + index), style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 13, fontWeight: FontWeight.w700, color: glyph)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontFamily: AppTypography.bodyFamily, fontSize: 14.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, height: 1.35, color: AppColors.textPrimary))),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivesIndicator extends StatelessWidget {
  const _LivesIndicator({required this.lives});
  final int lives;
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(3, (i) {
          final alive = i < lives;
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: Icon(alive ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: alive ? AppColors.error : AppColors.textTertiary),
          );
        }),
      );
}
