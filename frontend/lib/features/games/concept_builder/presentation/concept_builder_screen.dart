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
import '../data/concept_challenges.dart';
import '../models/concept_challenge.dart';

class ConceptBuilderScreen extends ConsumerStatefulWidget {
  const ConceptBuilderScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<ConceptBuilderScreen> createState() => _ConceptBuilderScreenState();
}

class _ConceptBuilderScreenState extends ConsumerState<ConceptBuilderScreen> {
  late List<ConceptChallenge> _challenges;
  int _index = 0;
  List<String> _selectedIds = [];
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

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.conceptBuilder);
    _challenges = ConceptChallenges.session(count: 4);
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) => setState(() {});
    _timer.onComplete = () => _finishGame(timedOut: true);
    _timer.start();
    _start = DateTime.now();
  }

  ConceptChallenge get _current => _challenges[_index];

  void _onTapAvailable(ConceptBlock block) {
    if (_showResult) return;
    if (_selectedIds.contains(block.id)) return;
    if (_selectedIds.length >= _current.correctOrder.length) return; // max length
    setState(() => _selectedIds = [..._selectedIds, block.id]);
  }

  void _onTapSelected(int idx) {
    if (_showResult) return;
    setState(() {
      final copy = [..._selectedIds];
      copy.removeAt(idx);
      _selectedIds = copy;
    });
  }

  void _onReorder(int oldIdx, int newIdx) {
    if (_showResult) return;
    if (newIdx > oldIdx) newIdx--;
    setState(() {
      final item = _selectedIds.removeAt(oldIdx);
      _selectedIds.insert(newIdx, item);
    });
  }

  void _onClear() {
    if (_showResult) return;
    setState(() => _selectedIds = []);
  }

  void _onSubmit() {
    if (_showResult) return;
    if (_selectedIds.isEmpty) return;
    final correct = _current.isCorrect(_selectedIds);
    setState(() {
      _showResult = true;
      _wasCorrect = correct;
    });
    if (correct) {
      _correctCount++;
      _combo.registerHit();
      final elapsedSec = _start == null ? 3 : DateTime.now().difference(_start!).inSeconds % 10;
      _score += GameScoring.scoreForHit(difficulty: _current.difficulty, combo: _combo.current, responseTimeSeconds: elapsedSec.clamp(2, 10));
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
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.conceptBuilder, timeLimitSeconds: _timeLimit),
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
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameResultScreen(result: result, onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ConceptBuilderScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))))));
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
      return Scaffold(appBar: AppBar(title: const Text('CONCEPT BUILDER')), body: const EmptyState(icon: Icons.view_module_outlined, title: 'No challenges', message: 'No concept challenges available.'));
    }
    final ch = _current;
    final progress = (_index + (_showResult ? 1 : 0)) / _challenges.length;
    final available = ch.blocks.where((b) => !_selectedIds.contains(b.id)).toList();
    final selectedBlocks = _selectedIds.map((id) => ch.blocks.firstWhere((b) => b.id == id)).toList();
    final isWide = MediaQuery.sizeOf(context).width > 900;

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
                          const Icon(Icons.build_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text('CONCEPT BUILDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.primary)),
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
                          Text('BUILD ${_index + 1} / ${_challenges.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
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
                        // Instruction card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.14), AppColors.surfaceElevated]), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.primary.withValues(alpha: 0.30))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.brand), child: const Icon(Icons.lightbulb_rounded, size: 18, color: Colors.white)), const SizedBox(width: 10), Expanded(child: Text(ch.title, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w700)))]),
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
                        // BUILD AREA
                        Text('BUILD AREA (${_selectedIds.length}/${ch.correctOrder.length})', style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(minHeight: 120),
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
                                    child: Text('Tap blocks below to build →', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textTertiary.withValues(alpha: 0.9))),
                                  ),
                                )
                              : Column(
                                  children: [
                                    ReorderableListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      buildDefaultDragHandles: false,
                                      itemCount: selectedBlocks.length,
                                      onReorder: _onReorder,
                                      itemBuilder: (context, idx) {
                                        final block = selectedBlocks[idx];
                                        final correctPos = _showResult ? ch.correctOrder[idx] == block.id : null;
                                        return Padding(
                                          key: ValueKey('selected_${block.id}'),
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: _BuildBlock(
                                            block: block,
                                            index: idx,
                                            showResult: _showResult,
                                            isCorrectPos: correctPos,
                                            onRemove: () => _onTapSelected(idx),
                                            onReorderHandle: (isDragging) {},
                                          ),
                                        );
                                      },
                                    ),
                                    if (!_showResult)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(onPressed: _onClear, icon: const Icon(Icons.clear_rounded, size: 14), label: const Text('CLEAR')),
                                      ),
                                  ],
                                ),
                        ),
                        // Feedback
                        if (_showResult) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(_wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(_wasCorrect ? 'BUILD COMPLETE ✓' : 'BUILD INCORRECT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error))]),
                                const SizedBox(height: 6),
                                Text(ch.explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                                if (!_wasCorrect) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.35))),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('CORRECT CONCEPT', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.success)),
                                        const SizedBox(height: 6),
                                        Wrap(spacing: 6, runSpacing: 6, children: ch.correctBlocks.map((b) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Text(b.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)))).toList()),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_wasCorrect) ...[
                                  const SizedBox(height: 6),
                                  Text('+${GameScoring.scoreForHit(difficulty: ch.difficulty, combo: _combo.current, responseTimeSeconds: 3)} · COMBO ${_combo.label.isEmpty ? "×1" : _combo.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // AVAILABLE BLOCKS
                        Text('AVAILABLE BLOCKS', style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                        const SizedBox(height: 8),
                        if (isWide)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: available.map((b) => _AvailableBlock(block: b, onTap: () => _onTapAvailable(b), enabled: !_showResult && _selectedIds.length < ch.correctOrder.length)).toList(),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 10, mainAxisSpacing: 10),
                            itemCount: available.length,
                            itemBuilder: (context, i) {
                              final b = available[i];
                              return _AvailableBlock(block: b, onTap: () => _onTapAvailable(b), enabled: !_showResult && _selectedIds.length < ch.correctOrder.length);
                            },
                          ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: (_selectedIds.length != ch.correctOrder.length || _showResult) ? null : _onSubmit,
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: Text(_showResult ? (_wasCorrect ? 'NEXT BUILD' : (_lives <= 0 ? 'GAME OVER' : 'CONTINUE')) : 'BUILD CONCEPT', style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.pop(), child: const Text('EXIT BUILDER')),
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
                        const Icon(Icons.pause_circle_rounded, size: 48, color: AppColors.primary),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => setState(() { _paused = false; _timer.resume(); }), icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME'))),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT BUILDER'))),
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

