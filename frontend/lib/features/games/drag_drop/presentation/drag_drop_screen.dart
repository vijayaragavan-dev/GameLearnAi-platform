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

/// Drag & Drop Challenge: draggable items → target zones.
class DragDropScreen extends ConsumerStatefulWidget {
  const DragDropScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<DragDropScreen> createState() => _DragDropScreenState();
}

class _DragDropScreenState extends ConsumerState<DragDropScreen> {
  GameDifficulty _difficulty = GameDifficulty.medium;
  late GameCombo _combo;
  late GameTimer _timer;
  List<String> _zones = [];
  List<DragItem> _items = [];
  final Map<String, String?> _placements = {}; // itemId -> zone
  final Map<String, bool?> _feedback = {}; // itemId -> correct?
  int _score = 0;
  bool _loading = true;
  String? _error;
  DateTime? _start;
  bool _paused = false;
  bool _soundEnabled = true;
  int _timeLimit = 120;

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
      final contentRepo = ref.read(contentRepoProvider);
      final quizRepo = ref.read(quizRepoProvider);
      Future<dynamic> safeLesson() async { try { return await contentRepo.lesson(widget.topicId); } catch (_) { return null; } }
      Future<dynamic> safeQuiz() async { try { return await quizRepo.quizForTopic(widget.topicId); } catch (_) { return null; } }
      Future<dynamic> safeTopic() async { try { return await contentRepo.topic(widget.topicId); } catch (_) { return null; } }
      final results = await Future.wait([safeLesson(), safeQuiz(), safeTopic()]);
      final lessonRaw = results[0] as dynamic;
      final quizRaw = results[1] as dynamic;
      final topicRaw = results[2] as dynamic;
      final Lesson? lesson = lessonRaw is Lesson ? lessonRaw : null;
      final Quiz? quiz = quizRaw is Quiz ? quizRaw : null;
      final Topic? topic = topicRaw is Topic ? topicRaw : null;
      _difficulty = DifficultyUtils.resolve(topicDifficulty: topic?.difficulty);
      final payload = GameContentMapper.dragDropPayload(quiz: quiz, lesson: lesson, topic: topic);
      _zones = payload.zones;
      _items = payload.items;
      // Shuffle items
      _items.shuffle();
      for (final it in _items) {
        _placements[it.id] = null;
      }
      _timer = GameTimer(totalSeconds: _timeLimit);
      _timer.onTickValue = (_) => setState(() {});
      _timer.onComplete = _onTimeUp;
      _timer.start();
      _start = DateTime.now();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = describeError(e).message; _loading = false; });
    }
  }

  void _onTimeUp() => _finish();

  Future<void> _onDrop(DragItem item, String zone) async {
    if (_paused) return;
    final sound = ref.read(gameSoundControllerProvider);
    final prevZone = _placements[item.id];
    // If re-placing same zone, no-op
    if (prevZone == zone) return;
    setState(() => _placements[item.id] = zone);
    final correct = item.correctZone.toUpperCase() == zone.toUpperCase();
    setState(() => _feedback[item.id] = correct);
    if (correct) {
      _combo.registerHit();
      _score += GameScoring.scoreForHit(difficulty: _difficulty, combo: _combo.current, responseTimeSeconds: 3);
      await sound.correct();
      ref.read(hapticsProvider).success();
      if (_combo.isHot) await sound.combo();
    } else {
      _combo.registerMiss();
      await sound.incorrect();
      ref.read(hapticsProvider).error();
    }
    setState(() {});
    if (_checkCompletion()) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _finish();
    }
  }

  bool _checkCompletion() {
    for (final it in _items) {
      if (_placements[it.id] == null) return false;
    }
    return true;
  }

  int get _correctCount {
    var c = 0;
    for (final it in _items) {
      final zone = _placements[it.id];
      if (zone != null && zone.toUpperCase() == it.correctZone.toUpperCase()) c++;
    }
    return c;
  }

  void _finish() {
    _timer.stop();
    final elapsed = _start == null ? 0 : DateTime.now().difference(_start!).inSeconds;
    final accuracy = _items.isEmpty ? 0.0 : _correctCount / _items.length * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.dragDrop, timeLimitSeconds: _timeLimit),
      score: _score,
      accuracy: accuracy,
      correctCount: _correctCount,
      totalQuestions: _items.length,
      timeElapsedSeconds: elapsed,
      comboMax: _combo.max,
      xpEarned: xpPreview,
      completedAt: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameResultScreen(result: result, onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DragDropScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName))))));
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
      return Scaffold(appBar: AppBar(title: const Text('DRAG & DROP')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(appBar: AppBar(title: const Text('DRAG & DROP')), body: ErrorState(title: 'Unable to start', message: _error!, onRetry: _load));
    }
    final progress = _items.isEmpty ? 0.0 : _placements.values.where((v) => v != null).length / _items.length;
    final isWide = MediaQuery.sizeOf(context).width > 700;
    return GameScaffold(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.dragDrop),
      score: _score,
      progress: progress,
      progressLabel: 'PLACED ${_placements.values.where((v) => v != null).length} / ${_items.length}  •  CORRECT $_correctCount',
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
      child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DRAG ITEMS', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      final placed = _placements[item.id];
                      final fb = _feedback[item.id];
                      return _DraggableCard(item: item, isPlaced: placed != null, feedback: fb);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DROP ZONES', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: _zones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final zone = _zones[i];
                      final itemsInZone = _items.where((it) => _placements[it.id] == zone).toList();
                      return _DropZone(zone: zone, items: itemsInZone, onAccept: (item) => _onDrop(item, zone));
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checkCompletion() ? _finish : null,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('COMPLETE CHALLENGE'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Zones first (targets)
          const Align(alignment: Alignment.centerLeft, child: Text('DROP ZONES', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary))),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _zones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final zone = _zones[i];
                final itemsInZone = _items.where((it) => _placements[it.id] == zone).toList();
                return SizedBox(width: 180, child: _DropZone(zone: zone, items: itemsInZone, onAccept: (item) => _onDrop(item, zone)));
              },
            ),
          ),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: Text('DRAG ITEMS', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: AppColors.textTertiary))),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = _items[i];
                final placed = _placements[item.id];
                final fb = _feedback[item.id];
                return _DraggableCard(item: item, isPlaced: placed != null, feedback: fb);
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(onPressed: _checkCompletion() ? _finish : null, icon: const Icon(Icons.check_rounded), label: const Text('COMPLETE CHALLENGE')),
          ),
        ],
      ),
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({required this.item, required this.isPlaced, required this.feedback});
  final DragItem item;
  final bool isPlaced;
  final bool? feedback;
  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: feedback == true ? AppColors.success.withValues(alpha: 0.14) : feedback == false ? AppColors.error.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: feedback == true ? AppColors.success : feedback == false ? AppColors.error : isPlaced ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border, width: 1.4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.15), border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))), child: const Icon(Icons.drag_indicator_rounded, size: 14, color: AppColors.primaryBright)),
          const SizedBox(width: 10),
          Expanded(child: Text(item.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          if (feedback != null) Icon(feedback! ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18, color: feedback! ? AppColors.success : AppColors.error),
        ],
      ),
    );
    return Draggable<DragItem>(
      data: item,
      feedback: Material(color: Colors.transparent, child: Opacity(opacity: 0.85, child: SizedBox(width: 260, child: child))),
      childWhenDragging: Opacity(opacity: 0.4, child: child),
      child: child,
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.zone, required this.items, required this.onAccept});
  final String zone;
  final List<DragItem> items;
  final ValueChanged<DragItem> onAccept;
  @override
  Widget build(BuildContext context) {
    return DragTarget<DragItem>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final isHovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: isHovering ? AppColors.primary : AppColors.border, width: isHovering ? 1.6 : 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.flag_rounded, size: 14, color: isHovering ? AppColors.primary : AppColors.textTertiary), const SizedBox(width: 6), Text(zone.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: isHovering ? AppColors.primary : AppColors.textTertiary))]),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border, style: BorderStyle.solid), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Text('Drop here', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isHovering ? AppColors.primary : AppColors.textTertiary)),
                )
              else
                for (final it in items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                    child: Text(it.label, style: const TextStyle(fontSize: 12)),
                  ),
            ],
          ),
        );
      },
    );
  }
}
