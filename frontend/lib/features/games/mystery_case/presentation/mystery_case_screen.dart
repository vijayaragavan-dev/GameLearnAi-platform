import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/game_visual_identity.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_surfaces.dart';
import '../../../game_engine/engine/game_combo.dart';
import '../../../game_engine/engine/game_scoring.dart';
import '../../../game_engine/engine/game_timer.dart';
import '../../../game_engine/models/game_models.dart';
import '../../../game_engine/utils/difficulty_utils.dart';
import '../../../game_engine/widgets/game_hud.dart';
import '../../../game_engine/widgets/game_result_screen.dart';
import '../data/mystery_cases.dart';
import '../models/mystery_case.dart';

class MysteryCaseScreen extends ConsumerStatefulWidget {
  const MysteryCaseScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<MysteryCaseScreen> createState() => _MysteryCaseScreenState();
}

class _MysteryCaseScreenState extends ConsumerState<MysteryCaseScreen> {
  late List<MysteryCase> _cases;
  int _index = 0;
  Set<String> _discovered = {};
  Set<String> _collected = {};
  String? _selectedSolution;
  bool _showCaseResult = false;
  bool _wasCorrect = false;
  bool _briefingDone = false;
  bool _hintVisible = false;
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
  String? _feedbackMessage;