class _AvailableBlock extends StatelessWidget {
  const _AvailableBlock({required this.block, required this.onTap, required this.enabled});
  final ConceptBlock block;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Block ${block.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? AppColors.surface : AppColors.surfaceHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: enabled ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.15), border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))), child: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary)),
                const SizedBox(width: 8),
                Flexible(child: Text(block.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: enabled ? AppColors.textPrimary : AppColors.textTertiary))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildBlock extends StatelessWidget {
  const _BuildBlock({required this.block, required this.index, required this.showResult, required this.isCorrectPos, required this.onRemove, required this.onReorderHandle});
  final ConceptBlock block;
  final int index;
  final bool showResult;
  final bool? isCorrectPos;
  final VoidCallback onRemove;
  final ValueChanged<bool> onReorderHandle;
  @override
  Widget build(BuildContext context) {
    Color border = AppColors.primary;
    Color fill = AppColors.primary.withValues(alpha: 0.08);
    IconData icon = Icons.drag_handle_rounded;
    Color iconColor = AppColors.primary;
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
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: border)),
            child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: border)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(block.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
          if (!showResult) ...[
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: const Icon(Icons.drag_indicator_rounded, size: 16, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error.withValues(alpha: 0.1), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                child: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
              ),
            ),
          ] else
            Icon(icon, size: 16, color: iconColor),
        ],
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
