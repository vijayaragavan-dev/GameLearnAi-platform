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
import '../data/sequence_challenges.dart';
import '../models/sequence_challenge.dart';

class SequenceMasterScreen extends ConsumerStatefulWidget {
  const SequenceMasterScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<SequenceMasterScreen> createState() => _SequenceMasterScreenState();
}

class _SequenceMasterScreenState extends ConsumerState<SequenceMasterScreen> {
  late List<SequenceChallenge> _challenges;
  int _index = 0;
  List<String> _selectedIds = []; // for arrange
  String? _selectedComplete; // for complete
  bool _showResult = false;
  bool _wasCorrect = false;
  int _score = 0;
  int _lives = 3;
  int _correctCount = 0;
  late GameCombo _combo;
  late GameTimer _timer;
  GameDifficulty _difficulty = GameDifficulty.medium;
  int _timeLimit = 160;
  DateTime? _start;
  bool _paused = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.sequenceMaster);
    _challenges = SequenceChallenges.session(count: 4);
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) => setState(() {});
    _timer.onComplete = () => _finishGame(timedOut: true);
    _timer.start();
    _start = DateTime.now();
  }

  SequenceChallenge get _current => _challenges[_index];

  void _onTapAvailableArrange(SequenceBlock block) {
    if (_showResult) return;
    if (_selectedIds.contains(block.id)) return;
    if (_selectedIds.length >= _current.correctOrder.length) return;
    setState(() => _selectedIds = [..._selectedIds, block.id]);
  }

  void _onTapSelectedArrange(int idx) {
    if (_showResult) return;
    setState(() {
      final copy = [..._selectedIds];
      copy.removeAt(idx);
      _selectedIds = copy;
    });
  }

  void _onReorderArrange(int oldIdx, int newIdx) {
    if (_showResult) return;
    if (newIdx > oldIdx) newIdx--;
    setState(() {
      final item = _selectedIds.removeAt(oldIdx);
      _selectedIds.insert(newIdx, item);
    });
  }

  void _onClearArrange() {
    if (_showResult) return;
    setState(() => _selectedIds = []);
  }

  void _onSelectComplete(String candidateId) {
    if (_showResult) return;
    setState(() => _selectedComplete = candidateId);
  }

  void _onSubmit() {
    if (_showResult) return;
    final ch = _current;
    bool correct;
    if (ch.mode == SequenceMode.arrange) {
      if (_selectedIds.length != ch.correctOrder.length) return;
      correct = ch.isArrangeCorrect(_selectedIds);
    } else {
      if (_selectedComplete == null) return;
      correct = ch.isCompleteCorrect(_selectedComplete!);
    }
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
    _feedbackTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _next();
    });
  }

  void _next() {
    if (_index < _challenges.length - 1) {
      setState(() {
        _index++;
        _selectedIds = [];
        _selectedComplete = null;
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
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.sequenceMaster, timeLimitSeconds: _timeLimit),
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
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameResultScreen(result: result, onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SequenceMasterScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))))));
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
    try { _timer.dispose(); } catch (_) {}
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_challenges.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('SEQUENCE MASTER')), body: const EmptyState(icon: Icons.swap_vert_rounded, title: 'No challenges', message: 'No sequence challenges available.'));
    }
    final ch = _current;
    final progress = (_index + (_showResult ? 1 : 0)) / _challenges.length;
    final isArrange = ch.mode == SequenceMode.arrange;

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
                          const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          const Text('SEQUENCE MASTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.secondary)),
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
                      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress), duration: AppMotion.fast, builder: (context, value, _) => LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6, backgroundColor: AppColors.surfaceHigh, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary)))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('SEQUENCE ${_index + 1} / ${_challenges.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
                          const Spacer(),
                          _LivesIndicator(lives: _lives),
                          const SizedBox(width: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: ch.mode == SequenceMode.arrange ? AppColors.primary.withValues(alpha: 0.14) : AppColors.warning.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: ch.mode == SequenceMode.arrange ? AppColors.primary.withValues(alpha: 0.45) : AppColors.warning.withValues(alpha: 0.45))), child: Text(ch.mode == SequenceMode.arrange ? 'ARRANGE' : 'COMPLETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: ch.mode == SequenceMode.arrange ? AppColors.primary : AppColors.warning))),
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
                        // Title + objective
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary.withValues(alpha: 0.14), AppColors.surfaceElevated]), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.30))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.cyan), child: const Icon(Icons.psychology_rounded, size: 18, color: Colors.white)), const SizedBox(width: 10), Expanded(child: Text(ch.title, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w700)))]),
                              const SizedBox(height: 8),
                              Text(ch.learningObjective, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                                child: Text(ch.instruction, style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600)),
                              ),
                              if (ch.conceptSnippet != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderStrong)),
                                  child: SelectableText(ch.conceptSnippet!, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
                                ),
                              ],
                              if (ch.hint != null && !_showResult) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2))),
                                  child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), Expanded(child: Text(ch.hint!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isArrange) ...[
                          // Arrange mode: Available + Sequence Area
                          Text('SEQUENCE AREA (${_selectedIds.length}/${ch.correctOrder.length})', style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(minHeight: 140),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: _showResult ? (_wasCorrect ? AppColors.success : AppColors.error) : AppColors.border, width: _showResult ? 1.6 : 1.0),
                            ),
                            child: _selectedIds.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Text('Tap blocks below to build sequence →', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textTertiary.withValues(alpha: 0.9))),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      ReorderableListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        buildDefaultDragHandles: false,
                                        itemCount: _selectedIds.length,
                                        onReorder: _onReorderArrange,
                                        itemBuilder: (context, idx) {
                                          final id = _selectedIds[idx];
                                          final block = ch.sequenceBlocks.firstWhere((b) => b.id == id, orElse: () => ch.sequenceBlocks.first);
                                          final correctPos = _showResult ? ch.correctOrder[idx] == id : null;
                                          return Padding(
                                            key: ValueKey('seq_$id'),
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: _SequenceBlockCard(
                                              block: block,
                                              index: idx,
                                              showResult: _showResult,
                                              isCorrectPos: correctPos,
                                              onRemove: () => _onTapSelectedArrange(idx),
                                            ),
                                          );
                                        },
                                      ),
                                      // Arrows between blocks are visual via block card's bottom arrow (inside _SequenceBlockCard)
                                      if (!_showResult)
                                        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _onClearArrange, icon: const Icon(Icons.clear_rounded, size: 14), label: const Text('CLEAR'))),
                                    ],
                                  ),
                          ),
                          if (_showResult) ...[
                            const SizedBox(height: 12),
                            _FeedbackCard(wasCorrect: _wasCorrect, explanation: ch.explanation, correctBlocks: ch.sequenceBlocks.where((b) => ch.correctOrder.contains(b.id)).toList(), scoreDelta: _wasCorrect ? GameScoring.scoreForHit(difficulty: ch.difficulty, combo: _combo.current, responseTimeSeconds: 3) : 0, comboLabel: _combo.label),
                          ],
                          const SizedBox(height: 16),
                          Text('AVAILABLE BLOCKS', style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                          const SizedBox(height: 8),
                          _AvailableWrap(
                            blocks: ch.sequenceBlocks.where((b) => !_selectedIds.contains(b.id)).toList(),
                            enabled: !_showResult && _selectedIds.length < ch.correctOrder.length,
                            onTap: _onTapAvailableArrange,
                          ),
                        ] else ...[
                          // Complete mode: Show sequence with missing slots
                          Text('COMPLETE THE SEQUENCE', style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _showResult ? (_wasCorrect ? AppColors.success : AppColors.error) : AppColors.border, width: _showResult ? 1.6 : 1.0)),
                            child: Column(
                              children: List.generate(ch.sequenceBlocks.length, (i) {
                                final isMissing = ch.missingPositions?.contains(i) ?? false;
                                final block = ch.sequenceBlocks[i];
                                final candidate = isMissing ? ch.candidateBlocks?.firstWhere((c) => c.id == _selectedComplete, orElse: () => ch.candidateBlocks!.first) : null;
                                return Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isMissing
                                            ? (_showResult
                                                ? (_wasCorrect ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12))
                                                : (_selectedComplete != null ? AppColors.warning.withValues(alpha: 0.14) : AppColors.surfaceHigh))
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                        border: Border.all(color: isMissing ? (_showResult ? (_wasCorrect ? AppColors.success : AppColors.error) : (_selectedComplete != null ? AppColors.warning : AppColors.border)) : AppColors.border, width: isMissing ? 1.4 : 1.0),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(shape: BoxShape.circle, color: isMissing ? AppColors.warning.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.12), border: Border.all(color: isMissing ? AppColors.warning : AppColors.primary)),
                                            child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isMissing ? AppColors.warning : AppColors.primary)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              isMissing ? (_selectedComplete != null ? candidate!.label : '???') : block.label,
                                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: isMissing && _selectedComplete == null ? AppColors.textTertiary : AppColors.textPrimary),
                                            ),
                                          ),
                                          if (isMissing && _showResult)
                                            Icon(_wasCorrect ? Icons.check_rounded : Icons.close_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error)
                                          else if (!isMissing)
                                            const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.textTertiary),
                                        ],
                                      ),
                                    ),
                                    if (i < ch.sequenceBlocks.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.textTertiary)),
                                  ],
                                );
                              }),
                            ),
                          ),
                          if (_showResult) ...[
                            const SizedBox(height: 12),
                            _FeedbackCard(wasCorrect: _wasCorrect, explanation: ch.explanation, correctBlocks: ch.sequenceBlocks, scoreDelta: _wasCorrect ? GameScoring.scoreForHit(difficulty: ch.difficulty, combo: _combo.current, responseTimeSeconds: 3) : 0, comboLabel: _combo.label),
                          ],
                          const SizedBox(height: 16),
                          Text('CANDIDATE BLOCKS', style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: (ch.candidateBlocks ?? []).map((b) {
                              final selected = _selectedComplete == b.id;
                              final showRes = _showResult;
                              final isCorrect = b.id == ch.correctAnswer;
                              Color border = AppColors.border;
                              Color fill = AppColors.surface;
                              if (showRes) {
                                if (isCorrect) {
                                  border = AppColors.success;
                                  fill = AppColors.success.withValues(alpha: 0.14);
                                } else if (selected && !isCorrect) {
                                  border = AppColors.error;
                                  fill = AppColors.error.withValues(alpha: 0.12);
                                }
                              } else if (selected) {
                                border = AppColors.warning;
                                fill = AppColors.warning.withValues(alpha: 0.16);
                              }
                              return GestureDetector(
                                onTap: _showResult ? null : () => _onSelectComplete(b.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: border, width: selected || (showRes && isCorrect) ? 1.8 : 1.2)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: (showRes && isCorrect ? AppColors.success : selected ? AppColors.warning : AppColors.textTertiary).withValues(alpha: 0.15), border: Border.all(color: showRes && isCorrect ? AppColors.success : selected ? AppColors.warning : AppColors.textTertiary)), child: Icon(showRes && isCorrect ? Icons.check_rounded : showRes && selected && !isCorrect ? Icons.close_rounded : Icons.add_rounded, size: 14, color: showRes && isCorrect ? AppColors.success : showRes && selected && !isCorrect ? AppColors.error : selected ? AppColors.warning : AppColors.textTertiary)),
                                      const SizedBox(width: 8),
                                      Text(b.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: () {
                            if (_showResult) return null;
                            if (isArrange) {
                              if (_selectedIds.length != ch.correctOrder.length) return null;
                            } else {
                              if (_selectedComplete == null) return null;
                            }
                            return _onSubmit;
                          }(),
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: Text(_showResult ? (_wasCorrect ? 'NEXT SEQUENCE' : (_lives <= 0 ? 'GAME OVER' : 'CONTINUE')) : (isArrange ? 'SUBMIT SEQUENCE' : 'COMPLETE SEQUENCE'), style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.pop(), child: const Text('EXIT MASTER')),
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
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT MASTER'))),
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

class _SequenceBlockCard extends StatelessWidget {
  const _SequenceBlockCard({required this.block, required this.index, required this.showResult, required this.isCorrectPos, required this.onRemove});
  final SequenceBlock block;
  final int index;
  final bool showResult;
  final bool? isCorrectPos;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    Color border = AppColors.secondary;
    Color fill = AppColors.secondary.withValues(alpha: 0.08);
    IconData icon = Icons.drag_handle_rounded;
    Color iconColor = AppColors.secondary;
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
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: border)),
            child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: border)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(block.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
          if (!showResult) ...[
            ReorderableDragStartListener(
              index: index,
              child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: const Icon(Icons.drag_indicator_rounded, size: 16, color: AppColors.textTertiary)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error.withValues(alpha: 0.1), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))), child: const Icon(Icons.close_rounded, size: 14, color: AppColors.error)),
            ),
          ] else
            Icon(icon, size: 16, color: iconColor),
        ],
      ),
    );
  }
}

