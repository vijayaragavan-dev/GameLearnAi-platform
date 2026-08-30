import 'dart:math';
import '../../../game_engine/models/game_models.dart';

enum ChallengeType { quickConcept, debug, arrange, match, sequence, logic, scenario }

enum CellType { normal, challenge, snake, ladder, bonus, checkpoint, finish, start }

class ChallengeBlock {
  const ChallengeBlock({required this.id, required this.label});
  final String id;
  final String label;
}

class ChallengeOption {
  const ChallengeOption({required this.id, required this.label, this.description = ''});
  final String id;
  final String label;
  final String description;
}

class MatchPair {
  const MatchPair({required this.leftId, required this.leftLabel, required this.rightId, required this.rightLabel});
  final String leftId;
  final String leftLabel;
  final String rightId;
  final String rightLabel;
}

/// Educational challenge for Snake & Ladder cell
class SnakeChallenge {
  const SnakeChallenge({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.challengeType,
    required this.instruction,
    required this.learningObjective,
    required this.concept,
    required this.explanation,
    required this.hint,
    this.blocks,
    this.correctOrder,
    this.matchPairs,
    this.codeSnippet,
    this.debugOptions,
    this.correctDebugId,
    this.sequenceBlocks,
    this.sequenceCorrect,
    this.options,
    this.correctOptionId,
    this.scenarioOptions,
    this.correctScenarioId,
  });

  final String id;
  final String title;
  final String topic;
  final GameDifficulty difficulty;
  final ChallengeType challengeType;
  final String instruction;
  final String learningObjective;
  final String concept;
  final String explanation;
  final String hint;
  // Type-specific
  final List<ChallengeBlock>? blocks; // arrange/sequence/logic
  final List<String>? correctOrder;
  final List<MatchPair>? matchPairs;
  final String? codeSnippet;
  final List<ChallengeOption>? debugOptions;
  final String? correctDebugId;
  final List<ChallengeBlock>? sequenceBlocks;
  final List<String>? sequenceCorrect;
  final List<ChallengeOption>? options; // quickConcept / logic / scenario generic
  final String? correctOptionId;
  final List<ChallengeOption>? scenarioOptions;
  final String? correctScenarioId;

  bool get isValid {
    if (id.isEmpty || title.isEmpty || topic.isEmpty || instruction.isEmpty || learningObjective.isEmpty || concept.isEmpty || explanation.isEmpty || hint.isEmpty) return false;
    switch (challengeType) {
      case ChallengeType.arrange:
      case ChallengeType.sequence:
      case ChallengeType.logic:
        final b = blocks ?? sequenceBlocks;
        final c = correctOrder ?? sequenceCorrect;
        if (b == null || c == null) return false;
        if (b.length < 2 || c.length != b.length) return false;
        final ids = b.map((e) => e.id).toSet();
        for (final cid in c) if (!ids.contains(cid)) return false;
        return true;
      case ChallengeType.match:
        if (matchPairs == null || matchPairs!.length < 2) return false;
        return true;
      case ChallengeType.debug:
        if (codeSnippet == null || debugOptions == null || correctDebugId == null) return false;
        if (!debugOptions!.any((o) => o.id == correctDebugId)) return false;
        return true;
      case ChallengeType.quickConcept:
      case ChallengeType.scenario:
        final opts = options ?? scenarioOptions;
        final cid = correctOptionId ?? correctScenarioId;
        if (opts == null || cid == null) return false;
        if (!opts.any((o) => o.id == cid)) return false;
        return true;
    }
  }

  bool isCorrectDynamic(dynamic answer) {
    switch (challengeType) {
      case ChallengeType.arrange:
      case ChallengeType.sequence:
      case ChallengeType.logic:
        if (answer is! List<String>) return false;
        final c = correctOrder ?? sequenceCorrect!;
        if (answer.length != c.length) return false;
        for (var i = 0; i < c.length; i++) if (answer[i] != c[i]) return false;
        return true;
      case ChallengeType.match:
        if (answer is! Map<String, String>) return false;
        if (answer.length != matchPairs!.length) return false;
        for (final p in matchPairs!) if (answer[p.leftId] != p.rightId) return false;
        return true;
      case ChallengeType.debug:
        return answer is String && answer == correctDebugId;
      case ChallengeType.quickConcept:
      case ChallengeType.scenario:
        final cid = correctOptionId ?? correctScenarioId;
        return answer is String && answer == cid;
    }
  }
}

