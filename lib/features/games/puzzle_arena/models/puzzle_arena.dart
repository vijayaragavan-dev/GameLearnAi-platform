import '../../../game_engine/models/game_models.dart';

enum PuzzleType {
  arrange('Arrange'),
  match('Match'),
  connect('Connect'),
  sequence('Sequence'),
  logic('Logic'),
  debug('Debug'),
  pattern('Pattern');

  const PuzzleType(this.displayName);
  final String displayName;
}

class PuzzleBlock {
  const PuzzleBlock({required this.id, required this.label, this.detail});
  final String id;
  final String label;
  final String? detail;
}

class MatchPair {
  const MatchPair({required this.leftId, required this.leftLabel, required this.rightId, required this.rightLabel});
  final String leftId;
  final String leftLabel;
  final String rightId;
  final String rightLabel;
}

class ConnectNode {
  const ConnectNode({required this.id, required this.label, this.detail});
  final String id;
  final String label;
  final String? detail;
}

class ConnectLink {
  const ConnectLink({required this.from, required this.to});
  final String from;
  final String to;
  @override
  bool operator ==(Object other) => other is ConnectLink && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(from, to);
}

class PuzzleOption {
  const PuzzleOption({required this.id, required this.label, this.description = ''});
  final String id;
  final String label;
  final String description;
}

/// Core puzzle model — pure Dart, deterministic.
class PuzzleArenaPuzzle {
  const PuzzleArenaPuzzle({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.puzzleType,
    required this.instruction,
    required this.learningObjective,
    required this.concept,
    required this.explanation,
    required this.hint,
    this.blocks,
    this.correctOrder,
    this.matchPairs,
    this.connectNodes,
    this.correctLinks,
    this.sequenceBlocks,
    this.sequenceCorrect,
    this.logicBlocks,
    this.logicCorrect,
    this.codeSnippet,
    this.debugOptions,
    this.correctDebugId,
    this.patternSequence,
    this.patternOptions,
    this.correctPatternId,
    this.reward = 100,
  });

  final String id;
  final String title;
  final String topic;
  final GameDifficulty difficulty;
  final PuzzleType puzzleType;
  final String instruction;
  final String learningObjective;
  final String concept;
  final String explanation;
  final String hint;
  // Type-specific data (nullable, validated per type)
  final List<PuzzleBlock>? blocks; // arrange / sequence / logic
  final List<String>? correctOrder; // arrange / sequence / logic
  final List<MatchPair>? matchPairs; // match
  final List<ConnectNode>? connectNodes; // connect
  final List<ConnectLink>? correctLinks; // connect
  final List<PuzzleBlock>? sequenceBlocks; // alias for arrange but keep separate for clarity (sequence uses blocks)
  final List<String>? sequenceCorrect;
  final List<PuzzleBlock>? logicBlocks;
  final List<String>? logicCorrect;
  final String? codeSnippet; // debug
  final List<PuzzleOption>? debugOptions;
  final String? correctDebugId;
  final List<String>? patternSequence; // pattern (e.g., ["2","4","8","16","?"])
  final List<PuzzleOption>? patternOptions;
  final String? correctPatternId;
  final int reward;

  bool get isValid {
    if (id.isEmpty || title.isEmpty || topic.isEmpty || instruction.isEmpty || learningObjective.isEmpty || concept.isEmpty || explanation.isEmpty || hint.isEmpty) return false;
    if (reward <= 0) return false;
    switch (puzzleType) {
      case PuzzleType.arrange:
        if (blocks == null || correctOrder == null) return false;
        if (blocks!.length < 2 || correctOrder!.length != blocks!.length) return false;
        final ids = blocks!.map((b) => b.id).toSet();
        if (ids.length != blocks!.length) return false;
        for (final c in correctOrder!) if (!ids.contains(c)) return false;
        return true;
      case PuzzleType.sequence:
        final b = sequenceBlocks ?? blocks;
        final c = sequenceCorrect ?? correctOrder;
        if (b == null || c == null) return false;
        if (b.length < 2 || c.length != b.length) return false;
        final ids = b.map((e) => e.id).toSet();
        for (final cid in c) if (!ids.contains(cid)) return false;
        return true;
      case PuzzleType.logic:
        final lb = logicBlocks ?? blocks;
        final lc = logicCorrect ?? correctOrder;
        if (lb == null || lc == null) return false;
        if (lb.length < 2 || lc.length != lb.length) return false;
        final ids = lb.map((e) => e.id).toSet();
        for (final cid in lc) if (!ids.contains(cid)) return false;
        return true;
      case PuzzleType.match:
        if (matchPairs == null || matchPairs!.length < 2) return false;
        final lIds = matchPairs!.map((p) => p.leftId).toSet();
        final rIds = matchPairs!.map((p) => p.rightId).toSet();
        if (lIds.length != matchPairs!.length) return false;
        if (rIds.length != matchPairs!.length) return false;
        return true;
      case PuzzleType.connect:
        if (connectNodes == null || correctLinks == null) return false;
        if (connectNodes!.length < 2 || correctLinks!.isEmpty) return false;
        final nIds = connectNodes!.map((n) => n.id).toSet();
        for (final l in correctLinks!) {
          if (!nIds.contains(l.from) || !nIds.contains(l.to)) return false;
        }
        return true;
      case PuzzleType.debug:
        if (codeSnippet == null || codeSnippet!.isEmpty) return false;
        if (debugOptions == null || debugOptions!.length < 2) return false;
        if (correctDebugId == null) return false;
        if (!debugOptions!.any((o) => o.id == correctDebugId)) return false;
        return true;
      case PuzzleType.pattern:
        if (patternSequence == null || patternSequence!.length < 3) return false;
        if (patternOptions == null || patternOptions!.length < 2) return false;
        if (correctPatternId == null) return false;
        if (!patternOptions!.any((o) => o.id == correctPatternId)) return false;
        return true;
    }
  }

