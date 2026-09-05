import 'package:flutter/material.dart';

import '../../features/game_engine/models/game_models.dart';
import 'app_colors.dart';
import 'app_icons.dart';
import 'app_styles.dart';

/// Visual identity for a single game.
///
/// This is a PRESENTATION-ONLY mapping layer. It does not define or modify
/// game mechanics, rules, or gameplay data. All game behavior lives in
/// [GameDefinition] and the individual game screens.
///
/// Used by: game cards, game hub, game result headers, path nodes.
class GameVisualIdentity {
  const GameVisualIdentity({
    required this.type,
    required this.accent,
    required this.gradient,
    required this.icon,
    required this.category,
    required this.motif,
  });

  /// The game this identity belongs to.
  final GameType type;

  /// Primary accent color — used for borders, glow, and highlights.
  final Color accent;

  /// Two-color gradient — background wash for game cards.
  final LinearGradient gradient;

  /// Icon representation — consistent rounded style.
  final IconData icon;

  /// Game category — used for filtering and grouping.
  final String category;

  /// Visual motif descriptor — for artwork slots and decorative theming.
  final String motif;

  /// Get glow shadow for this game identity.
  List<BoxShadow> glowShadow({bool dark = true}) => [
    BoxShadow(
      color: accent.withValues(alpha: dark ? 0.35 : 0.14),
      blurRadius: 22,
      spreadRadius: 0,
    ),
  ];

  /// Get surface background color (subtle tint for cards).
  Color surfaceTint({bool dark = true}) =>
      accent.withValues(alpha: dark ? 0.08 : 0.04);

  /// Get border color for this game's cards.
  Color borderColor({bool dark = true}) =>
      accent.withValues(alpha: dark ? 0.35 : 0.22);
}

/// Centralized game visual identity registry.
///
/// Access via [GameVisualRegistry.of] — always returns a valid identity,
/// falling back to [GameVisualRegistry.fallback] for unmapped types.
abstract final class GameVisualRegistry {
  static const GameVisualIdentity _quizBattle = GameVisualIdentity(
    type: GameType.quizBattle,
    accent: AppColors.primary,
    gradient: AppGradients.gameQuiz,
    icon: Icons.quiz_rounded,
    category: 'battle',
    motif: 'combat_arena',
  );

  static const GameVisualIdentity _memoryMatch = GameVisualIdentity(
    type: GameType.memoryMatch,
    accent: AppColors.secondary,
    gradient: AppGradients.gameMemory,
    icon: Icons.grid_view_rounded,
    category: 'memory',
    motif: 'neural_grid',
  );

