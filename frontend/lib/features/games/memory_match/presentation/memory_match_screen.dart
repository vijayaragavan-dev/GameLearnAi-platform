import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/audio_manager.dart' show MusicContext;
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/models/content_models.dart';
import '../../../../core/models/quiz_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../game_engine/audio/game_sound_controller.dart';
import '../../../game_engine/engine/game_combo.dart';
import '../../../game_engine/engine/game_scoring.dart';
import '../../../game_engine/engine/game_timer.dart';
import '../../../game_engine/models/game_models.dart';
import '../../../game_engine/utils/difficulty_utils.dart';
import '../../../game_engine/utils/game_content_mapper.dart';
import '../../../game_engine/widgets/game_scaffold.dart';
import '../../../game_engine/widgets/game_result_screen.dart';

class MemoryCard {
  MemoryCard({required this.id, required this.pairId, required this.label, required this.isTerm});
  final String id;
  final String pairId;
  final String label;
  final bool isTerm;
  bool isFlipped = false;
  bool isMatched = false;
}

/// Memory Match: flip to find term-definition pairs.
class MemoryMatchScreen extends ConsumerStatefulWidget {
  const MemoryMatchScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends ConsumerState<MemoryMatchScreen> {
  GameDifficulty _difficulty = GameDifficulty.medium;
  late GameCombo _combo;
  late GameTimer _timer;
  List<MemoryCard> _cards = [];
  MemoryCard? _first;
  MemoryCard? _second;
  bool _busy = false;
  int _matchedPairs = 0;
  int _moves = 0;
  int _score = 0;
  bool _loading = true;
  String? _error;
  DateTime? _start;
  bool _paused = false;
  bool _soundEnabled = true;
  int _timeLimit = 90;

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _soundEnabled = ref.read(audioManagerProvider).sfxEnabled;
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fetch lesson + quiz + topic in parallel for content mapping.
      final contentRepo = ref.read(contentRepoProvider);
      final quizRepo = ref.read(quizRepoProvider);
      Future<dynamic> safeLesson() async { try { return await contentRepo.lesson(widget.topicId); } catch (_) { return null; } }
      Future<dynamic> safeQuiz() async { try { return await quizRepo.quizForTopic(widget.topicId); } catch (_) { return null; } }
      Future<dynamic> safeTopic() async { try { return await contentRepo.topic(widget.topicId); } catch (_) { return null; } }
      final results = await Future.wait([safeLesson(), safeQuiz(), safeTopic()]);
      final lesson = results[0] as dynamic;
      final quiz = results[1] as dynamic;
      final topic = results[2] as dynamic;
      final Lesson? typedLesson = lesson is Lesson ? lesson : null;
      final Quiz? typedQuiz = quiz is Quiz ? quiz : null;
      final Topic? typedTopic = topic is Topic ? topic : null;

      // Resolve difficulty from topic/lesson
      _difficulty = DifficultyUtils.resolve(topicDifficulty: typedTopic?.difficulty, masteryLevel: null);
      final pairs = GameContentMapper.memoryPairs(quiz: typedQuiz, lesson: typedLesson, topic: typedTopic, maxPairs: _pairsForDifficulty(_difficulty));
      if (pairs.length < 2) {
        throw Exception('Not enough learning content to build memory pairs for this topic.');
      }
      // Build cards: each pair yields two cards (term & definition) sharing pairId
      final cards = <MemoryCard>[];
      for (var i = 0; i < pairs.length; i++) {
        final p = pairs[i];
        final pairId = 'pair_$i';
        cards.add(MemoryCard(id: 'term_$i', pairId: pairId, label: p.term, isTerm: true));
        cards.add(MemoryCard(id: 'def_$i', pairId: pairId, label: p.definition, isTerm: false));
      }
      cards.shuffle(math.Random(42)); // deterministic shuffle for testability
      _timer = GameTimer(totalSeconds: _timeLimit);
      _timer.onTickValue = (_) => setState(() {});
      _timer.onComplete = _onTimeUp;
      _timer.start();
      _start = DateTime.now();
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = describeError(e).message;
        _loading = false;
      });
    }
  }

  int _pairsForDifficulty(GameDifficulty d) => switch (d) { GameDifficulty.easy => 4, GameDifficulty.medium => 6, GameDifficulty.hard => 8 };

  void _onTimeUp() {
    _finishGame(timedOut: true);
  }

  Future<void> _onTapCard(MemoryCard card) async {
    if (_busy || card.isFlipped || card.isMatched || _paused) return;
    final sound = ref.read(gameSoundControllerProvider);
    await sound.cardFlip();
    setState(() => card.isFlipped = true);
    if (_first == null) {
      _first = card;
      return;
    }
    if (_second == null && card.id != _first!.id) {
      _second = card;
      _moves++;
      setState(() => _busy = true);
      // Evaluate match after short delay for flip animation
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      if (_first!.pairId == _second!.pairId) {
        // Match!
        setState(() {
          _first!.isMatched = true;
          _second!.isMatched = true;
          _matchedPairs++;
        });
        _combo.registerHit();
        _score += GameScoring.scoreForHit(difficulty: _difficulty, combo: _combo.current, responseTimeSeconds: 2);
        await sound.match();
        if (_combo.isHot) await sound.combo();
        ref.read(hapticsProvider).success();
        _first = null;
        _second = null;
        setState(() => _busy = false);
        if (_matchedPairs * 2 == _cards.length) {
          _finishGame();
        }
      } else {
        // Mismatch
        _combo.registerMiss();
        await sound.mismatch();
        ref.read(hapticsProvider).error();
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() {
          _first!.isFlipped = false;
          _second!.isFlipped = false;
          _first = null;
          _second = null;
          _busy = false;
        });
      }
    }
  }

  void _finishGame({bool timedOut = false}) {
    _timer.stop();
    final elapsed = _start == null ? _timeLimit : DateTime.now().difference(_start!).inSeconds;
    final totalPairs = _cards.length ~/ 2;
    final accuracy = totalPairs == 0 ? 0.0 : _matchedPairs / totalPairs * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.memoryMatch, timeLimitSeconds: _timeLimit),
      score: _score,
      accuracy: accuracy,
      correctCount: _matchedPairs,
      totalQuestions: totalPairs,
      timeElapsedSeconds: elapsed,
      comboMax: _combo.max,
      xpEarned: xpPreview,
      completedAt: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameResultScreen(result: result, onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MemoryMatchScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName))))));
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    try { _timer.dispose(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('MEMORY MATCH')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(appBar: AppBar(title: const Text('MEMORY MATCH')), body: ErrorState(title: 'Unable to start', message: _error!, onRetry: _load));
    }
    final progress = _cards.isEmpty ? 0.0 : _matchedPairs / (_cards.length / 2);
    return GameScaffold(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.memoryMatch),
      score: _score,
      progress: progress,
      progressLabel: 'MATCHED $_matchedPairs / ${_cards.length ~/ 2}  •  MOVES $_moves',
      timeLabel: _fmt(_timer.remaining),
      combo: _combo,
      paused: _paused,
      soundEnabled: _soundEnabled,
      onPause: () => setState(() { _paused = true; _timer.pause(); }),
      onResume: () => setState(() { _paused = false; _timer.resume(); }),
      onExit: () => context.pop(),
      onSoundToggle: () async {
        final audio = ref.read(audioManagerProvider);
        await audio.setSfxEnabled(!audio.sfxEnabled);
        setState(() => _soundEnabled = audio.sfxEnabled);
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final crossAxisCount = isWide ? 4 : 3;
        // On narrow, adjust card aspect to avoid overflow
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25))),
                child: Row(children: [const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 8), Expanded(child: Text('Match terms with their definitions. Flip two cards at a time.', style: const TextStyle(fontSize: 12, color: AppColors.secondary)))]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, childAspectRatio: isWide ? 1.1 : 0.95, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: _cards.length,
                  itemBuilder: (context, i) {
                    final card = _cards[i];
                    return _MemoryTile(card: card, onTap: () => _onTapCard(card));
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.card, required this.onTap});
  final MemoryCard card;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final revealed = card.isFlipped || card.isMatched;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      label: revealed ? card.label : 'Hidden card',
      button: true,
      enabled: !card.isMatched,
      child: GestureDetector(
        onTap: card.isMatched ? null : onTap,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.easeOut,
          decoration: BoxDecoration(
            color: card.isMatched ? AppColors.success.withValues(alpha: 0.16) : revealed ? AppColors.surfaceElevated : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: card.isMatched ? AppColors.success.withValues(alpha: 0.55) : revealed ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border, width: card.isMatched || revealed ? 1.6 : 1.0),
            boxShadow: revealed ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12)] : null,
          ),
          child: AnimatedSwitcher(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) {
              final rotate = Tween(begin: math.pi * 0.5, end: 0.0).animate(CurvedAnimation(parent: anim, curve: AppMotion.easeOut));
              return AnimatedBuilder(animation: rotate, builder: (context, child) { final tilt = (rotate.value / 3).clamp(-0.3, 0.3); return Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(revealed ? tilt : -tilt), alignment: Alignment.center, child: child); }, child: child);
            },
            child: revealed
                ? Padding(
                    key: ValueKey('front_${card.id}'),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(card.isTerm ? Icons.menu_book_rounded : Icons.article_rounded, size: 18, color: card.isMatched ? AppColors.success : AppColors.secondary),
                        const SizedBox(height: 8),
                        Text(card.label, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: card.isMatched ? AppColors.success : AppColors.textPrimary)),
                        if (card.isMatched) ...[const SizedBox(height: 6), const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success)],
                      ],
                    ),
                  )
                : Container(
                    key: ValueKey('back_${card.id}'),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.brand, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 10)]), child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(card.isTerm ? 'TERM' : 'DEF', style: const TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