class BoardCell {
  const BoardCell({required this.number, required this.type, this.snakeTo, this.ladderTo, this.challengeId});
  final int number; // 1..100, 0 is START
  final CellType type;
  final int? snakeTo;
  final int? ladderTo;
  final String? challengeId;
}

class SnakeAndLadderBoard {
  const SnakeAndLadderBoard({required this.size, required this.cells, required this.snakes, required this.ladders, required this.challengeCells});
  final int size; // e.g., 100
  final List<BoardCell> cells;
  final Map<int, int> snakes; // head -> tail
  final Map<int, int> ladders; // foot -> top
  final Map<int, String> challengeCells; // cell -> challengeId

  static SnakeAndLadderBoard create({int size = 100}) {
    // Define snakes and ladders deterministic
    final snakes = <int, int>{
      17: 6,
      32: 12,
      48: 28,
      63: 41,
      88: 52,
      96: 74,
    };
    final ladders = <int, int>{
      8: 26,
      21: 42,
      36: 58,
      54: 73,
      67: 86,
      80: 98,
    };
    final challengeCells = <int, String>{
      5: 'sl_01',
      9: 'sl_02',
      14: 'sl_03',
      19: 'sl_04',
      26: 'sl_05',
      33: 'sl_06',
      38: 'sl_07',
      44: 'sl_08',
      51: 'sl_09',
      59: 'sl_10',
      65: 'sl_11',
      71: 'sl_12',
      78: 'sl_13',
      84: 'sl_14',
      90: 'sl_15',
      95: 'sl_16',
      // additional challenges for remaining cells up to 30, but board only needs mapping for those cells that are challenge type
      11: 'sl_17',
      22: 'sl_18',
      29: 'sl_19',
      37: 'sl_20',
      46: 'sl_21',
      55: 'sl_22',
      62: 'sl_23',
      74: 'sl_24',
      82: 'sl_25',
      88: 'sl_26', // overlaps snake head but challenge also? We'll make snake takes precedence? For simplicity, challenge cells are distinct from snake/ladder heads; we have 88 as snake, so avoid challenge on 88 - but we already have 88 as snake, so we should not have challenge on 88. We'll keep challenge on 88 but snake will be prioritized? Better avoid overlap - remove 88.
      91: 'sl_27',
      97: 'sl_28',
      99: 'sl_29',
      100: 'sl_30', // finish could be challenge? We'll make finish not challenge
    };
    // Remove overlaps where cell is snake head or ladder foot: ensure challenge cells don't overlap those for clarity
    final cleanChallenge = <int, String>{};
    for (final e in challengeCells.entries) {
      if (snakes.containsKey(e.key) || ladders.containsKey(e.key)) continue;
      if (e.key == 100) continue; // finish not challenge
      cleanChallenge[e.key] = e.value;
    }
    final cells = <BoardCell>[];
    // Start cell 0
    cells.add(const BoardCell(number: 0, type: CellType.start));
    for (int i = 1; i <= size; i++) {
      CellType t = CellType.normal;
      if (i == size) t = CellType.finish;
      else if (snakes.containsKey(i)) t = CellType.snake;
      else if (ladders.containsKey(i)) t = CellType.ladder;
      else if (cleanChallenge.containsKey(i)) t = CellType.challenge;
      else if (i % 25 == 0) t = CellType.bonus;
      else if (i % 33 == 0) t = CellType.checkpoint;
      cells.add(BoardCell(number: i, type: t, snakeTo: snakes[i], ladderTo: ladders[i], challengeId: cleanChallenge[i]));
    }
    return SnakeAndLadderBoard(size: size, cells: cells, snakes: snakes, ladders: ladders, challengeCells: cleanChallenge);
  }

  BoardCell cellAt(int number) => cells.firstWhere((c) => c.number == number);
  bool isSnakeHead(int n) => snakes.containsKey(n);
  bool isLadderFoot(int n) => ladders.containsKey(n);
  bool isChallengeCell(int n) => challengeCells.containsKey(n);
  bool isFinish(int n) => n == size;
  bool isValidCell(int n) => n >= 0 && n <= size;
}