  static const GameVisualIdentity _dragDrop = GameVisualIdentity(
    type: GameType.dragDrop,
    accent: Color(0xFF818CF8), // indigo
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF312E81), Color(0xFF818CF8)],
    ),
    icon: Icons.drag_indicator_rounded,
    category: 'puzzle',
    motif: 'assembly_grid',
  );

  static const GameVisualIdentity _speedRun = GameVisualIdentity(
    type: GameType.speedRun,
    accent: AppColors.streak,
    gradient: AppGradients.gameSpeed,
    icon: Icons.timer_rounded,
    category: 'speed',
    motif: 'time_warp',
  );

  static const GameVisualIdentity _debugArena = GameVisualIdentity(
    type: GameType.debugArena,
    accent: AppColors.success,
    gradient: AppGradients.gameDebug,
    icon: Icons.bug_report_rounded,
    category: 'logic',
    motif: 'code_matrix',
  );

  static const GameVisualIdentity _unlockCode = GameVisualIdentity(
    type: GameType.unlockCode,
    accent: AppColors.xp,
    gradient: AppGradients.gameMystery,
    icon: Icons.lock_open_rounded,
    category: 'puzzle',
    motif: 'vault_door',
  );

  static const GameVisualIdentity _conceptBuilder = GameVisualIdentity(
    type: GameType.conceptBuilder,
    accent: Color(0xFF7C3AED), // violet
    gradient: AppGradients.gamePuzzle,
    icon: Icons.account_tree_rounded,
    category: 'logic',
    motif: 'blueprint',
  );

  static const GameVisualIdentity _sequenceMaster = GameVisualIdentity(
    type: GameType.sequenceMaster,
    accent: Color(0xFF06B6D4), // teal-400
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF164E63), Color(0xFF06B6D4)],
    ),
    icon: Icons.format_list_numbered_rounded,
    category: 'logic',
    motif: 'sequence_chain',
  );

  static const GameVisualIdentity _targetChallenge = GameVisualIdentity(
    type: GameType.targetChallenge,
    accent: AppColors.error,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7F1D1D), Color(0xFFF87171)],
    ),
    icon: Icons.gps_fixed_rounded,
    category: 'arcade',
    motif: 'crosshair',
  );

  static const GameVisualIdentity _mysteryCase = GameVisualIdentity(
    type: GameType.mysteryCase,
    accent: Color(0xFFA78BFA), // purple-400
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2E1065), Color(0xFFA78BFA)],
    ),
    icon: Icons.search_rounded,
    category: 'mystery',
    motif: 'detective_files',
  );

  static const GameVisualIdentity _bossBattle = GameVisualIdentity(
    type: GameType.bossBattle,
    accent: AppColors.error,
    gradient: AppGradients.gameBoss,
    icon: Icons.shield_rounded,
    category: 'battle',
    motif: 'boss_arena',
  );

  static const GameVisualIdentity _puzzleArena = GameVisualIdentity(
    type: GameType.puzzleArena,
    accent: Color(0xFF7C3AED),
    gradient: AppGradients.gamePuzzle,
    icon: Icons.extension_rounded,
    category: 'puzzle',
    motif: 'jigsaw',
  );

  static const GameVisualIdentity _connectivityLab = GameVisualIdentity(
    type: GameType.connectivityLab,
    accent: Color(0xFF14B8A6), // teal
    gradient: AppGradients.gameNetwork,
    icon: Icons.hub_rounded,
    category: 'network',
    motif: 'network_graph',
  );

  static const GameVisualIdentity _snakeAndLadder = GameVisualIdentity(
    type: GameType.snakeAndLadder,
    accent: Color(0xFFF59E0B), // amber
    gradient: AppGradients.gameBoard,
    icon: Icons.casino_rounded,
    category: 'board',
    motif: 'game_board',
  );

  /// Fallback identity — used when type is not mapped (should not happen
  /// with the 14 defined games, but safe for future additions).
  static const GameVisualIdentity fallback = GameVisualIdentity(
    type: GameType.quizBattle,
    accent: AppColors.primary,
    gradient: AppGradients.brand,
    icon: Icons.sports_esports_rounded,
    category: 'arcade',
    motif: 'generic_game',
  );

  static const List<GameVisualIdentity> _all = [
    _quizBattle,
    _memoryMatch,
    _dragDrop,
    _speedRun,
    _debugArena,
    _unlockCode,
    _conceptBuilder,
    _sequenceMaster,
    _targetChallenge,
    _mysteryCase,
    _bossBattle,
    _puzzleArena,
    _connectivityLab,
    _snakeAndLadder,
  ];

  /// Get visual identity for a [GameType].
  /// Always returns a valid identity — never throws.
  static GameVisualIdentity of(GameType type) {
    try {
      return _all.firstWhere((identity) => identity.type == type);
    } catch (_) {
      return fallback;
    }
  }

  /// Get visual identity from a game ID string.
  static GameVisualIdentity fromId(String id) {
    try {
      final type = GameType.values.firstWhere((t) => t.id == id);
      return of(type);
    } catch (_) {
      return fallback;
    }
  }

  /// All registered game identities.
  static List<GameVisualIdentity> get all => _all;

  /// Get all identities for a category.
  static List<GameVisualIdentity> byCategory(String category) =>
      _all.where((i) => i.category == category).toList();

  /// Available game categories.
  static const List<String> categories = [
    'battle',
    'memory',
    'speed',
    'puzzle',
    'logic',
    'mystery',
    'arcade',
    'network',
    'board',
  ];
}

/// Convenience widget: applies the correct accent border + tint for a game type.
class GameIdentityAccent extends StatelessWidget {
  const GameIdentityAccent({
    super.key,
    required this.gameType,
    required this.child,
    this.borderWidth = 1.0,
    this.showGlow = false,
    this.radius = 20,
  });

  final GameType gameType;
  final Widget child;
  final double borderWidth;
  final bool showGlow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final identity = GameVisualRegistry.of(gameType);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showGlow ? identity.glowShadow(dark: isDark) : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.cardHighlight(identity.accent),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: identity.borderColor(dark: isDark),
            width: borderWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}