  MysteryCase get _current => _cases[_index];

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.mysteryCase);
    // Use mysteryCase fallback: if not in utils, default 150/180 etc handled via default. Ensure we have mapping.
    _cases = MysteryCases.session(count: 4);
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) {
      if (mounted) setState(() {});
    };
    _timer.onComplete = _onTimeUp;
    _timer.start();
    _start = DateTime.now();
  }

  void _onTimeUp() => _finishGame(timedOut: true);

  void _onDiscoverClue(MysteryClue clue) {
    if (_showCaseResult) return;
    if (_discovered.contains(clue.id)) return;
    setState(() {
      _discovered = {..._discovered, clue.id};
      _feedbackMessage = null;
    });
    ref.read(hapticsProvider).tap();
  }

  void _onCollectEvidence(MysteryClue clue) {
    if (_showCaseResult) return;
    if (!_discovered.contains(clue.id)) return;
    if (_collected.contains(clue.id)) return;
    setState(() {
      _collected = {..._collected, clue.id};
      _feedbackMessage = null;
    });
    ref.read(hapticsProvider).success();
  }

  void _onSelectSolution(String sid) {
    if (_showCaseResult) return;
    setState(() => _selectedSolution = sid);
  }

  void _onSolve() {
    if (_showCaseResult) return;
    final c = _current;
    if (_selectedSolution == null) {
      setState(() => _feedbackMessage = 'Select a deduction first — review evidence.');
      return;
    }
    if (!c.canSolve(_collected)) {
      setState(() => _feedbackMessage = 'Need ${c.requiredEvidence - _collected.length} more evidence — keep investigating!');
      return;
    }
    if (!c.hasSolution(_selectedSolution!)) {
      setState(() => _feedbackMessage = 'Invalid deduction.');
      return;
    }
    final correct = c.isCorrectSolution(_selectedSolution!);
    setState(() {
      _showCaseResult = true;
      _wasCorrect = correct;
      _feedbackMessage = null;
    });
    if (correct) {
      _correctCount++;
      _combo.registerHit();
      final elapsedSec = _start == null ? 3 : DateTime.now().difference(_start!).inSeconds % 10;
      _score += GameScoring.scoreForHit(difficulty: c.difficulty, combo: _combo.current, responseTimeSeconds: elapsedSec.clamp(2, 10));
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
      _nextCase();
    });
  }

  void _nextCase() {
    if (_index < _cases.length - 1) {
      setState(() {
        _index++;
        _discovered = {};
        _collected = {};
        _selectedSolution = null;
        _showCaseResult = false;
        _wasCorrect = false;
        _briefingDone = false;
        _hintVisible = false;
        _feedbackMessage = null;
      });
    } else {
      _finishGame();
    }
  }

  void _finishGame({bool timedOut = false, bool outOfLives = false}) {
    _timer.stop();
    final elapsed = _start == null ? 0 : DateTime.now().difference(_start!).inSeconds;
    final total = _cases.length;
    final accuracy = total == 0 ? 0.0 : _correctCount / total * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.mysteryCase, timeLimitSeconds: _timeLimit),
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
              onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MysteryCaseScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))),
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
    try { _timer.dispose(); } catch (_) {}
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cases.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('MYSTERY CASE')), body: const EmptyState(icon: Icons.search_off_rounded, title: 'No cases', message: 'No mystery cases available.'));
    }
    final c = _current;
    final progress = (_index + (_showCaseResult && _wasCorrect ? 1 : 0)) / _cases.length;
    final evidenceProgress = c.requiredEvidence == 0 ? 1.0 : (_collected.length / c.requiredEvidence).clamp(0.0, 1.0);
    final identity = GameVisualRegistry.of(GameType.mysteryCase);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                GameHud(
                  score: _score,
                  progress: progress,
                  progressLabel: 'CASE ${_index + 1} / ${_cases.length}',
                  timeRemaining: _fmt(_timer.remaining),
                  combo: _combo,
                  difficultyLabel: _difficulty.displayName,
                  accent: identity.accent,
                  gameIcon: identity.icon,
                  gameTitle: GameType.mysteryCase.displayName,
                  onPause: () => setState(() { _paused = true; _timer.pause(); }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      _LivesIndicator(lives: _lives),
                      const Spacer(),
                      Text('EVIDENCE  ${_collected.length} / ${c.requiredEvidence}', style: const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
                    ],
                  ),
                ),
                Expanded(
                  child: _briefingDone ? _buildInvestigationBoard(c, evidenceProgress) : _buildBriefing(c),
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
                        const Icon(Icons.pause_circle_rounded, size: 48, color: Color(0xFF8B5CF6)),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => setState(() { _paused = false; _timer.resume(); }), icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME'))),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT CASE'))),
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

  Widget _buildBriefing(MysteryCase c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.18), AppColors.surfaceElevated]),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
              boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)])), child: const Icon(Icons.search_rounded, color: Colors.white, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title.toUpperCase(), style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(c.topic.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.45))), child: Text(c.difficulty.displayName.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8B5CF6)))),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('CASE BRIEFING', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
                const SizedBox(height: 8),
                Text(c.caseBriefing, style: const TextStyle(fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), const Text('BACKGROUND', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.secondary))]),
                      const SizedBox(height: 6),
                      Text(c.background, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Row(children: [const Icon(Icons.school_outlined, size: 14, color: AppColors.success), const SizedBox(width: 6), const Text('LEARNING OBJECTIVE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.success))]),
                      const SizedBox(height: 6),
                      Text(c.learningObjective, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(children: [const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), const Text('MISSION', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.warning))]),
                      const SizedBox(height: 6),
                      Text(c.investigationQuestion, style: const TextStyle(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => setState(() => _briefingDone = true),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56), backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_rounded, size: 18), SizedBox(width: 8), Text('START INVESTIGATION', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w800))]),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => context.pop(), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)), child: const Text('EXIT CASE')),
          const SizedBox(height: 10),
          const Center(child: Text('Tip: Examine clues → Collect evidence → Deduce culprit', style: TextStyle(fontSize: 11, color: AppColors.textTertiary))),
        ],
      ),
    );
  }

  Widget _buildInvestigationBoard(MysteryCase c, double evidenceProgress) {
    final identity = GameVisualRegistry.of(GameType.mysteryCase);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameChallengeSurface(
            accent: identity.accent,
            title: 'CASE FILE',
            icon: identity.icon,
            subtitle: c.topic.toUpperCase(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Case objective header
                Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.14), AppColors.surfaceElevated]), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.30))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)])), child: const Icon(Icons.lightbulb_rounded, size: 18, color: Colors.white)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(c.title, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 15, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(c.difficulty.displayName.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                ]),
                const SizedBox(height: 10),
                Text(c.investigationQuestion, style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(c.learningObjective, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Investigation progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, size: 14, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 6),
                    Text('EVIDENCE  ${_collected.length} / ${c.requiredEvidence}', style: const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
                    const Spacer(),
                    if (_collected.length >= c.requiredEvidence)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.4))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success), SizedBox(width: 4), Text('READY TO SOLVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success))])),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: evidenceProgress),
                    duration: AppMotion.fast,
                    builder: (context, v, _) => LinearProgressIndicator(value: v.clamp(0, 1), minHeight: 8, backgroundColor: AppColors.surfaceHigh, valueColor: AlwaysStoppedAnimation<Color>(v >= 1 ? AppColors.success : const Color(0xFF8B5CF6))),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _collected.isEmpty
                            ? [const Text('No evidence yet — tap clues to collect', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))]
                            : _collected.map((eid) {
                                final clue = c.clues.firstWhere((cl) => cl.id == eid);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.4))),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified_rounded, size: 12, color: AppColors.success), const SizedBox(width: 4), Text(clue.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success))]),
                                );
                              }).toList(),
                      ),
                    ),
                  ],
                ),
                if (_hintVisible) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(c.hint, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)))]),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(onPressed: () => setState(() => _hintVisible = true), icon: const Icon(Icons.lightbulb_outline_rounded, size: 14), label: const Text('SHOW HINT'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Suspects / Entities
          if (c.entities.isNotEmpty) ...[
            const Text('SUSPECTS / SYSTEMS', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: c.entities.map((e) {
                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8B5CF6).withValues(alpha: 0.14), border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4))), child: const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF8B5CF6))), const SizedBox(width: 8), Expanded(child: Text(e.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                        const SizedBox(height: 6),
                        Text(e.role, style: const TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                        const SizedBox(height: 4),
                        Text(e.description, style: const TextStyle(fontSize: 11, height: 1.4, color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                        if (e.alibi != null) ...[
                          const SizedBox(height: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Text('Alibi: ${e.alibi}', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Clues
          Row(
            children: [
              const Text('CLUES TO EXAMINE', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
              const Spacer(),
              Text('${_discovered.length}/${c.clues.length} examined', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.92, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: c.clues.length,
            itemBuilder: (context, i) {
              final clue = c.clues[i];
              final discovered = _discovered.contains(clue.id);
              final collected = _collected.contains(clue.id);
              return _ClueCard(
                clue: clue,
                discovered: discovered,
                collected: collected,
                showResult: _showCaseResult,
                onExamine: () => _onDiscoverClue(clue),
                onCollect: () => _onCollectEvidence(clue),
              );
            },
          ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Deduction / Solutions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _collected.length >= c.requiredEvidence ? const Color(0xFF8B5CF6).withValues(alpha: 0.4) : AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_rounded, size: 14, color: _collected.length >= c.requiredEvidence ? const Color(0xFF8B5CF6) : AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text('DEDUCTION', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: _collected.length >= c.requiredEvidence ? const Color(0xFF8B5CF6) : AppColors.textTertiary)),
                    const Spacer(),
                    if (_collected.length < c.requiredEvidence)
                      Text('Collect ${c.requiredEvidence - _collected.length} more', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning))
                    else
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c.investigationQuestion, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.4)),
                const SizedBox(height: 12),
                for (var j = 0; j < c.solutions.length; j++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SolutionCard(
                      index: j,
                      option: c.solutions[j],
                      selected: _selectedSolution == c.solutions[j].id,
                      showResult: _showCaseResult,
                      isCorrect: c.correctSolutionId == c.solutions[j].id,
                      wasSelected: _selectedSolution == c.solutions[j].id,
                      enabled: !_showCaseResult,
                      onTap: () => _onSelectSolution(c.solutions[j].id),
                    ),
                  ),
                if (_feedbackMessage != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                    child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(_feedbackMessage!, style: const TextStyle(fontSize: 12, color: AppColors.warning)))]),
                  ),
                ],
                if (_showCaseResult) ...[
                  const SizedBox(height: 10),
                  GameFeedbackSurface(
                    isCorrect: _wasCorrect,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Icon(_wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(_wasCorrect ? 'CASE SOLVED!' : 'INCORRECT DEDUCTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error))]),
                        const SizedBox(height: 6),
                        Text(c.explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [Icon(Icons.school_outlined, size: 12, color: AppColors.success), SizedBox(width: 6), Text('CONCEPT', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.success))]),
                              const SizedBox(height: 4),
                              Text(c.conceptExplanation, style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (_wasCorrect) ...[
                          const SizedBox(height: 6),
                          Text('+${GameScoring.scoreForHit(difficulty: c.difficulty, combo: _combo.current, responseTimeSeconds: 3)} · ${_combo.label.isEmpty ? "COMBO x1" : _combo.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ] else ...[
                          const SizedBox(height: 6),
                          Text(_lives > 0 ? 'Lives remaining: $_lives — keep investigating!' : 'No lives left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _lives > 0 ? AppColors.textSecondary : AppColors.error)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _showCaseResult
                ? null
                : () {
                    if (_selectedSolution == null) {
                      setState(() => _feedbackMessage = 'Select a deduction first.');
                      return;
                    }
                    if (!c.canSolve(_collected)) {
                      setState(() => _feedbackMessage = 'Need ${c.requiredEvidence - _collected.length} more evidence — examine and collect clues!');
                      return;
                    }
                    _onSolve();
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: const Color(0xFF8B5CF6),
              disabledBackgroundColor: AppColors.surfaceHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(_showCaseResult ? (_wasCorrect ? 'CASE SOLVED — NEXT' : (_lives <= 0 ? 'GAME OVER' : 'REVIEWING...')) : 'SOLVE CASE', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: _showCaseResult ? AppColors.textTertiary : Colors.white)),
          ),
          const SizedBox(height: 8),
          if (!_showCaseResult)
            Center(child: Text(_collected.length >= c.requiredEvidence ? 'Select a deduction above and solve' : 'Examine clues and collect ${c.requiredEvidence - _collected.length} more evidence to unlock solving', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary), textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.pop(), child: const Text('EXIT INVESTIGATION')),
        ],
      ),
    );
  }
}

class _ClueCard extends StatelessWidget {
  const _ClueCard({required this.clue, required this.discovered, required this.collected, required this.showResult, required this.onExamine, required this.onCollect});
  final MysteryClue clue;
  final bool discovered;
  final bool collected;
  final bool showResult;
  final VoidCallback onExamine;
  final VoidCallback onCollect;

  IconData _iconFor(ClueCategory cat) => switch (cat) {
        ClueCategory.document => Icons.description_outlined,
        ClueCategory.log => Icons.terminal_rounded,
        ClueCategory.diagram => Icons.account_tree_rounded,
        ClueCategory.database => Icons.storage_rounded,
        ClueCategory.network => Icons.wifi_tethering_rounded,
        ClueCategory.codeSnippet => Icons.code_rounded,
        ClueCategory.observation => Icons.visibility_outlined,
        ClueCategory.timeline => Icons.timeline_rounded,
        ClueCategory.scientific => Icons.science_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Color border;
    Color fill;
    if (collected) {
      border = AppColors.success;
      fill = AppColors.success.withValues(alpha: 0.12);
    } else if (discovered) {
      border = const Color(0xFF8B5CF6);
      fill = const Color(0xFF8B5CF6).withValues(alpha: 0.10);
    } else {
      border = AppColors.border;
      fill = AppColors.surface;
    }
    return Semantics(
      button: true,
      label: 'Clue ${clue.title}',
      child: GestureDetector(
        onTap: discovered ? null : onExamine,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: discovered ? 1.6 : 1.0),
            boxShadow: discovered && !collected ? [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.20), blurRadius: 12)] : collected ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.18), blurRadius: 12)] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: (collected ? AppColors.success : discovered ? const Color(0xFF8B5CF6) : AppColors.textTertiary).withValues(alpha: 0.14), border: Border.all(color: collected ? AppColors.success : discovered ? const Color(0xFF8B5CF6) : AppColors.textTertiary)), child: Icon(collected ? Icons.verified_rounded : discovered ? Icons.visibility_rounded : _iconFor(clue.category), size: 14, color: collected ? AppColors.success : discovered ? const Color(0xFF8B5CF6) : AppColors.textTertiary)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(clue.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: collected ? AppColors.success : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (collected) const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                ],
              ),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)), child: Text(clue.category.displayName.toUpperCase(), style: const TextStyle(fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppColors.textTertiary))),
              const SizedBox(height: 8),
              Expanded(
                child: discovered
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(clue.content, style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.textSecondary)),
                            if (clue.detail != null) ...[
                              const SizedBox(height: 4),
                              Text(clue.detail!, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
                            ],
                            if (!collected && !showResult) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: onCollect,
                                  style: FilledButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  child: const Text('COLLECT EVIDENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                                ),
                              ),
                            ],
                            if (collected)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bookmark_added_rounded, size: 10, color: AppColors.success), SizedBox(width: 4), Text('EVIDENCE COLLECTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success))]),
                              ),
                            if (clue.isKeyEvidence && discovered && !collected) const Padding(padding: EdgeInsets.only(top: 4), child: Text('★ Key evidence', style: TextStyle(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.w700))),
                            if (!clue.isKeyEvidence && discovered) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Distractor — not needed', style: TextStyle(fontSize: 9, color: AppColors.textTertiary))),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textTertiary),
                          const SizedBox(height: 6),
                          const Text('Tap to examine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                          const SizedBox(height: 4),
                          Text(clue.category.displayName, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({required this.index, required this.option, required this.selected, required this.showResult, required this.isCorrect, required this.wasSelected, required this.enabled, required this.onTap});
  final int index;
  final MysterySolutionOption option;
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
        border = const Color(0xFF8B5CF6);
        fill = const Color(0xFF8B5CF6).withValues(alpha: 0.16);
        glyph = const Color(0xFF8B5CF6);
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
      label: 'Deduction ${String.fromCharCode(65 + index)}: ${option.label}',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: selected || (showResult && isCorrect) ? 1.8 : 1.2),
            boxShadow: selected && !showResult ? [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.30), blurRadius: 16)] : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w600, height: 1.4, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(option.description, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3)),
                  ],
                ),
              ),
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
