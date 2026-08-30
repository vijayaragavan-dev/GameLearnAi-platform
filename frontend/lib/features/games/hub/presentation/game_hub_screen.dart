import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../game_engine/models/game_models.dart';

/// Hub listing the four approved games for a topic. Entry point from TopicDetail.
class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key, required this.topicId, this.topicName, this.subjectId});
  final String topicId;
  final String? topicName;
  final String? subjectId;

  void _open(BuildContext context, GameType type) {
    switch (type) {
      case GameType.quizBattle:
        context.push('/games/$topicId/quiz-battle', extra: topicName);
        break;
      case GameType.memoryMatch:
        context.push('/games/$topicId/memory', extra: topicName);
        break;
      case GameType.dragDrop:
        context.push('/games/$topicId/drag-drop', extra: topicName);
        break;
      case GameType.speedRun:
        context.push('/games/$topicId/speed-run', extra: topicName);
        break;
      case GameType.debugArena:
        context.push('/games/$topicId/debug-arena', extra: topicName);
        break;
      case GameType.unlockCode:
        context.push('/games/$topicId/unlock-code', extra: topicName);
        break;
      case GameType.conceptBuilder:
        context.push('/games/$topicId/concept-builder', extra: topicName);
        break;
      case GameType.sequenceMaster:
        context.push('/games/$topicId/sequence-master', extra: topicName);
        break;
      case GameType.targetChallenge:
        context.push('/games/$topicId/target-challenge', extra: topicName);
        break;
      case GameType.mysteryCase:
        context.push('/games/$topicId/mystery-case', extra: topicName);
        break;
      case GameType.bossBattle:
        context.push('/games/$topicId/boss-battle', extra: topicName);
        break;
      case GameType.puzzleArena:
        context.push('/games/$topicId/puzzle-arena', extra: topicName);
        break;
      case GameType.connectivityLab:
        context.push('/games/$topicId/connectivity-lab', extra: topicName);
        break;
      case GameType.snakeAndLadder:
        context.push('/games/$topicId/snake-and-ladder', extra: topicName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = GameDefinition.all;
    return Scaffold(
      appBar: AppBar(title: const Text('GAME ARENA')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.18), AppColors.surfaceElevated]),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.brand), child: const Icon(Icons.sports_esports_rounded, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topicName ?? 'Select your challenge', style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('Learning feels like play. Pick a game — same mastery, more fun.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Polished summary row — real data, not fake progress (responsive Wrap)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surfaceHigh.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.grid_view_rounded, size: 12, color: AppColors.textTertiary), const SizedBox(width: 6), Text('${cards.length} GAMES', style: const TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.textTertiary))]),
                Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textTertiary)), const SizedBox(width: 8), const Icon(Icons.category_outlined, size: 12, color: AppColors.textTertiary), const SizedBox(width: 6), const Text('8 TOPICS', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.textTertiary))]),
                Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textTertiary)), const SizedBox(width: 8), const Icon(Icons.speed_rounded, size: 12, color: AppColors.textTertiary), const SizedBox(width: 6), const Text('VARIABLE DIFFICULTY', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.textTertiary))]),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('CHOOSE YOUR GAME', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
          const SizedBox(height: 4),
          const Text('All games available — no locked content. Pick any to start.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 12),
          for (final d in cards) Padding(padding: const EdgeInsets.only(bottom: 14), child: _GameCard(def: d, onTap: () => _open(context, d.type))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
            child: Row(children: [const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary), const SizedBox(width: 8), const Expanded(child: Text('Quiz Battle & Speed Run award real XP. Other games show local scores (real XP coming next backend update).', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))) ]),
          ),
        ],
      ),
    );
  }
}

String _categoryFor(GameType type) {
  return switch (type) {
    GameType.quizBattle => 'Challenge',
    GameType.memoryMatch => 'Logic',
    GameType.dragDrop => 'Problem Solving',
    GameType.speedRun => 'Challenge',
    GameType.debugArena => 'Programming',
    GameType.unlockCode => 'Programming',
    GameType.conceptBuilder => 'Logic',
    GameType.sequenceMaster => 'Logic',
    GameType.targetChallenge => 'Mathematics',
    GameType.mysteryCase => 'Problem Solving',
    GameType.bossBattle => 'Challenge',
    GameType.puzzleArena => 'Logic',
    GameType.connectivityLab => 'Networking',
    GameType.snakeAndLadder => 'Challenge',
  };
}

IconData _categoryIconFor(GameType type) {
  return switch (type) {
    GameType.quizBattle => Icons.emoji_events_outlined,
    GameType.memoryMatch => Icons.psychology_outlined,
    GameType.dragDrop => Icons.extension_outlined,
    GameType.speedRun => Icons.bolt_outlined,
    GameType.debugArena => Icons.bug_report_outlined,
    GameType.unlockCode => Icons.lock_outline_rounded,
    GameType.conceptBuilder => Icons.view_module_outlined,
    GameType.sequenceMaster => Icons.swap_vert_rounded,
    GameType.targetChallenge => Icons.adjust_rounded,
    GameType.mysteryCase => Icons.search_outlined,
    GameType.bossBattle => Icons.videogame_asset_outlined,
    GameType.puzzleArena => Icons.extension_outlined,
    GameType.connectivityLab => Icons.wifi_rounded,
    GameType.snakeAndLadder => Icons.casino_outlined,
  };
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.def, required this.onTap});
  final GameDefinition def;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = switch (def.type) {
      GameType.quizBattle => AppColors.primary,
      GameType.memoryMatch => AppColors.secondary,
      GameType.dragDrop => AppColors.success,
      GameType.speedRun => AppColors.warning,
      GameType.debugArena => const Color(0xFFEF4444),
      GameType.unlockCode => const Color(0xFFEAB308),
      GameType.conceptBuilder => const Color(0xFF8B5CF6),
      GameType.sequenceMaster => const Color(0xFF06B6D4),
      GameType.targetChallenge => const Color(0xFFF97316),
      GameType.mysteryCase => const Color(0xFF7C3AED),
      GameType.bossBattle => const Color(0xFFEF4444),
      GameType.puzzleArena => const Color(0xFF06B6D4),
      GameType.connectivityLab => const Color(0xFF10B981),
      GameType.snakeAndLadder => const Color(0xFFF59E0B),
    };
    final category = _categoryFor(def.type);
    final categoryIcon = _categoryIconFor(def.type);
    return Semantics(
      button: true,
      label: '${def.displayName}, category $category, ${def.description}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(width: 54, height: 54, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [color.withValues(alpha: 0.9), color])), child: Center(child: Text(def.icon, style: const TextStyle(fontSize: 24)))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(def.displayName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.success.withValues(alpha: 0.35))),
                          child: const Text('AVAILABLE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.success)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(def.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(icon: categoryIcon, label: category),
                        _Chip(icon: Icons.speed_outlined, label: 'MEDIUM'),
                        if (def.supportsTimer) _Chip(icon: Icons.timer_outlined, label: 'Timed'),
                        if (def.supportsCombo) _Chip(icon: Icons.local_fire_department_outlined, label: 'Combo'),
                        _Chip(icon: Icons.star_outline_rounded, label: 'XP'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 11, color: AppColors.textTertiary), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary))]),
      );
}
