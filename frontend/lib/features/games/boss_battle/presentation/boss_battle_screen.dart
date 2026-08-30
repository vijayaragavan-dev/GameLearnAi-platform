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
import '../data/boss_battles.dart';
import '../models/boss_battle.dart';

class BossBattleScreen extends ConsumerStatefulWidget {
  const BossBattleScreen({super.key, required this.topicId, this.topicName, this.subjectId});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  @override
  ConsumerState<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends ConsumerState<BossBattleScreen> with SingleTickerProviderStateMixin {
  late List<BossBattle> _bosses;
  int _bossIndex = 0;
  int _phaseIndex = 0;
  int _bossHp = 100;
  int _maxHp = 100;
  int _lives = 3;
  int _score = 0;
  int _correctCount = 0;
  int _defeatedCount = 0;
  late GameCombo _combo;
  late GameTimer _timer;
  GameDifficulty _difficulty = GameDifficulty.medium;
  int _timeLimit = 150;
  DateTime? _start;
  bool _paused = false;
  bool _briefingDone = false;
  bool _showPhaseResult = false;
  bool _wasCorrect = false;
  bool _wasCritical = false;
  int _lastDamage = 0;
  String? _counterMessage;
  String? _selectedOption;
  List<String> _arrangeSelected = [];
  List<int> _toggleState = [];
  bool _hintVisible = false;
  Timer? _feedbackTimer;
  String? _phaseFeedback;
  late AnimationController _shakeController;

  BossBattle get _currentBoss => _bosses[_bossIndex];
  BossPhase get _currentPhase => _currentBoss.phases[_phaseIndex];

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.bossBattle);
    _bosses = BossBattles.session(count: 4);
    _initBoss();
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) { if (mounted) setState(() {}); };
    _timer.onComplete = _onTimeUp;
    _timer.start();
    _start = DateTime.now();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  void _initBoss() {
    final b = _currentBoss;
    _maxHp = b.maxHp;
    _bossHp = b.maxHp;
    _phaseIndex = 0;
    _briefingDone = false;
    _showPhaseResult = false;
    _wasCorrect = false;
    _wasCritical = false;
    _lastDamage = 0;
    _counterMessage = null;
    _selectedOption = null;
    _arrangeSelected = [];
    _toggleState = [];
    _hintVisible = false;
    _phaseFeedback = null;
    _resetPhaseState();
  }

  void _resetPhaseState() {
    final p = _currentPhase;
    _selectedOption = null;
    _arrangeSelected = [];
    if (p.type == BossPhaseType.toggle) {
      _toggleState = List<int>.from(p.initialState!);
    } else {
      _toggleState = [];
    }
    _hintVisible = false;
  }

  void _onTimeUp() => _finishGame(timedOut: true);

  void _onSelectOption(String id) {
    if (_showPhaseResult) return;
    setState(() => _selectedOption = id);
  }

  void _onToggleBit(int idx) {
    if (_showPhaseResult) return;
    setState(() {
      _toggleState[idx] = _toggleState[idx] == 0 ? 1 : 0;
    });
  }

  void _onArrangeTap(BossBlock block) {
    if (_showPhaseResult) return;
    if (_arrangeSelected.contains(block.id)) return;
    if (_arrangeSelected.length >= _currentPhase.blocks!.length) return;
    setState(() => _arrangeSelected = [..._arrangeSelected, block.id]);
  }

  void _onArrangeRemove(int idx) {
    if (_showPhaseResult) return;
    setState(() {
      final copy = [..._arrangeSelected];
      copy.removeAt(idx);
      _arrangeSelected = copy;
    });
  }

  void _onArrangeReorder(int oldIdx, int newIdx) {
    if (_showPhaseResult) return;
    if (newIdx > oldIdx) newIdx--;
    setState(() {
      final item = _arrangeSelected.removeAt(oldIdx);
      _arrangeSelected.insert(newIdx, item);
    });
  }

  void _onSubmitPhase() {
    if (_showPhaseResult) return;
    final phase = _currentPhase;
    bool correct = false;
    bool critical = false;

    // Validate selection exists
    switch (phase.type) {
      case BossPhaseType.select:
      case BossPhaseType.repair:
        if (_selectedOption == null) {
          setState(() => _phaseFeedback = 'Choose a strategy to attack!');
          return;
        }
        correct = phase.isSelectCorrect(_selectedOption!);
        break;
      case BossPhaseType.arrange:
        if (_arrangeSelected.length != phase.blocks!.length) {
          setState(() => _phaseFeedback = 'Arrange all blocks to form the attack sequence!');
          return;
        }
        correct = phase.isArrangeCorrect(_arrangeSelected);
        break;
      case BossPhaseType.toggle:
        correct = phase.isToggleCorrect(_toggleState);
        if (!correct && _toggleState.isEmpty) {
          setState(() => _phaseFeedback = 'Configure the state to strike!');
          return;
        }
        break;
    }

    // Critical hit check: if combo already >=2 and no prior miss in this boss (simplified: combo >=2)
    // Also requires correct and efficient (for arrange, no extra steps)
    if (correct) {
      critical = _combo.current >= 2;
    }

    setState(() {
      _showPhaseResult = true;
      _wasCorrect = correct;
      _wasCritical = critical && correct;
      _phaseFeedback = null;
      _counterMessage = null;
      _lastDamage = 0;
    });

    if (correct) {
      _correctCount++;
      _combo.registerHit();
      int dmg = phase.damage;
      if (_wasCritical) dmg += phase.criticalDamage;
      // Apply damage
      setState(() {
        _lastDamage = dmg;
        _bossHp -= dmg;
        if (_bossHp < 0) _bossHp = 0;
      });
      _score += GameScoring.scoreForHit(difficulty: _currentBoss.difficulty, combo: _combo.current, responseTimeSeconds: 3);
      if (_wasCritical) _score += 20; // bonus for critical
      ref.read(hapticsProvider).success();
      _shakeController.forward(from: 0);
      // Check boss defeated
      if (_bossHp <= 0) {
        // Boss defeated!
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _onBossDefeated();
        });
      } else if (_phaseIndex < _currentBoss.phases.length - 1) {
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(milliseconds: 1600), () {
          if (!mounted) return;
          setState(() {
            _phaseIndex++;
            _showPhaseResult = false;
            _wasCorrect = false;
            _wasCritical = false;
            _resetPhaseState();
          });
        });
      } else {
        // Last phase but boss not yet at 0? Still treat as victory if phases done (damage sum should be 0, but handle)
        if (_bossHp <= 0) {
          _feedbackTimer?.cancel();
          _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            _onBossDefeated();
          });
        } else {
          // If boss still has HP but phases done, force defeat (should not happen with our data, but handle)
          _feedbackTimer?.cancel();
          _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            _onBossDefeated();
          });
        }
      }
    } else {
      _combo.registerMiss();
      _lives--;
      ref.read(hapticsProvider).error();
      setState(() => _counterMessage = phase.counterAttackMessage);
      _shakeController.forward(from: 0);
      if (_lives <= 0) {
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(milliseconds: 900), () {
          if (mounted) _finishGame(outOfLives: true);
        });
        return;
      }
      // Stay on same phase, allow retry after delay showing feedback but not advancing
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(() {
          _showPhaseResult = false;
          _wasCorrect = false;
          _wasCritical = false;
          _phaseFeedback = null;
          _counterMessage = null;
          // Reset selection for retry
          _selectedOption = null;
          // For arrange, keep or clear? Clear for retry
          _arrangeSelected = [];
          if (phase.type == BossPhaseType.toggle) {
            _toggleState = List<int>.from(phase.initialState!);
          }
        });
      });
    }
  }

  void _onBossDefeated() {
    _defeatedCount++;
    if (_bossIndex < _bosses.length - 1) {
      setState(() {
        _bossIndex++;
        _initBoss();
      });
    } else {
      _finishGame();
    }
  }

  void _finishGame({bool timedOut = false, bool outOfLives = false}) {
    _timer.stop();
    final elapsed = _start == null ? 0 : DateTime.now().difference(_start!).inSeconds;
    final total = _bosses.length;
    // Accuracy based on bosses defeated? Use defeated vs total
    final accuracy = total == 0 ? 0.0 : _defeatedCount / total * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, difficulty: _difficulty, type: GameType.bossBattle, timeLimitSeconds: _timeLimit),
      score: _score,
      accuracy: accuracy,
      correctCount: _defeatedCount,
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
              onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => BossBattleScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))),
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
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bosses.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('BOSS BATTLE')), body: const EmptyState(icon: Icons.videogame_asset_off_rounded, title: 'No bosses', message: 'No bosses available.'));
    }
    final boss = _currentBoss;
    final phase = _currentPhase;
    final bossProgress = _maxHp == 0 ? 0.0 : _bossHp / _maxHp;
    final sessionProgress = (_bossIndex + (_bossHp <= 0 ? 1 : 0)) / _bosses.length;

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
                          const Icon(Icons.videogame_asset_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          const Text('BOSS BATTLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFFEF4444))),
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
                      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: sessionProgress), duration: AppMotion.fast, builder: (context, v, _) => LinearProgressIndicator(value: v.clamp(0, 1), minHeight: 6, backgroundColor: AppColors.surfaceHigh, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444))))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('BOSS ${_bossIndex + 1} / ${_bosses.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
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
                  child: _briefingDone ? _buildArena(boss, phase, bossProgress) : _buildBriefing(boss),
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
                        const Icon(Icons.pause_circle_rounded, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => setState(() { _paused = false; _timer.resume(); }), icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME'))),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT BATTLE'))),
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

  Widget _buildBriefing(BossBattle boss) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFFEF4444).withValues(alpha: 0.18), AppColors.surfaceElevated]),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
              boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]), boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 12)]),
                      child: Center(child: Text(_iconForBoss(boss), style: const TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(boss.name, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          Text(boss.title, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(boss.topic.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.45))), child: Text(boss.difficulty.displayName.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFFEF4444)))),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('BOSS INTRODUCTION', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                const SizedBox(height: 8),
                Text(boss.intro, style: const TextStyle(fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.auto_stories_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), const Text('STORY', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.secondary))]),
                      const SizedBox(height: 6),
                      Text(boss.story, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Row(children: [const Icon(Icons.school_outlined, size: 14, color: AppColors.success), const SizedBox(width: 6), const Text('LEARNING OBJECTIVE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.success))]),
                      const SizedBox(height: 6),
                      Text(boss.learningObjective, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(children: [const Icon(Icons.shield_outlined, size: 14, color: AppColors.warning), const SizedBox(width: 6), Text('BOSS HP: ${boss.maxHp} • PHASES: ${boss.phases.length}', style: const TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.warning))]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => setState(() => _briefingDone = true),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56), backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sports_mma_rounded, size: 18), SizedBox(width: 8), Text('ENTER ARENA', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w800))]),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => context.pop(), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)), child: const Text('RETREAT')),
          const SizedBox(height: 10),
          const Center(child: Text('Tip: Analyze → Act → Damage boss → Watch for counterattacks', style: TextStyle(fontSize: 11, color: AppColors.textTertiary))),
        ],
      ),
    );
  }

  String _iconForBoss(BossBattle b) {
    if (b.id == 'bb_03') return '🗡️';
    if (b.id == 'bb_09' || b.id == 'bb_10') return '🌐';
    if (b.topic == 'Programming') return '💻';
    if (b.topic == 'Mathematics') return '🔢';
    if (b.topic == 'Data Structures') return '🧱';
    if (b.topic == 'DBMS') return '🗄️';
    if (b.topic == 'Operating Systems') return '⚙️';
    if (b.topic == 'Computer Networks') return '📡';
    if (b.topic == 'Algorithms') return '🧠';
    return '👾';
  }

  Widget _buildArena(BossBattle boss, BossPhase phase, double bossProgress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Boss Header with HP
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final shake = _shakeController.value;
              final offset = shake > 0 ? (1 - shake) * 8 * (shake * 10 % 2 == 0 ? 1 : -1) : 0.0;
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFFEF4444).withValues(alpha: 0.14), AppColors.surfaceElevated]),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.30)),
                boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)])), child: Center(child: Text(_iconForBoss(boss), style: const TextStyle(fontSize: 24)))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(boss.name, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 15, fontWeight: FontWeight.w800)),
                            Text(boss.title, style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)), child: Text('HP $_bossHp / $_maxHp', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)))),
                              const SizedBox(width: 6),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4))), child: Text('PHASE ${_phaseIndex + 1} / ${boss.phases.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)))),
                            ]),
                          ],
                        ),
                      ),
                      if (_wasCorrect && _showPhaseResult)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success)), child: Text('-$_lastDamage HP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // HP Bar
                  Semantics(
                    label: 'Boss HP $_bossHp of $_maxHp',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFEF4444)), const SizedBox(width: 6), const Text('BOSS HP', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))), const Spacer(), Text('$_bossHp / $_maxHp', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: bossProgress),
                            duration: AppMotion.normal,
                            curve: AppMotion.easeOut,
                            builder: (context, v, _) => LinearProgressIndicator(
                              value: v.clamp(0, 1),
                              minHeight: 14,
                              backgroundColor: AppColors.surfaceHigh,
                              valueColor: AlwaysStoppedAnimation<Color>(v <= 0.3 ? AppColors.warning : const Color(0xFFEF4444)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_wasCritical && _showPhaseResult) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(gradient: AppGradients.streakFire, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt_rounded, size: 14, color: Colors.white), SizedBox(width: 4), Text('CRITICAL HIT!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1))]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Phase mission
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEF4444).withValues(alpha: 0.14), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4))), child: Center(child: Text('${_phaseIndex + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(phase.title, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 15, fontWeight: FontWeight.w700))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.warning.withValues(alpha: 0.4))), child: Text('${phase.damage} DMG', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.warning))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(phase.instruction, style: const TextStyle(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600)),
                if (phase.codeSnippet != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderStrong)),
                    child: SelectableText(phase.codeSnippet!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5, color: AppColors.textPrimary)),
                  ),
                ],
                if (_hintVisible && phase.hint != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), Expanded(child: Text(phase.hint!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
                  ),
                ] else if (phase.hint != null && !_showPhaseResult) ...[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _hintVisible = true), icon: const Icon(Icons.lightbulb_outline_rounded, size: 14), label: const Text('SHOW HINT'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap))),
                ],
                if (boss.hint != null && phase.hint == null && !_hintVisible && !_showPhaseResult) ...[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _hintVisible = true), icon: const Icon(Icons.lightbulb_outline_rounded, size: 14), label: const Text('SHOW HINT'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero))),
                ],
                if (_hintVisible && boss.hint != null && phase.hint == null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(boss.hint!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Battle Area — depends on phase type
          _buildPhaseBattle(phase),
          const SizedBox(height: 12),
          if (_phaseFeedback != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
              child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(_phaseFeedback!, style: const TextStyle(fontSize: 12, color: AppColors.warning)))]),
            ),
            const SizedBox(height: 8),
          ],
          if (_showPhaseResult) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _wasCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(_wasCorrect ? Icons.check_circle_rounded : Icons.warning_amber_rounded, size: 16, color: _wasCorrect ? AppColors.success : AppColors.error), const SizedBox(width: 6), Text(_wasCorrect ? (_wasCritical ? 'CRITICAL HIT! BOSS DAMAGED!' : 'HIT! BOSS DAMAGED!') : 'BOSS COUNTERATTACK!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error))]),
                  const SizedBox(height: 6),
                  if (_wasCorrect) ...[
                    Text('Dealt $_lastDamage damage! HP $_bossHp/$_maxHp', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                    if (_wasCritical) const Text('CRITICAL: Extra damage for efficient execution!', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w700)),
                    if (phase.explanation != null) ...[
                      const SizedBox(height: 6),
                      Text(phase.explanation!, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                    ],
                    if (_bossHp <= 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.4))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [Icon(Icons.celebration_rounded, size: 14, color: AppColors.success), SizedBox(width: 6), Text('BOSS DEFEATED!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success))]),
                            const SizedBox(height: 4),
                            Text(boss.victoryMessage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                            const SizedBox(height: 4),
                            Text(boss.explanation, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Text(boss.conceptExplanation, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(_counterMessage ?? 'Wrong move! Boss strikes back!', style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.error)),
                    const SizedBox(height: 4),
                    Text(_lives > 0 ? 'Lives remaining: $_lives' : 'No lives left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _lives > 0 ? AppColors.textSecondary : AppColors.error)),
                    if (_lives > 0) const Text('Prepare to counter! Analyze and retry.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _showPhaseResult
                ? null
                : () {
                    // Validate before submit handled inside _onSubmitPhase
                    _onSubmitPhase();
                  },
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: const Color(0xFFEF4444), disabledBackgroundColor: AppColors.surfaceHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(_showPhaseResult ? (_wasCorrect ? (_bossHp <= 0 ? 'BOSS DEFEATED' : 'NEXT PHASE') : (_lives <= 0 ? 'GAME OVER' : 'COUNTERED...')) : 'ATTACK!', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: _showPhaseResult ? AppColors.textTertiary : Colors.white)),
          ),
          if (!_showPhaseResult) const Padding(padding: EdgeInsets.only(top: 6), child: Center(child: Text('Analyze the situation and strike the weak point', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)))),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.pop(), child: const Text('RETREAT')),
        ],
      ),
    );
  }

  Widget _buildPhaseBattle(BossPhase phase) {
    switch (phase.type) {
      case BossPhaseType.select:
      case BossPhaseType.repair:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('CHOOSE STRATEGY', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            for (var i = 0; i < phase.options!.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BossOptionCard(
                  index: i,
                  option: phase.options![i],
                  selected: _selectedOption == phase.options![i].id,
                  showResult: _showPhaseResult,
                  isCorrect: phase.correctOptionId == phase.options![i].id,
                  wasSelected: _selectedOption == phase.options![i].id,
                  enabled: !_showPhaseResult,
                  onTap: () => _onSelectOption(phase.options![i].id),
                ),
              ),
          ],
        );
      case BossPhaseType.arrange:
        final blocks = phase.blocks!;
        final available = blocks.where((b) => !_arrangeSelected.contains(b.id)).toList();
        final selectedBlocks = _arrangeSelected.map((id) => blocks.firstWhere((b) => b.id == id)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('BATTLE SEQUENCE (${_arrangeSelected.length}/${blocks.length})', style: const TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _showPhaseResult ? (_wasCorrect ? AppColors.success : AppColors.error) : AppColors.border, width: _showPhaseResult ? 1.6 : 1.0)),
              child: _arrangeSelected.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('Tap blocks below to build attack →', style: TextStyle(fontSize: 13, color: AppColors.textTertiary.withValues(alpha: 0.9)))) )
                  : Column(
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: selectedBlocks.length,
                          onReorder: _onArrangeReorder,
                          itemBuilder: (context, idx) {
                            final block = selectedBlocks[idx];
                            final correctPos = _showPhaseResult ? phase.correctOrder![idx] == block.id : null;
                            return Padding(
                              key: ValueKey('sel_${block.id}'),
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ArrangeBlockCard(block: block, index: idx, showResult: _showPhaseResult, isCorrectPos: correctPos, onRemove: () => _onArrangeRemove(idx)),
                            );
                          },
                        ),
                        if (!_showPhaseResult) Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() => _arrangeSelected = []), icon: const Icon(Icons.clear_rounded, size: 14), label: const Text('CLEAR'))),
                      ],
                    ),
            ),
            if (_showPhaseResult && !_wasCorrect) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.success.withValues(alpha: 0.35))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CORRECT SEQUENCE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.success)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: phase.correctOrder!.map((id) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Text(blocks.firstWhere((b) => b.id == id).label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)))).toList()),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('AVAILABLE BLOCKS', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: available.map((b) => _AvailableBossBlock(block: b, onTap: () => _onArrangeTap(b), enabled: !_showPhaseResult && _arrangeSelected.length < blocks.length)).toList(),
            ),
          ],
        );
      case BossPhaseType.toggle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('CONFIGURE STATE', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_toggleState.length, (i) {
                      final cur = _toggleState[i];
                      final target = phase.targetState![i];
                      final correctBit = cur == target;
                      Color border = _showPhaseResult ? (correctBit ? AppColors.success : AppColors.error) : (cur == 1 ? const Color(0xFFEF4444) : AppColors.border);
                      Color fill = _showPhaseResult ? (correctBit ? AppColors.success.withValues(alpha: 0.14) : AppColors.error.withValues(alpha: 0.12)) : (cur == 1 ? const Color(0xFFEF4444).withValues(alpha: 0.14) : AppColors.surfaceHigh);
                      return Container(
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1.4)),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showPhaseResult ? null : () => _onToggleBit(i),
                            borderRadius: BorderRadius.circular(12),
                            child: Center(child: Text('$cur', style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 20, fontWeight: FontWeight.w700, color: _showPhaseResult ? (correctBit ? AppColors.success : AppColors.error) : (cur == 1 ? const Color(0xFFEF4444) : AppColors.textSecondary)))),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(phase.targetState!.length, (i) => Container(
                          margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                          width: 52,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning.withValues(alpha: 0.4))),
                          child: Text('${phase.targetState![i]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning)),
                        )),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 4), child: Text('TARGET', style: TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppColors.warning))),
                  const SizedBox(height: 10),
                  Text('Tap bits to configure — match target to strike boss weak point', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _BossOptionCard extends StatelessWidget {
  const _BossOptionCard({required this.index, required this.option, required this.selected, required this.showResult, required this.isCorrect, required this.wasSelected, required this.enabled, required this.onTap});
  final int index;
  final BossOption option;
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
        border = const Color(0xFFEF4444);
        fill = const Color(0xFFEF4444).withValues(alpha: 0.16);
        glyph = const Color(0xFFEF4444);
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
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: selected || (showResult && isCorrect) ? 1.8 : 1.2),
            boxShadow: selected && !showResult ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.30), blurRadius: 16)] : null,
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

class _ArrangeBlockCard extends StatelessWidget {
  const _ArrangeBlockCard({required this.block, required this.index, required this.showResult, required this.isCorrectPos, required this.onRemove});
  final BossBlock block;
  final int index;
  final bool showResult;
  final bool? isCorrectPos;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    Color border = const Color(0xFFEF4444);
    Color fill = const Color(0xFFEF4444).withValues(alpha: 0.08);
    IconData icon = Icons.drag_handle_rounded;
    Color iconColor = const Color(0xFFEF4444);
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

class _AvailableBossBlock extends StatelessWidget {
  const _AvailableBossBlock({required this.block, required this.onTap, required this.enabled});
  final BossBlock block;
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
              decoration: BoxDecoration(color: enabled ? AppColors.surface : AppColors.surfaceHigh.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: enabled ? const Color(0xFFEF4444).withValues(alpha: 0.45) : AppColors.border, width: 1.2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEF4444).withValues(alpha: 0.15), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4))), child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFFEF4444))),
                  const SizedBox(width: 8),
                  Flexible(child: Text(block.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: enabled ? AppColors.textPrimary : AppColors.textTertiary))),
                ],
              ),
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
