import 'dart:async';
import 'dart:math';
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
import '../data/snake_and_ladder_data.dart';
import '../models/snake_and_ladder.dart';

class SnakeAndLadderScreen extends ConsumerStatefulWidget {
  const SnakeAndLadderScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.diceProvider});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final DiceRollProvider? diceProvider;
  @override
  ConsumerState<SnakeAndLadderScreen> createState() => _SnakeAndLadderScreenState();
}

class _SnakeAndLadderScreenState extends ConsumerState<SnakeAndLadderScreen> {
  late SnakeAndLadderBoard _board;
  late SnakeAndLadderState _state;
  late GameCombo _combo;
  late GameTimer _timer;
  GameDifficulty _difficulty = GameDifficulty.medium;
  int _timeLimit = 240;
  DateTime? _start;
  bool _paused = false;
  int _score = 0;
  int _correct = 0;
  int _failed = 0;
  int _resets = 0;
  Timer? _feedbackTimer;
  bool _showChallenge = false;
  SnakeChallenge? _currentChallenge;
  bool _showResult = false;
  bool _wasCorrect = false;
  bool _showSnake = false;
  bool _showLadder = false;
  bool _showFell = false;
  String? _feedback;
  // Challenge-specific selections
  List<String> _arrangeSelected = [];
  Map<String, String> _matchSelected = {};
  String? _matchLeftPicked;
  String? _selectedOption;
  bool _hintVisible = false;

