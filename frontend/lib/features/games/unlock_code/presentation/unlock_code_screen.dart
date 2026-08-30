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
import '../data/unlock_challenges.dart';
import '../models/unlock_challenge.dart';

class UnlockCodeScreen extends ConsumerStatefulWidget {
  const UnlockCodeScreen({super.key, required this.topicId, this.topicName, this.subjectId});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  @override
  ConsumerState<UnlockCodeScreen> createState() => _UnlockCodeScreenState();
}

class _UnlockCodeScreenState extends ConsumerState<UnlockCodeScreen> {
  late List<UnlockChallenge> _challenges;
  late VaultCode _vault;
  int _index = 0;
  String? _selected;
  bool _showResult = false;
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
  List<String?> _revealed = [];

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.unlockCode);
    _challenges = UnlockChallenges.session(count: 4);
    _vault = UnlockChallenges.vaultForSession(_challenges);
    _revealed = List.filled(_vault.length, null);
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) => setState(() {});
    _timer.onComplete = _onTimeUp;
    _timer.start();
    _start = DateTime.now();
  }

  void _onTimeUp() => _finishGame(timedOut: true);

  void _onSelect(String choice) {
    if (_showResult) return;
    setState(() => _selected = choice);
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
      _revealed[_index] = ch.codeReward;
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
    _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _next();
    });
  }

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
    final total = _challenges.length;
    final accuracy = total == 0 ? 0.0 : _correctCount / total * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, difficulty: _difficulty, type: GameType.unlockCode, timeLimitSeconds: _timeLimit),
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
    // If all correct, show unlock animation before result (simple delay with vault)
    if (_vault.isUnlocked(_correctCount) && !timedOut && !outOfLives) {
      _showUnlockSequence(result);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameResultScreen(result: result, onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => UnlockCodeScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))))));
    }
  }

  void _showUnlockSequence(GameResult result) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.scrim,
      builder: (_) => _UnlockDialog(vault: _vault, onContinue: () {
        Navigator.of(context).pop();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameResultScreen(result: result, onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => UnlockCodeScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))))));
      }),
    );
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Color _timerColor() {
    final r = _timer.remaining;
    if (r <= 10) return AppColors.error;
    if (r <= 30) return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  void dispose() {
    _timer.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_challenges.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('UNLOCK THE CODE')), body: const EmptyState(icon: Icons.lock_outline_rounded, title: 'No challenges', message: 'No unlock challenges available.'));
    }
    final ch = _challenges[_index];
    final progress = (_index + (_showResult ? 1 : 0)) / _challenges.length;
    final isWide = MediaQuery.sizeOf(context).width > 700;
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
                          const Icon(Icons.lock_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          const Text('UNLOCK THE CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.warning)),
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
                // Vault
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryDeep.withValues(alpha: 0.25), AppColors.surfaceElevated]),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_vault.isUnlocked(_correctCount) ? Icons.lock_open_rounded : Icons.lock_rounded, size: 18, color: _vault.isUnlocked(_correctCount) ? AppColors.success : AppColors.warning),
                          const SizedBox(width: 8),
                          Text(_vault.isUnlocked(_correctCount) ? 'VAULT UNLOCKED' : 'LOCKED VAULT', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: _vault.isUnlocked(_correctCount) ? AppColors.success : AppColors.warning)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: List.generate(_vault.length, (i) {
                          final revealed = _revealed[i];
                          final isRevealed = revealed != null;
                          return Semantics(
                            label: isRevealed ? 'Code fragment ${i + 1}: $revealed' : 'Code fragment ${i + 1} hidden',
                            child: AnimatedContainer(
                              duration: AppMotion.normal,
                              curve: AppMotion.easeOut,
                              width: isWide ? 64 : 56,
                              height: isWide ? 64 : 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isRevealed ? AppColors.success.withValues(alpha: 0.14) : AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isRevealed ? AppColors.success : AppColors.border, width: isRevealed ? 1.6 : 1.0),
                                boxShadow: isRevealed ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.25), blurRadius: 12)] : null,
                              ),
                              child: revealed != null
                                  ? Text(revealed, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.success))
                                  : const Text('?', style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Text('CODE: ${_vault.isUnlocked(_correctCount) ? _vault.display : _revealed.map((e) => e ?? '?').join(' ')}', style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(ch.topic.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))), const SizedBox(width: 8), Text(ch.difficulty.displayName.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppColors.textTertiary))]),
                        const SizedBox(height: 10),
                        if (ch.codeSnippet != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderStrong)),
                            child: SelectableText(ch.codeSnippet!, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
                          ),
                        if (ch.codeSnippet != null) const SizedBox(height: 12),
                        Text(ch.prompt, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 18, fontWeight: FontWeight.w600, height: 1.35)),
                        const SizedBox(height: 8),
                        if (ch.hint != null && !_showResult)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2))),
                            child: Row(children: [const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), Expanded(child: Text(ch.hint!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
                          ),
                        if (ch.hint != null && !_showResult) const SizedBox(height: 12),
                        for (var i = 0; i < ch.choices.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChoiceCard(
                              index: i,
                              label: ch.choices[i],
                              selected: _selected == ch.choices[i],
                              showResult: _showResult,
                              isCorrect: ch.correctAnswer == ch.choices[i],
                              wasSelected: _selected == ch.choices[i],
                              onTap: () => _onSelect(ch.choices[i]),
                            ),
                          ),
                        if (_showResult) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(_wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(_wasCorrect ? 'CORRECT! CODE FRAGMENT REVEALED' : 'ACCESS DENIED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error))]),
                                const SizedBox(height: 6),
                                Text(ch.explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                                if (_wasCorrect) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.key_rounded, size: 14, color: AppColors.success), const SizedBox(width: 6), Text('Fragment ${ch.codeReward} unlocked', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success))]),
                                ] else
                                  const Padding(padding: EdgeInsets.only(top: 6), child: Text('Code fragment remains locked.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _selected == null || _showResult ? null : _onSubmit,
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: Text(_showResult ? (_wasCorrect ? 'NEXT CHALLENGE' : (_lives <= 0 ? 'GAME OVER' : 'CONTINUE')) : 'UNLOCK FRAGMENT', style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.pop(), child: const Text('EXIT VAULT')),
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
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT VAULT'))),
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
        border = AppColors.warning;
        fill = AppColors.warning.withValues(alpha: 0.16);
        glyph = AppColors.warning;
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
            boxShadow: selected && !showResult ? [BoxShadow(color: AppColors.warning.withValues(alpha: 0.35), blurRadius: 18)] : null,
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
          return Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 4), child: Icon(alive ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: alive ? AppColors.error : AppColors.textTertiary));
        }),
      );
}

class _UnlockDialog extends StatefulWidget {
  const _UnlockDialog({required this.vault, required this.onContinue});
  final VaultCode vault;
  final VoidCallback onContinue;
  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_c.value);
                return Transform.scale(scale: 0.8 + 0.2 * t, child: Opacity(opacity: t, child: Column(children: [Icon(Icons.lock_open_rounded, size: 56, color: AppColors.success), const SizedBox(height: 12), const Text('VAULT UNLOCKED!', style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.success))])));
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.success.withValues(alpha: 0.4))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.vault.fragments.map((f) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success)), child: Text(f, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.success)))).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text('CODE: ${widget.vault.display}', style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onContinue, child: const Text('VIEW RESULTS'))),
          ],
        ),
      ),
    );
  }
}
