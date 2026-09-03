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
import '../data/puzzle_puzzles.dart';
import '../models/puzzle_arena.dart';

class PuzzleArenaScreen extends ConsumerStatefulWidget {
  const PuzzleArenaScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<PuzzleArenaScreen> createState() => _PuzzleArenaScreenState();
}

class _PuzzleArenaScreenState extends ConsumerState<PuzzleArenaScreen> {
  late List<PuzzleArenaPuzzle> _puzzles;
  int _index = 0;
  int _score = 0;
  int _lives = 3;
  int _correctCount = 0;
  late GameCombo _combo;
  late GameTimer _timer;
  GameDifficulty _difficulty = GameDifficulty.medium;
  int _timeLimit = 150;
  DateTime? _start;
  bool _paused = false;
  bool _hintVisible = false;
  bool _showResult = false;
  bool _wasCorrect = false;
  String? _selectedDebug;
  String? _selectedPattern;
  List<String> _arrangeSelected = [];
  Map<String, String> _matchSelected = {};
  String? _matchLeftPicked;
  Set<ConnectLink> _connectSelected = {};
  String? _connectFirst;
  String? _feedback;
  Timer? _feedbackTimer;

  PuzzleArenaPuzzle get _current => _puzzles[_index];

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.puzzleArena);
    _puzzles = PuzzleArenaPuzzles.session(count: 4);
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) { if (mounted) setState(() {}); };
    _timer.onComplete = _onTimeUp;
    _timer.start();
    _start = DateTime.now();
  }

  void _onTimeUp() => _finishGame(timedOut: true);

  void _resetPuzzleState() {
    _arrangeSelected = [];
    _matchSelected = {};
    _matchLeftPicked = null;
    _connectSelected = {};
    _connectFirst = null;
    _selectedDebug = null;
    _selectedPattern = null;
    _hintVisible = false;
    _feedback = null;
  }

  void _onCheck() {
    if (_showResult) return;
    final p = _current;
    bool correct = false;
    switch (p.puzzleType) {
      case PuzzleType.arrange:
        if (_arrangeSelected.length != p.blocks!.length) {
          setState(() => _feedback = 'Arrange all blocks to check!');
          return;
        }
        correct = p.isArrangeCorrect(_arrangeSelected);
        break;
      case PuzzleType.sequence:
        final blocks = p.sequenceBlocks ?? p.blocks!;
        final correctOrder = p.sequenceCorrect ?? p.correctOrder!;
        if (_arrangeSelected.length != blocks.length) {
          setState(() => _feedback = 'Sequence incomplete!');
          return;
        }
        correct = p.isSequenceCorrect(_arrangeSelected);
        // silence unused
        correctOrder;
        break;
      case PuzzleType.logic:
        final blocks = p.logicBlocks ?? p.blocks!;
        if (_arrangeSelected.length != blocks.length) {
          setState(() => _feedback = 'Build the full logical order!');
          return;
        }
        correct = p.isLogicCorrect(_arrangeSelected);
        break;
      case PuzzleType.match:
        if (_matchSelected.length != p.matchPairs!.length) {
          setState(() => _feedback = 'Match all pairs first!');
          return;
        }
        correct = p.isMatchCorrect(_matchSelected);
        break;
      case PuzzleType.connect:
        if (_connectSelected.length != p.correctLinks!.length) {
          setState(() => _feedback = 'Connect all required links!');
          return;
        }
        correct = p.isConnectCorrect(_connectSelected);
        break;
      case PuzzleType.debug:
        if (_selectedDebug == null) {
          setState(() => _feedback = 'Select a fix!');
          return;
        }
        correct = p.isDebugCorrect(_selectedDebug!);
        break;
      case PuzzleType.pattern:
        if (_selectedPattern == null) {
          setState(() => _feedback = 'Choose the next element!');
          return;
        }
        correct = p.isPatternCorrect(_selectedPattern!);
        break;
    }

    setState(() {
      _showResult = true;
      _wasCorrect = correct;
      _feedback = null;
    });

    if (correct) {
      _correctCount++;
      _combo.registerHit();
      final elapsed = _start == null ? 3 : DateTime.now().difference(_start!).inSeconds % 10;
      _score += GameScoring.scoreForHit(difficulty: p.difficulty, combo: _combo.current, responseTimeSeconds: elapsed.clamp(2, 10));
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
    _feedbackTimer = Timer(Duration(milliseconds: correct ? 1600 : 1800), () {
      if (!mounted) return;
      if (correct) {
        if (_index < _puzzles.length - 1) {
          setState(() {
            _index++;
            _showResult = false;
            _wasCorrect = false;
            _resetPuzzleState();
          });
        } else {
          _finishGame();
        }
      } else {
        // allow retry on same puzzle if lives remain
        setState(() {
          _showResult = false;
          _wasCorrect = false;
          // keep lives deducted, resetWas but keep selections for user to fix? clear for retry
          if (p.puzzleType == PuzzleType.arrange || p.puzzleType == PuzzleType.sequence || p.puzzleType == PuzzleType.logic) {
            _arrangeSelected = [];
          } else if (p.puzzleType == PuzzleType.match) {
            _matchSelected = {};
            _matchLeftPicked = null;
          } else if (p.puzzleType == PuzzleType.connect) {
            _connectSelected = {};
            _connectFirst = null;
          } else if (p.puzzleType == PuzzleType.debug) {
            _selectedDebug = null;
          } else if (p.puzzleType == PuzzleType.pattern) {
            _selectedPattern = null;
          }
        });
      }
    });
  }

  void _finishGame({bool timedOut = false, bool outOfLives = false}) {
    _timer.stop();
    final elapsed = _start == null ? 0 : DateTime.now().difference(_start!).inSeconds;
    final total = _puzzles.length;
    final accuracy = total == 0 ? 0.0 : _correctCount / total * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.puzzleArena, timeLimitSeconds: _timeLimit),
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
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameResultScreen(
              result: result,
              onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PuzzleArenaScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))),
            )));
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  Color _timerColor() {
    final r = _timer.remaining;
    if (r <= 10) return AppColors.error;
    if (r <= 30) return AppColors.warning;
    return AppColors.textSecondary;
  }

  // Arrange helpers
  void _onTapAvailableBlock(PuzzleBlock block) {
    if (_showResult) return;
    if (_arrangeSelected.contains(block.id)) return;
    setState(() => _arrangeSelected = [..._arrangeSelected, block.id]);
  }

  void _onRemoveArrange(int idx) {
    if (_showResult) return;
    setState(() {
      final copy = [..._arrangeSelected];
      copy.removeAt(idx);
      _arrangeSelected = copy;
    });
  }

  void _onReorderArrange(int oldIdx, int newIdx) {
    if (_showResult) return;
    if (newIdx > oldIdx) newIdx--;
    setState(() {
      final item = _arrangeSelected.removeAt(oldIdx);
      _arrangeSelected.insert(newIdx, item);
    });
  }

  // Match helpers
  void _onMatchLeft(String leftId) {
    if (_showResult) return;
    setState(() => _matchLeftPicked = leftId);
  }

  void _onMatchRight(String rightId) {
    if (_showResult) return;
    if (_matchLeftPicked == null) {
      setState(() => _feedback = 'Pick a left item first!');
      return;
    }
    setState(() {
      _matchSelected[_matchLeftPicked!] = rightId;
      _matchLeftPicked = null;
      _feedback = null;
    });
  }

  void _clearMatchForLeft(String leftId) {
    if (_showResult) return;
    setState(() => _matchSelected.remove(leftId));
  }

  // Connect helpers
  void _onConnectTap(String nodeId) {
    if (_showResult) return;
    if (_connectFirst == null) {
      setState(() => _connectFirst = nodeId);
    } else {
      if (_connectFirst == nodeId) {
        setState(() => _connectFirst = null);
        return;
      }
      final link = ConnectLink(from: _connectFirst!, to: nodeId);
      final reverse = ConnectLink(from: nodeId, to: _connectFirst!);
      setState(() {
        if (_connectSelected.contains(link) || _connectSelected.contains(reverse)) {
          _connectSelected.remove(link);
          _connectSelected.remove(reverse);
        } else {
          // For directional puzzles we keep as defined; just add link in picked order
          _connectSelected = {..._connectSelected, link};
        }
        _connectFirst = null;
        _feedback = null;
      });
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
    if (_puzzles.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('PUZZLE ARENA')), body: const EmptyState(icon: Icons.extension_off_rounded, title: 'No puzzles', message: 'No puzzles available.'));
    }
    final p = _current;
    final progress = (_index + (_showResult && _wasCorrect ? 1 : 0)) / _puzzles.length;
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
                          const Icon(Icons.extension_rounded, size: 14, color: Color(0xFF06B6D4)),
                          const SizedBox(width: 6),
                          const Text('PUZZLE ARENA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF06B6D4))),
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
                      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress), duration: AppMotion.fast, builder: (context, v, _) => LinearProgressIndicator(value: v.clamp(0, 1), minHeight: 6, backgroundColor: AppColors.surfaceHigh, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4))))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('PUZZLE ${_index + 1} / ${_puzzles.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
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
                        // Title + mission
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF06B6D4).withValues(alpha: 0.14), AppColors.surfaceElevated]), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.30))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF0E7490), Color(0xFF06B6D4)])), child: const Icon(Icons.lightbulb_rounded, size: 18, color: Colors.white)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(p.title, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 15, fontWeight: FontWeight.w700))),
                                const SizedBox(width: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(p.puzzleType.displayName.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary))),
                              ]),
                              const SizedBox(height: 8),
                              Text(p.instruction, style: const TextStyle(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(p.learningObjective, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Puzzle Board
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.view_module_rounded, size: 14, color: Color(0xFF06B6D4)),
                                  const SizedBox(width: 6),
                                  const Text('PUZZLE BOARD', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: Color(0xFF06B6D4))),
                                  const Spacer(),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(p.topic.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildBoardForPuzzle(p),
                              if (_hintVisible) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(p.hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _hintVisible = true), icon: const Icon(Icons.lightbulb_outline_rounded, size: 14), label: const Text('SHOW HINT'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap))),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_feedback != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                            child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(_feedback!, style: const TextStyle(fontSize: 12, color: AppColors.warning)))]),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_showResult) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(_wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(_wasCorrect ? 'PUZZLE SOLVED!' : 'NOT QUITE!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error))]),
                                const SizedBox(height: 6),
                                Text(p.explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(children: [Icon(Icons.school_outlined, size: 12, color: AppColors.success), SizedBox(width: 6), Text('CONCEPT', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.success))]),
                                      const SizedBox(height: 4),
                                      Text(p.concept, style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (_wasCorrect) ...[
                                  const SizedBox(height: 6),
                                  Text('+${GameScoring.scoreForHit(difficulty: p.difficulty, combo: _combo.current, responseTimeSeconds: 3)} · ${_combo.label.isEmpty ? "x1" : _combo.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                                ] else ...[
                                  const SizedBox(height: 6),
                                  Text(_lives > 0 ? 'Lives remaining: $_lives — try again!' : 'No lives left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _lives > 0 ? AppColors.textSecondary : AppColors.error)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(onPressed: () => setState(() => _hintVisible = true), icon: const Icon(Icons.lightbulb_outline_rounded, size: 16), label: const Text('HINT'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: _showResult ? null : _onCheck,
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: const Color(0xFF06B6D4), disabledBackgroundColor: AppColors.surfaceHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: Text(_showResult ? (_wasCorrect ? 'NEXT PUZZLE' : (_lives <= 0 ? 'GAME OVER' : 'RETRYING...')) : 'CHECK', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w700, color: _showResult ? AppColors.textTertiary : Colors.white)),
                              ),
                            ),
                          ],
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
                        const Icon(Icons.pause_circle_rounded, size: 48, color: Color(0xFF06B6D4)),
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

  Widget _buildBoardForPuzzle(PuzzleArenaPuzzle p) {
    switch (p.puzzleType) {
      case PuzzleType.arrange:
        return _buildArrangeBoard(p.blocks!, p.correctOrder!);
      case PuzzleType.sequence:
        final blocks = p.sequenceBlocks ?? p.blocks!;
        final correct = p.sequenceCorrect ?? p.correctOrder!;
        return _buildArrangeBoard(blocks, correct, title: 'SEQUENCE');
      case PuzzleType.logic:
        final blocks = p.logicBlocks ?? p.blocks!;
        final correct = p.logicCorrect ?? p.correctOrder!;
        return _buildArrangeBoard(blocks, correct, title: 'LOGIC ORDER');
      case PuzzleType.match:
        return _buildMatchBoard(p);
      case PuzzleType.connect:
        return _buildConnectBoard(p);
      case PuzzleType.debug:
        return _buildDebugBoard(p);
      case PuzzleType.pattern:
        return _buildPatternBoard(p);
    }
  }

  Widget _buildArrangeBoard(List<PuzzleBlock> blocks, List<String> correctOrder, {String title = 'ARRANGE'}) {
    final available = blocks.where((b) => !_arrangeSelected.contains(b.id)).toList();
    final selected = _arrangeSelected.map((id) => blocks.firstWhere((b) => b.id == id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$title (${_arrangeSelected.length}/${blocks.length})', style: const TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _showResult ? (_wasCorrect ? AppColors.success : AppColors.error) : AppColors.border, width: _showResult ? 1.6 : 1.0)),
          child: _arrangeSelected.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('Tap blocks below to build →', style: TextStyle(fontSize: 13, color: AppColors.textTertiary.withValues(alpha: 0.9)))))
              : Column(
                  children: [
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: selected.length,
                      onReorder: _onReorderArrange,
                      itemBuilder: (context, idx) {
                        final block = selected[idx];
                        final correctPos = _showResult ? correctOrder[idx] == block.id : null;
                        return Padding(
                          key: ValueKey('sel_${block.id}'),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ArrangePuzzleCard(block: block, index: idx, showResult: _showResult, isCorrectPos: correctPos, onRemove: () => _onRemoveArrange(idx)),
                        );
                      },
                    ),
                    if (!_showResult) Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() => _arrangeSelected = []), icon: const Icon(Icons.clear_rounded, size: 14), label: const Text('CLEAR'))),
                  ],
                ),
        ),
        if (_showResult && !_wasCorrect) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.35))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CORRECT ORDER', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.success)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: correctOrder.map((id) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Text(blocks.firstWhere((b) => b.id == id).label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)))).toList()),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Text('AVAILABLE BLOCKS', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: available.map((b) => _AvailablePuzzleBlock(block: b, onTap: () => _onTapAvailableBlock(b), enabled: !_showResult)).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchBoard(PuzzleArenaPuzzle p) {
    final pairs = p.matchPairs!;
    final leftItems = pairs.map((e) => e.leftId).toList();
    final rightItems = pairs.map((e) => e.rightId).toList()..shuffle();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('TAP LEFT THEN RIGHT TO MATCH', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftItems.map((lid) {
                  final pair = pairs.firstWhere((e) => e.leftId == lid);
                  final matchedRight = _matchSelected[lid];
                  final isPicked = _matchLeftPicked == lid;
                  final isMatched = matchedRight != null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: _showResult ? null : () => _onMatchLeft(lid),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isPicked ? const Color(0xFF06B6D4).withValues(alpha: 0.14) : isMatched ? AppColors.success.withValues(alpha: 0.12) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: isPicked ? const Color(0xFF06B6D4) : isMatched ? AppColors.success : AppColors.border, width: isPicked || isMatched ? 1.6 : 1.0),
                        ),
                        child: Row(
                          children: [
                            Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: isMatched ? AppColors.success.withValues(alpha: 0.14) : isPicked ? const Color(0xFF06B6D4).withValues(alpha: 0.14) : AppColors.surfaceHigh, border: Border.all(color: isMatched ? AppColors.success : isPicked ? const Color(0xFF06B6D4) : AppColors.border)), child: Icon(isMatched ? Icons.check_rounded : isPicked ? Icons.touch_app_rounded : Icons.circle_outlined, size: 14, color: isMatched ? AppColors.success : isPicked ? const Color(0xFF06B6D4) : AppColors.textTertiary)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pair.leftLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            if (isMatched) GestureDetector(onTap: _showResult ? null : () => _clearMatchForLeft(lid), child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: rightItems.map((rid) {
                  final pair = pairs.firstWhere((e) => e.rightId == rid);
                  final isUsed = _matchSelected.containsValue(rid);
                  final leftForThis = _matchSelected.entries.where((e) => e.value == rid).map((e) => e.key).firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: _showResult ? null : () => _onMatchRight(rid),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUsed ? AppColors.success.withValues(alpha: 0.12) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: isUsed ? AppColors.success : AppColors.border, width: isUsed ? 1.6 : 1.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(pair.rightLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                            if (isUsed) ...[
                              const SizedBox(width: 6),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.success)), child: Text(pairs.firstWhere((e) => e.rightId == rid).leftLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success))),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        if (_matchLeftPicked != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF06B6D4)), const SizedBox(width: 6), Text('Selected ${pairs.firstWhere((e) => e.leftId == _matchLeftPicked).leftLabel} — now tap a right item', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF06B6D4)))]),
          ),
        ],
        if (_matchSelected.isNotEmpty && !_showResult) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() { _matchSelected = {}; _matchLeftPicked = null; }), icon: const Icon(Icons.clear_rounded, size: 14), label: const Text('CLEAR ALL'))),
        ],
        if (_showResult && !_wasCorrect) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
            child: Wrap(spacing: 6, runSpacing: 6, children: pairs.map((pair) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Text('${pair.leftLabel} → ${pair.rightLabel}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)))).toList()),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectBoard(PuzzleArenaPuzzle p) {
    final nodes = p.connectNodes!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('TAP TWO NODES TO CONNECT', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: nodes.map((n) {
            final isFirst = _connectFirst == n.id;
            final isConnected = _connectSelected.any((l) => l.from == n.id || l.to == n.id);
            return GestureDetector(
              onTap: _showResult ? null : () => _onConnectTap(n.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isFirst ? const Color(0xFF06B6D4).withValues(alpha: 0.14) : isConnected ? AppColors.success.withValues(alpha: 0.08) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: isFirst ? const Color(0xFF06B6D4) : isConnected ? AppColors.success.withValues(alpha: 0.4) : AppColors.border, width: isFirst || isConnected ? 1.6 : 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: isFirst ? const Color(0xFF06B6D4).withValues(alpha: 0.14) : isConnected ? AppColors.success.withValues(alpha: 0.14) : AppColors.surfaceHigh, border: Border.all(color: isFirst ? const Color(0xFF06B6D4) : isConnected ? AppColors.success : AppColors.border)), child: Icon(isConnected ? Icons.link_rounded : isFirst ? Icons.touch_app_rounded : Icons.circle_outlined, size: 14, color: isConnected ? AppColors.success : isFirst ? const Color(0xFF06B6D4) : AppColors.textTertiary)),
                    const SizedBox(width: 8),
                    Text(n.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (_connectSelected.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _connectSelected.map((l) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Text('${nodes.firstWhere((n) => n.id == l.from).label} → ${nodes.firstWhere((n) => n.id == l.to).label}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)))).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_connectFirst != null) Text('Selected ${nodes.firstWhere((n) => n.id == _connectFirst).label} — tap another to link', style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4), fontWeight: FontWeight.w600)),
        if (_connectSelected.isNotEmpty && !_showResult) Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() { _connectSelected = {}; _connectFirst = null; }), icon: const Icon(Icons.clear_rounded, size: 14), label: const Text('CLEAR'))),
        if (_showResult && !_wasCorrect) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
            child: Wrap(spacing: 6, runSpacing: 6, children: p.correctLinks!.map((l) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Text('${nodes.firstWhere((n) => n.id == l.from).label} → ${nodes.firstWhere((n) => n.id == l.to).label}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)))).toList()),
          ),
        ],
      ],
    );
  }

  Widget _buildDebugBoard(PuzzleArenaPuzzle p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderStrong)),
          child: SelectableText(p.codeSnippet!, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 12),
        const Text('CHOOSE FIX', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        for (var i = 0; i < p.debugOptions!.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionCard(
              index: i,
              option: PuzzleOption(id: p.debugOptions![i].id, label: p.debugOptions![i].label, description: p.debugOptions![i].description),
              selected: _selectedDebug == p.debugOptions![i].id,
              showResult: _showResult,
              isCorrect: p.correctDebugId == p.debugOptions![i].id,
              wasSelected: _selectedDebug == p.debugOptions![i].id,
              enabled: !_showResult,
              onTap: () => setState(() => _selectedDebug = p.debugOptions![i].id),
            ),
          ),
      ],
    );
  }

  Widget _buildPatternBoard(PuzzleArenaPuzzle p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF06B6D4).withValues(alpha: 0.12), AppColors.surfaceHigh]), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: p.patternSequence!.map((s) {
              final isQuestion = s == '?';
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: isQuestion ? AppColors.warning.withValues(alpha: 0.14) : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: isQuestion ? AppColors.warning : AppColors.border, width: isQuestion ? 1.6 : 1.0)),
                child: Text(s, style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w700, color: isQuestion ? AppColors.warning : AppColors.textPrimary)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        const Text('CHOOSE NEXT', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        for (var i = 0; i < p.patternOptions!.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionCard(
              index: i,
              option: p.patternOptions![i],
              selected: _selectedPattern == p.patternOptions![i].id,
              showResult: _showResult,
              isCorrect: p.correctPatternId == p.patternOptions![i].id,
              wasSelected: _selectedPattern == p.patternOptions![i].id,
              enabled: !_showResult,
              onTap: () => setState(() => _selectedPattern = p.patternOptions![i].id),
            ),
          ),
      ],
    );
  }
}

