/// Reusable game system domain models.
/// Pure Dart, no Flutter dependency except for semantics centralization.
library;

/// Game type identifier for the approved games (now 14 with Snake & Ladder).
enum GameType {
  quizBattle('quiz_battle', 'Quiz Battle'),
  memoryMatch('memory_match', 'Memory Match'),
  dragDrop('drag_drop', 'Drag & Drop'),
  speedRun('speed_run', 'Speed Run'),
  debugArena('debug_arena', 'Debug Arena'),
  unlockCode('unlock_code', 'Unlock the Code'),
  conceptBuilder('concept_builder', 'Concept Builder'),
  sequenceMaster('sequence_master', 'Sequence Master'),
  targetChallenge('target_challenge', 'Target Challenge'),
  mysteryCase('mystery_case', 'Mystery Case'),
  bossBattle('boss_battle', 'Boss Battle'),
  puzzleArena('puzzle_arena', 'Puzzle Arena'),
  connectivityLab('connectivity_lab', 'Connectivity Lab'),
  snakeAndLadder('snake_and_ladder', 'Snake & Ladder');

  const GameType(this.id, this.displayName);
  final String id;
  final String displayName;
}

/// Difficulty concept (Easy/Medium/Hard) mapped to presentation.
enum GameDifficulty {
  easy('EASY', 'Easy'),
  medium('MEDIUM', 'Medium'),
  hard('HARD', 'Hard');

  const GameDifficulty(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;

  static GameDifficulty fromString(String v) {
    final u = v.toUpperCase();
    if (u == 'MEDIUM') return GameDifficulty.medium;
    if (u == 'HARD') return GameDifficulty.hard;
    return GameDifficulty.easy;
  }
}

/// Lifecycle state of a game session.
enum GameStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
  failed,
}

/// Configuration for a game session - ties game to learning context.
class GameConfig {
  const GameConfig({
    required this.topicId,
    this.topicName,
    this.subjectId,
    this.subjectName,
    required this.type,
    required this.difficulty,
    this.timeLimitSeconds,
  });

  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  final GameType type;
  final GameDifficulty difficulty;
  final int? timeLimitSeconds;
}

/// Result of a completed game session (polished result screen source).
class GameResult {
  const GameResult({
    required this.config,
    required this.score,
    required this.accuracy,
    required this.correctCount,
    required this.totalQuestions,
    required this.timeElapsedSeconds,
    required this.comboMax,
    required this.xpEarned,
    required this.completedAt,
    this.bestScore,
  });

  final GameConfig config;
  final int score;
  final double accuracy; // 0..100
  final int correctCount;
  final int totalQuestions;
  final int timeElapsedSeconds;
  final int comboMax;
  final int xpEarned; // local or server-derived
  final DateTime completedAt;
  final int? bestScore; // personal best if available

  bool get isPerfect => totalQuestions > 0 && correctCount == totalQuestions;
  bool get isSuccess => accuracy >= 50;

  String get performanceLabel {
    if (accuracy >= 90) return 'LEGENDARY';
    if (accuracy >= 75) return 'EXCELLENT';
    if (accuracy >= 50) return 'GOOD';
    if (accuracy >= 30) return 'FAIR';
    return 'KEEP TRYING';
  }
}

/// Definition tying a game type to its capabilities.
class GameDefinition {
  const GameDefinition({
    required this.type,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.supportsTimer,
    required this.supportsCombo,
    required this.supportsPause,
  });

  final GameType type;
  final String displayName;
  final String description;
  final String icon; // emoji or iconKey
  final bool supportsTimer;
  final bool supportsCombo;
  final bool supportsPause;

  static const List<GameDefinition> all = [
    GameDefinition(
      type: GameType.quizBattle,
      displayName: 'Quiz Battle',
      description: 'Answer fast, build combos, and dominate the challenge.',
      icon: '⚔️',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: false,
    ),
    GameDefinition(
      type: GameType.memoryMatch,
      displayName: 'Memory Match',
      description: 'Flip cards and match concepts with their definitions.',
      icon: '🧠',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.dragDrop,
      displayName: 'Drag & Drop',
      description: 'Drag concepts to their correct zones.',
      icon: '🧩',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.speedRun,
      displayName: 'Speed Run',
      description: 'Race against the clock in a rapid-fire sprint.',
      icon: '⚡',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: false,
    ),
    GameDefinition(
      type: GameType.debugArena,
      displayName: 'Debug Arena',
      description: 'Hunt bugs, diagnose causes, and ship the fix.',
      icon: '🐞',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.unlockCode,
      displayName: 'Unlock the Code',
      description: 'Solve challenges to reveal the vault code.',
      icon: '🔐',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.conceptBuilder,
      displayName: 'Concept Builder',
      description: 'Assemble building blocks into the correct concept.',
      icon: '🧱',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.sequenceMaster,
      displayName: 'Sequence Master',
      description: 'Master the order — arrange and complete sequences.',
      icon: '🔀',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.targetChallenge,
      displayName: 'Target Challenge',
      description: 'Manipulate the state to hit the exact target.',
      icon: '🎯',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.mysteryCase,
      displayName: 'Mystery Case',
      description: 'Investigate clues, connect evidence, and solve the case.',
      icon: '🕵️',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.bossBattle,
      displayName: 'Boss Battle',
      description: 'Fight the boss — analyze, strike, and defeat with knowledge!',
      icon: '👾',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.puzzleArena,
      displayName: 'Puzzle Arena',
      description: 'Think, arrange, connect, and solve.',
      icon: '🧩',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.connectivityLab,
      displayName: 'Connectivity Lab',
      description: 'Build, route, diagnose, and restore the network.',
      icon: '🔌',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
    GameDefinition(
      type: GameType.snakeAndLadder,
      displayName: 'Snake & Ladder',
      description: 'Climb through challenges. Avoid mistakes. Reach mastery.',
      icon: '🐍',
      supportsTimer: true,
      supportsCombo: true,
      supportsPause: true,
    ),
  ];

  static GameDefinition of(GameType type) =>
      all.firstWhere((d) => d.type == type);
}