class _AvailableWrap extends StatelessWidget {
  const _AvailableWrap({required this.blocks, required this.enabled, required this.onTap});
  final List<SequenceBlock> blocks;
  final bool enabled;
  final ValueChanged<SequenceBlock> onTap;
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 900;
    if (isWide) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: blocks.map((b) => _AvailChip(block: b, enabled: enabled, onTap: () => onTap(b))).toList(),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: blocks.length,
      itemBuilder: (context, i) => _AvailChip(block: blocks[i], enabled: enabled, onTap: () => onTap(blocks[i])),
    );
  }
}

class _AvailChip extends StatelessWidget {
  const _AvailChip({required this.block, required this.enabled, required this.onTap});
  final SequenceBlock block;
  final bool enabled;
  final VoidCallback onTap;
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
              decoration: BoxDecoration(color: enabled ? AppColors.surface : AppColors.surfaceHigh.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: enabled ? AppColors.secondary.withValues(alpha: 0.45) : AppColors.border, width: 1.2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary.withValues(alpha: 0.15), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4))), child: const Icon(Icons.add_rounded, size: 16, color: AppColors.secondary)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(block.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: enabled ? AppColors.textPrimary : AppColors.textTertiary))),
                ],
              ),
            ),
          ),
        ),
      );
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.wasCorrect, required this.explanation, required this.correctBlocks, required this.scoreDelta, required this.comboLabel});
  final bool wasCorrect;
  final String explanation;
  final List<SequenceBlock> correctBlocks;
  final int scoreDelta;
  final String comboLabel;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: wasCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: wasCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(wasCorrect ? 'SEQUENCE MASTERED!' : 'SEQUENCE INCORRECT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: wasCorrect ? AppColors.success : AppColors.error))]),
            const SizedBox(height: 6),
            Text(explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: wasCorrect ? AppColors.success.withValues(alpha: 0.35) : AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wasCorrect ? 'YOUR SEQUENCE (CORRECT)' : 'CORRECT SEQUENCE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: wasCorrect ? AppColors.success : AppColors.textTertiary)),
                  const SizedBox(height: 6),
                  ...correctBlocks.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success.withValues(alpha: 0.12), border: Border.all(color: AppColors.success)), child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.value.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                          const Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.textTertiary),
                        ]),
                      )),
                ],
              ),
            ),
            if (wasCorrect) ...[
              const SizedBox(height: 6),
              Text('+$scoreDelta ${comboLabel.isEmpty ? '' : comboLabel}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
            ],
          ],
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