class _ArrangePuzzleCard extends StatelessWidget {
  const _ArrangePuzzleCard({required this.block, required this.index, required this.showResult, required this.isCorrectPos, required this.onRemove});
  final PuzzleBlock block;
  final int index;
  final bool showResult;
  final bool? isCorrectPos;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    Color border = const Color(0xFF06B6D4);
    Color fill = const Color(0xFF06B6D4).withValues(alpha: 0.08);
    IconData icon = Icons.drag_handle_rounded;
    Color iconColor = const Color(0xFF06B6D4);
    if (showResult) {
      if (isCorrectPos == true) {
        border = AppColors.success;
        fill = AppColors.success.withValues(alpha: 0.12);
        icon = Icons.check_rounded;
        iconColor = AppColors.success;
      } else if (isCorrectPos == false) {
        border = AppColors.error;
        fill = AppColors.error.withValues(alpha: 0.1);
        icon = Icons.close_rounded;
        iconColor = AppColors.error;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: border, width: 1.4)),
      child: Row(
        children: [
          Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: border)), child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: border))),
          const SizedBox(width: 10),
          Expanded(child: Text(block.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
          if (!showResult) ...[
            ReorderableDragStartListener(index: index, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: const Icon(Icons.drag_indicator_rounded, size: 16, color: AppColors.textTertiary))),
            const SizedBox(width: 8),
            GestureDetector(onTap: onRemove, child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error.withValues(alpha: 0.1), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))), child: const Icon(Icons.close_rounded, size: 14, color: AppColors.error))),
          ] else
            Icon(icon, size: 16, color: iconColor),
        ],
      ),
    );
  }
}