  // Validation helpers for each type
  bool isArrangeCorrect(List<String> orderedIds) {
    if (puzzleType != PuzzleType.arrange) return false;
    if (orderedIds.length != correctOrder!.length) return false;
    for (var i = 0; i < correctOrder!.length; i++) if (orderedIds[i] != correctOrder![i]) return false;
    return true;
  }

  bool isSequenceCorrect(List<String> orderedIds) {
    if (puzzleType != PuzzleType.sequence) return false;
    final c = sequenceCorrect ?? correctOrder!;
    if (orderedIds.length != c.length) return false;
    for (var i = 0; i < c.length; i++) if (orderedIds[i] != c[i]) return false;
    return true;
  }

  bool isLogicCorrect(List<String> orderedIds) {
    if (puzzleType != PuzzleType.logic) return false;
    final c = logicCorrect ?? correctOrder!;
    if (orderedIds.length != c.length) return false;
    for (var i = 0; i < c.length; i++) if (orderedIds[i] != c[i]) return false;
    return true;
  }

  bool isMatchCorrect(Map<String, String> userPairs) {
    if (puzzleType != PuzzleType.match) return false;
    if (userPairs.length != matchPairs!.length) return false;
    for (final p in matchPairs!) {
      if (userPairs[p.leftId] != p.rightId) return false;
    }
    return true;
  }

  bool isConnectCorrect(Set<ConnectLink> userLinks) {
    if (puzzleType != PuzzleType.connect) return false;
    if (userLinks.length != correctLinks!.length) return false;
    final correctSet = correctLinks!.toSet();
    return userLinks.containsAll(correctSet) && correctSet.containsAll(userLinks);
  }

  bool isDebugCorrect(String selectedId) {
    if (puzzleType != PuzzleType.debug) return false;
    return selectedId == correctDebugId;
  }

  bool isPatternCorrect(String selectedId) {
    if (puzzleType != PuzzleType.pattern) return false;
    return selectedId == correctPatternId;
  }

  bool isCorrectDynamic(dynamic answer) {
    switch (puzzleType) {
      case PuzzleType.arrange:
        return answer is List<String> && isArrangeCorrect(answer);
      case PuzzleType.sequence:
        return answer is List<String> && isSequenceCorrect(answer);
      case PuzzleType.logic:
        return answer is List<String> && isLogicCorrect(answer);
      case PuzzleType.match:
        return answer is Map<String, String> && isMatchCorrect(answer);
      case PuzzleType.connect:
        return answer is Set<ConnectLink> && isConnectCorrect(answer);
      case PuzzleType.debug:
        return answer is String && isDebugCorrect(answer);
      case PuzzleType.pattern:
        return answer is String && isPatternCorrect(answer);
    }
  }
}

/// Session state for testing (pure Dart)
class PuzzleArenaState {
  PuzzleArenaState({required this.puzzle});
  final PuzzleArenaPuzzle puzzle;
  List<String> arrangeSelection = [];
  Map<String, String> matchSelection = {};
  Set<ConnectLink> connectSelection = {};
  String? debugSelection;
  String? patternSelection;
  int lives = 3;
  bool solved = false;

  bool submitArrange(List<String> order) {
    final ok = puzzle.isArrangeCorrect(order) || puzzle.isSequenceCorrect(order) || puzzle.isLogicCorrect(order);
    if (ok) solved = true; else lives--;
    return ok;
  }

  bool submitMatch(Map<String, String> pairs) {
    final ok = puzzle.isMatchCorrect(pairs);
    if (ok) solved = true; else lives--;
    return ok;
  }

  bool submitConnect(Set<ConnectLink> links) {
    final ok = puzzle.isConnectCorrect(links);
    if (ok) solved = true; else lives--;
    return ok;
  }

  bool submitDebug(String id) {
    final ok = puzzle.isDebugCorrect(id);
    if (ok) solved = true; else lives--;
    return ok;
  }

  bool submitPattern(String id) {
    final ok = puzzle.isPatternCorrect(id);
    if (ok) solved = true; else lives--;
    return ok;
  }

  void reset() {
    arrangeSelection = [];
    matchSelection = {};
    connectSelection = {};
    debugSelection = null;
    patternSelection = null;
    lives = 3;
    solved = false;
  }
}

abstract final class PuzzleArenaValidator {
  static bool hasNoDuplicateIds(List<PuzzleArenaPuzzle> puzzles) => puzzles.map((p) => p.id).toSet().length == puzzles.length;
  static Set<String> topicsOf(List<PuzzleArenaPuzzle> puzzles) => puzzles.map((p) => p.topic).toSet();
  static Set<PuzzleType> typesOf(List<PuzzleArenaPuzzle> puzzles) => puzzles.map((p) => p.puzzleType).toSet();
  static Set<GameDifficulty> difficultiesOf(List<PuzzleArenaPuzzle> puzzles) => puzzles.map((p) => p.difficulty).toSet();
}