  @override
  void initState() {
    super.initState();
    _board = SnakeAndLadderBoard.create(size: 100);
    _state = SnakeAndLadderState(board: _board, diceProvider: widget.diceProvider ?? RandomDiceProvider());
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.snakeAndLadder);
    // Fallback if not defined (should be added)
    if (_timeLimit == 0) _timeLimit = 240;
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) { if (mounted) setState(() {}); };
    _timer.onComplete = _onTimeUp;
    _timer.start();
    _start = DateTime.now();
  }

  void _onTimeUp() => _finishGame(timedOut: true);

  void _onRoll() {
    if (_state.isGameOver || _state.isFinished || _state.challengeActive || _state.isRolling || _showChallenge) return;
    try {
      final roll = _state.rollDice();
      setState(() {});
      // Animate movement with small delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final newPos = _state.move(roll);
        setState(() {
          _feedback = null;
          _showSnake = false;
          _showLadder = false;
        });
        // Check what landed on
        if (_board.isFinish(newPos)) {
          _finishGame();
        } else if (_board.isSnakeHead(newPos)) {
          setState(() {
            _showSnake = true;
            _feedback = '🐍 SNAKE! Slid from $newPos to ${_board.snakes[newPos]}';
          });
          // already moved to tail in state.move
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _showSnake = false);
          });
        } else if (_board.isLadderFoot(newPos)) {
          setState(() {
            _showLadder = true;
            _feedback = '🪜 LADDER! Climbed from $newPos to ${_board.ladders[newPos]}';
          });
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _showLadder = false);
          });
        } else if (_board.isChallengeCell(newPos)) {
          final cid = _board.challengeCells[newPos]!;
          final ch = SnakeAndLadderChallenges.byId(cid);
          setState(() {
            _currentChallenge = ch;
            _showChallenge = true;
            _showResult = false;
            _wasCorrect = false;
            _hintVisible = false;
            _arrangeSelected = [];
            _matchSelected = {};
            _matchLeftPicked = null;
            _selectedOption = null;
          });
        }
      });
    } catch (_) {
      setState(() => _feedback = 'Cannot roll now');
    }
  }

  void _onChallengeCheck() {
    if (_currentChallenge == null || _showResult) return;
    final ch = _currentChallenge!;
    bool correct = false;
    switch (ch.challengeType) {
      case ChallengeType.arrange:
      case ChallengeType.sequence:
      case ChallengeType.logic:
        if (_arrangeSelected.length != (ch.blocks ?? ch.sequenceBlocks)!.length) {
          setState(() => _feedback = 'Arrange all blocks!');
          return;
        }
        correct = ch.isCorrectDynamic(_arrangeSelected);
        break;
      case ChallengeType.match:
        if (_matchSelected.length != ch.matchPairs!.length) {
          setState(() => _feedback = 'Match all pairs!');
          return;
        }
        correct = ch.isCorrectDynamic(_matchSelected);
        break;
      case ChallengeType.debug:
        if (_selectedOption == null) {
          setState(() => _feedback = 'Select a fix!');
          return;
        }
        correct = ch.isCorrectDynamic(_selectedOption!);
        break;
      case ChallengeType.quickConcept:
      case ChallengeType.scenario:
        if (_selectedOption == null) {
          setState(() => _feedback = 'Choose an answer!');
          return;
        }
        correct = ch.isCorrectDynamic(_selectedOption!);
        break;
    }

    setState(() {
      _showResult = true;
      _wasCorrect = correct;
      _feedback = null;
    });

    if (correct) {
      _correct++;
      _combo.registerHit();
      _score += GameScoring.scoreForHit(difficulty: ch.difficulty, combo: _combo.current, responseTimeSeconds: 3);
      ref.read(hapticsProvider).success();
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _showChallenge = false;
          _showResult = false;
          _wasCorrect = false;
          _currentChallenge = null;
          _state.challengeActive = false;
          // complete challenge in state
          _state.completeChallenge(true);
        });
      });
    } else {
      _failed++;
      _combo.registerMiss();
      ref.read(hapticsProvider).error();
      // Primary consequence: RESET TO START
      setState(() {
        _showFell = true;
        _feedback = '🐍 YOU FELL! Back to START';
      });
      _state.completeChallenge(false);
      _resets++;
      // Update state lives
      // _state.lives is inside SnakeAndLadderState, but we also track for HUD? Use _state.lives
      // For scoring, we already decremented via completeChallenge
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        if (_state.isGameOver) {
          _finishGame(outOfLives: true);
          return;
        }
        setState(() {
          _showFell = false;
          _showChallenge = false;
          _showResult = false;
          _wasCorrect = false;
          _currentChallenge = null;
        });
      });
    }
  }

  void _finishGame({bool timedOut = false, bool outOfLives = false}) {
    _timer.stop();
    final elapsed = _start == null ? 0 : DateTime.now().difference(_start!).inSeconds;
    final total = _board.size;
    // Accuracy based on challenges? Use correct vs total attempted
    final attempted = _correct + _failed;
    final acc = attempted == 0 ? 0.0 : _correct / attempted * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: acc, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, difficulty: _difficulty, type: GameType.snakeAndLadder, timeLimitSeconds: _timeLimit),
      score: _score,
      accuracy: acc,
      correctCount: _correct,
      totalQuestions: attempted,
      timeElapsedSeconds: elapsed,
      comboMax: _combo.max,
      xpEarned: xpPreview,
      completedAt: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameResultScreen(
              result: result,
              onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SnakeAndLadderScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))),
            )));
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
    final progress = _board.size == 0 ? 0.0 : _state.currentPosition / _board.size;
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
                          const Icon(Icons.casino_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          const Text('SNAKE & LADDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFFF59E0B))),
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
                      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress), duration: AppMotion.fast, builder: (context, v, _) => LinearProgressIndicator(value: v.clamp(0, 1), minHeight: 6, backgroundColor: AppColors.surfaceHigh, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B))))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('POS ${_state.currentPosition} / ${_board.size}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
                          const Spacer(),
                          _LivesIndicator(lives: _state.lives),
                          const SizedBox(width: 8),
                          Text('RESETS $_resets', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                          const SizedBox(width: 8),
                          if (_combo.current >= 2)
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(gradient: _combo.isOnFire ? AppGradients.streakFire : AppGradients.xpGold, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Text(_combo.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textOnColor))),
                        ],
                      ),
                      if (_state.lastRoll != null) ...[
                        const SizedBox(height: 6),
                        Center(child: Text('Last roll: ${_state.lastRoll}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showFell) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.error.withValues(alpha: 0.4))),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('🐍', style: TextStyle(fontSize: 18)), SizedBox(width: 8), Text('YOU FELL! Back to START', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.error, letterSpacing: 1))]),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_feedback != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: (_showSnake || _showLadder) ? AppColors.warning.withValues(alpha: 0.1) : AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: (_showSnake || _showLadder) ? AppColors.warning.withValues(alpha: 0.3) : AppColors.border)),
                            child: Text(_feedback!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: (_showSnake || _showLadder) ? AppColors.warning : AppColors.textSecondary), textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Board
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 6),
                                  const Text('SNAKE & LADDER BOARD', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
                                  const Spacer(),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text('${_board.size} CELLS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Board grid 10x10
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1),
                                itemCount: _board.cells.length,
                                itemBuilder: (context, idx) {
                                  final cell = _board.cells[idx];
                                  final isPlayer = _state.currentPosition == cell.number;
                                  final isStart = cell.number == 0;
                                  Color bg = AppColors.surfaceHigh;
                                  Color border = AppColors.border;
                                  String label = isStart ? 'START' : '${cell.number}';
                                  String icon = '';
                                  if (cell.type == CellType.snake) {
                                    bg = AppColors.error.withValues(alpha: 0.12);
                                    border = AppColors.error.withValues(alpha: 0.4);
                                    icon = '🐍';
                                  } else if (cell.type == CellType.ladder) {
                                    bg = AppColors.success.withValues(alpha: 0.12);
                                    border = AppColors.success.withValues(alpha: 0.4);
                                    icon = '🪜';
                                  } else if (cell.type == CellType.challenge) {
                                    bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
                                    border = const Color(0xFFF59E0B).withValues(alpha: 0.4);
                                    icon = '🧠';
                                  } else if (cell.type == CellType.bonus) {
                                    bg = AppColors.warning.withValues(alpha: 0.08);
                                    border = AppColors.warning.withValues(alpha: 0.3);
                                    icon = '⭐';
                                  } else if (cell.type == CellType.finish) {
                                    bg = AppColors.success.withValues(alpha: 0.18);
                                    border = AppColors.success;
                                    icon = '🏁';
                                  } else if (cell.type == CellType.checkpoint) {
                                    bg = AppColors.secondary.withValues(alpha: 0.08);
                                    border = AppColors.secondary.withValues(alpha: 0.3);
                                    icon = '📍';
                                  }
                                  if (isPlayer) {
                                    bg = const Color(0xFFF59E0B).withValues(alpha: 0.22);
                                    border = const Color(0xFFF59E0B);
                                  }
                                  return Semantics(
                                    label: isStart ? 'START' : 'Cell ${cell.number} ${cell.type.name}${isPlayer ? " player" : ""}',
                                    child: Container(
                                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: border, width: isPlayer ? 1.6 : 1.0)),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(icon, style: const TextStyle(fontSize: 10)),
                                                const SizedBox(height: 2),
                                                Text(label, style: TextStyle(fontSize: isStart ? 7 : 9, fontWeight: FontWeight.w700, color: isPlayer ? const Color(0xFFF59E0B) : AppColors.textPrimary), textAlign: TextAlign.center),
                                                if (cell.snakeTo != null) Text('→${cell.snakeTo}', style: const TextStyle(fontSize: 7, color: AppColors.error)),
                                                if (cell.ladderTo != null) Text('→${cell.ladderTo}', style: const TextStyle(fontSize: 7, color: AppColors.success)),
                                              ],
                                            ),
                                          ),
                                          if (isPlayer)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                                child: const Center(child: Text('🧍', style: TextStyle(fontSize: 14))),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _LegendChip(icon: '🧠', label: 'Challenge'),
                                  SizedBox(width: 8),
                                  _LegendChip(icon: '🐍', label: 'Snake'),
                                  SizedBox(width: 8),
                                  _LegendChip(icon: '🪜', label: 'Ladder'),
                                  SizedBox(width: 8),
                                  _LegendChip(icon: '🏁', label: 'Finish'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Roll button
                        FilledButton.icon(
                          onPressed: (_state.challengeActive || _showChallenge || _state.isGameOver || _state.isFinished || _state.isRolling) ? null : _onRoll,
                          icon: const Icon(Icons.casino_rounded, size: 18),
                          label: const Text('ROLL', style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w800)),
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: const Color(0xFFF59E0B), disabledBackgroundColor: AppColors.surfaceHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                        const SizedBox(height: 6),
                        Center(child: Text(_state.challengeActive || _showChallenge ? 'Complete challenge to continue' : 'Roll to move', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary))),
                        const SizedBox(height: 12),
                        // Challenge panel
                        if (_showChallenge && _currentChallenge != null) _buildChallengePanel(_currentChallenge!),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.pop(), child: const Text('EXIT GAME')),
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
                        const Icon(Icons.pause_circle_rounded, size: 48, color: Color(0xFFF59E0B)),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => setState(() { _paused = false; _timer.resume(); }), icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME'))),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT GAME'))),
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

  Widget _buildChallengePanel(SnakeChallenge ch) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)])), child: const Icon(Icons.quiz_rounded, size: 18, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(child: Text(ch.title, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 15, fontWeight: FontWeight.w700))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(ch.challengeType.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 8),
          Text(ch.instruction, style: const TextStyle(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(ch.learningObjective, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          if (ch.codeSnippet != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderStrong)),
              child: SelectableText(ch.codeSnippet!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5, color: AppColors.textPrimary)),
            ),
          ],
          const SizedBox(height: 12),
          _buildChallengeBoard(ch),
          const SizedBox(height: 10),
          if (_hintVisible) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(ch.hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
            ),
            const SizedBox(height: 8),
          ] else
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _hintVisible = true), icon: const Icon(Icons.lightbulb_outline_rounded, size: 14), label: const Text('SHOW HINT'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero))),
          if (_showResult) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(_wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(_wasCorrect ? 'CORRECT! +${GameScoring.scoreForHit(difficulty: ch.difficulty, combo: _combo.current, responseTimeSeconds: 3)}' : 'INCORRECT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error))]),
                  const SizedBox(height: 6),
                  Text(ch.explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                  if (!_wasCorrect) ...[
                    const SizedBox(height: 6),
                    const Text('🐍 You will return to START and try again!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ] else
                    const Padding(padding: EdgeInsets.only(top: 6), child: Text('Keep climbing!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _showResult ? null : _onChallengeCheck,
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: const Color(0xFFF59E0B), disabledBackgroundColor: AppColors.surfaceHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_showResult ? (_wasCorrect ? 'CLIMBING...' : 'FALLING...') : 'CHECK', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w700, color: _showResult ? AppColors.textTertiary : Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeBoard(SnakeChallenge ch) {
    switch (ch.challengeType) {
      case ChallengeType.arrange:
      case ChallengeType.sequence:
      case ChallengeType.logic:
        final blocks = ch.blocks ?? ch.sequenceBlocks!;
        final correct = ch.correctOrder ?? ch.sequenceCorrect!;
        final available = blocks.where((b) => !_arrangeSelected.contains(b.id)).toList();
        final selected = _arrangeSelected.map((id) => blocks.firstWhere((b) => b.id == id)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('BUILD ORDER (${_arrangeSelected.length}/${blocks.length})', style: const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 90),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
              child: _arrangeSelected.isEmpty
                  ? Center(child: Text('Tap blocks below →', style: TextStyle(fontSize: 12, color: AppColors.textTertiary.withValues(alpha: 0.9))))
                  : Column(
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: selected.length,
                          onReorder: (o, n) {
                            if (_showResult) return;
                            if (n > o) n--;
                            setState(() {
                              final item = _arrangeSelected.removeAt(o);
                              _arrangeSelected.insert(n, item);
                            });
                          },
                          itemBuilder: (context, idx) {
                            final b = selected[idx];
                            final isCorrect = _showResult ? correct[idx] == b.id : null;
                            Color border = const Color(0xFFF59E0B);
                            Color fill = const Color(0xFFF59E0B).withValues(alpha: 0.08);
                            if (_showResult) {
                              if (isCorrect == true) {
                                border = AppColors.success;
                                fill = AppColors.success.withValues(alpha: 0.12);
                              } else if (isCorrect == false) {
                                border = AppColors.error;
                                fill = AppColors.error.withValues(alpha: 0.1);
                              }
                            }
                            return Container(
                              key: ValueKey('sel_${b.id}'),
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
                              child: Row(
                                children: [
                                  Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: border)), child: Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: border))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(b.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                  if (!_showResult)
                                    GestureDetector(onTap: () => setState(() => _arrangeSelected.removeAt(idx)), child: const Icon(Icons.close_rounded, size: 14, color: AppColors.error)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available.map((b) => _AvailableBlock(block: b, onTap: () => setState(() => _arrangeSelected = [..._arrangeSelected, b.id]), enabled: !_showResult)).toList(),
            ),
          ],
        );
      case ChallengeType.match:
        // For snake game, match is same as before but we simplify to tap left then right
        final pairs = ch.matchPairs!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TAP LEFT THEN RIGHT TO MATCH', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: pairs.map((pair) {
                      final isPicked = _matchLeftPicked == pair.leftId;
                      final matched = _matchSelected[pair.leftId];
                      final isMatched = matched != null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: _showResult ? null : () => setState(() => _matchLeftPicked = pair.leftId),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(color: isPicked ? const Color(0xFFF59E0B).withValues(alpha: 0.14) : isMatched ? AppColors.success.withValues(alpha: 0.12) : AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: isPicked ? const Color(0xFFF59E0B) : isMatched ? AppColors.success : AppColors.border)),
                            child: Row(children: [Expanded(child: Text(pair.leftLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), if (isMatched) const Icon(Icons.check_rounded, size: 12, color: AppColors.success)]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: pairs.map((pair) {
                      // Shuffle right display? Keep order but randomize via sorting by id
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: _showResult
                              ? null
                              : () {
                                  if (_matchLeftPicked == null) {
                                    setState(() => _feedback = 'Pick left first');
                                    return;
                                  }
                                  setState(() {
                                    _matchSelected[_matchLeftPicked!] = pair.rightId;
                                    _matchLeftPicked = null;
                                  });
                                },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(color: _matchSelected.containsValue(pair.rightId) ? AppColors.success.withValues(alpha: 0.12) : AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _matchSelected.containsValue(pair.rightId) ? AppColors.success : AppColors.border)),
                            child: Text(pair.rightLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            if (_matchSelected.isNotEmpty && !_showResult)
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(() { _matchSelected = {}; _matchLeftPicked = null; }), child: const Text('CLEAR'))),
          ],
        );
      case ChallengeType.debug:
      case ChallengeType.quickConcept:
      case ChallengeType.scenario:
        final opts = ch.debugOptions ?? ch.options ?? ch.scenarioOptions!;
        final correctId = ch.correctDebugId ?? ch.correctOptionId ?? ch.correctScenarioId!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < opts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionCard(index: i, option: opts[i], selected: _selectedOption == opts[i].id, showResult: _showResult, isCorrect: correctId == opts[i].id, wasSelected: _selectedOption == opts[i].id, enabled: !_showResult, onTap: () => setState(() => _selectedOption = opts[i].id)),
              ),
          ],
        );
    }
  }

}

class _AvailableBlock extends StatelessWidget {
  const _AvailableBlock({required this.block, required this.onTap, required this.enabled});
  final ChallengeBlock block;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: enabled ? AppColors.surface : AppColors.surfaceHigh.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: enabled ? const Color(0xFFF59E0B).withValues(alpha: 0.45) : AppColors.border)),
            child: Text(block.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: enabled ? AppColors.textPrimary : AppColors.textTertiary)),
          ),
        ),
      );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.index, required this.option, required this.selected, required this.showResult, required this.isCorrect, required this.wasSelected, required this.enabled, required this.onTap});
  final int index;
  final ChallengeOption option;
  final bool selected;
  final bool showResult;
  final bool isCorrect;
  final bool wasSelected;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Color border = AppColors.border;
    Color fill = AppColors.surface;
    Color glyph = AppColors.textTertiary;
    if (showResult) {
      if (isCorrect) {
        border = AppColors.success;
        fill = AppColors.success.withValues(alpha: 0.14);
        glyph = AppColors.success;
      } else if (wasSelected && !isCorrect) {
        border = AppColors.error;
        fill = AppColors.error.withValues(alpha: 0.12);
        glyph = AppColors.error;
      }
    } else if (selected) {
      border = const Color(0xFFF59E0B);
      fill = const Color(0xFFF59E0B).withValues(alpha: 0.16);
      glyph = const Color(0xFFF59E0B);
    }
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8), border: Border.all(color: border, width: selected || (showResult && isCorrect) ? 1.6 : 1.0)),
        child: Row(
          children: [
            Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: glyph.withValues(alpha: 0.14), border: Border.all(color: glyph)), child: Text(String.fromCharCode(65 + index), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: glyph))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(option.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)), if (option.description.isNotEmpty) Text(option.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))])),
          ],
        ),
      ),
    );
  }
}

class _LivesIndicator extends StatelessWidget {
  const _LivesIndicator({required this.lives});
  final int lives;
  @override
  Widget build(BuildContext context) => Row(children: List.generate(3, (i) => Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 4), child: Icon(i < lives ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: i < lives ? AppColors.error : AppColors.textTertiary))));
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.icon, required this.label});
  final String icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(icon, style: const TextStyle(fontSize: 10)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary))]),
      );
}