class _AvailablePuzzleBlock extends StatelessWidget {
  const _AvailablePuzzleBlock({required this.block, required this.onTap, required this.enabled});
  final PuzzleBlock block;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Block ${block.label}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: enabled ? AppColors.surface : AppColors.surfaceHigh.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: enabled ? const Color(0xFF06B6D4).withValues(alpha: 0.45) : AppColors.border, width: 1.2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF06B6D4).withValues(alpha: 0.15), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4))), child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF06B6D4))),
                  const SizedBox(width: 8),
                  Flexible(child: Text(block.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: enabled ? AppColors.textPrimary : AppColors.textTertiary))),
                ],
              ),
            ),
          ),
        ),
      );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.index, required this.option, required this.selected, required this.showResult, required this.isCorrect, required this.wasSelected, required this.enabled, required this.onTap});
  final int index;
  final PuzzleOption option;
  final bool selected;
  final bool showResult;
  final bool isCorrect;
  final bool wasSelected;
  final bool enabled;
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
        border = const Color(0xFF06B6D4);
        fill = const Color(0xFF06B6D4).withValues(alpha: 0.16);
        glyph = const Color(0xFF06B6D4);
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
      label: 'Option ${String.fromCharCode(65 + index)}: ${option.label}',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: border, width: selected || (showResult && isCorrect) ? 1.8 : 1.2), boxShadow: selected && !showResult ? [BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.30), blurRadius: 16)] : null),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: glyph.withValues(alpha: 0.14), border: Border.all(color: glyph.withValues(alpha: 0.5))), child: showResult && isCorrect ? const Icon(Icons.check_rounded, size: 15, color: AppColors.success) : showResult && wasSelected && !isCorrect ? const Icon(Icons.close_rounded, size: 15, color: AppColors.error) : Text(String.fromCharCode(65 + index), style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 13, fontWeight: FontWeight.w700, color: glyph))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(option.label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w600, height: 1.4)), if (option.description.isNotEmpty) ...[const SizedBox(height: 4), Text(option.description, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))]])),
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
  Widget build(BuildContext context) => Row(children: List.generate(3, (i) => Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 4), child: Icon(i < lives ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: i < lives ? AppColors.error : AppColors.textTertiary))));
}