/// Deterministic dice provider for testing
abstract class DiceRollProvider {
  int roll();
}

class RandomDiceProvider implements DiceRollProvider {
  final Random _rng;
  RandomDiceProvider([int? seed]) : _rng = seed != null ? Random(seed) : Random();
  @override
  int roll() => _rng.nextInt(6) + 1;
}

class FixedDiceProvider implements DiceRollProvider {
  FixedDiceProvider(this.rolls);
  final List<int> rolls;
  int _idx = 0;
  @override
  int roll() {
    if (_idx >= rolls.length) return rolls.last;
    return rolls[_idx++];
  }
}

/// Session state for board progression
class SnakeAndLadderState {
  SnakeAndLadderState({required this.board, DiceRollProvider? diceProvider}) : diceProvider = diceProvider ?? RandomDiceProvider();
  final SnakeAndLadderBoard board;
  final DiceRollProvider diceProvider;
  int currentPosition = 0; // 0 = START
  int totalScore = 0;
  int maxCombo = 0;
  int currentCombo = 0;
  int lives = 3;
  int resets = 0;
  int successfulChallenges = 0;
  int failedChallenges = 0;
  bool isGameOver = false;
  bool isFinished = false;
  bool isRolling = false;
  int? lastRoll;
  String? currentChallengeId;
  bool challengeActive = false;

  int rollDice() {
    if (isGameOver || isFinished || challengeActive || isRolling) throw StateError('Cannot roll now');
    final r = diceProvider.roll();
    if (r < 1 || r > 6) throw StateError('Roll out of range');
    lastRoll = r;
    isRolling = true;
    return r;
  }

  // Call after roll to move token
  int move(int steps) {
    if (!isRolling) throw StateError('No roll pending');
    final target = currentPosition + steps;
    int newPos;
    if (target > board.size) {
      // Need exact finish
      newPos = currentPosition; // stay
    } else {
      newPos = target;
    }
    currentPosition = newPos;
    isRolling = false;
    // Check snakes/ladders/challenge
    if (board.isFinish(newPos)) {
      isFinished = true;
    } else if (board.isSnakeHead(newPos)) {
      // Will be handled by caller to animate snake, but we move immediately
      // For state, we move to tail
      currentPosition = board.snakes[newPos]!;
    } else if (board.isLadderFoot(newPos)) {
      currentPosition = board.ladders[newPos]!;
    } else if (board.isChallengeCell(newPos)) {
      currentChallengeId = board.challengeCells[newPos];
      challengeActive = true;
    }
    return currentPosition;
  }

  // Called when challenge succeeded
  void completeChallenge(bool success) {
    if (!challengeActive) return;
    if (success) {
      successfulChallenges++;
      currentCombo++;
      if (currentCombo > maxCombo) maxCombo = currentCombo;
    } else {
      failedChallenges++;
      currentCombo = 0;
      // Reset to start
      currentPosition = 0;
      resets++;
      currentChallengeId = null;
      challengeActive = false;
      // lives handling is outside but we decrement lives? For this game primary consequence is reset, but we also keep lives
      lives--;
      if (lives <= 0) isGameOver = true;
      return;
    }
    // On success, clear challenge
    currentChallengeId = null;
    challengeActive = false;
  }

  void resetRun() {
    currentPosition = 0;
    currentChallengeId = null;
    challengeActive = false;
    isRolling = false;
    lastRoll = null;
    currentCombo = 0;
    resets++;
  }

  void resetSession() {
    currentPosition = 0;
    totalScore = 0;
    maxCombo = 0;
    currentCombo = 0;
    lives = 3;
    resets = 0;
    successfulChallenges = 0;
    failedChallenges = 0;
    isGameOver = false;
    isFinished = false;
    isRolling = false;
    lastRoll = null;
    currentChallengeId = null;
    challengeActive = false;
  }
}

abstract final class SnakeValidator {
  static bool hasNoDuplicateIds(List<SnakeChallenge> challenges) => challenges.map((c) => c.id).toSet().length == challenges.length;
}
