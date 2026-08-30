import '../../../game_engine/models/game_models.dart';

/// Phase interaction type — ensures anti-quiz variety.
enum BossPhaseType {
  select, // choose correct strategy/diagnosis
  arrange, // reorder blocks to correct order
  toggle, // flip bits / configure state
  repair, // identify and fix code/logic (select variant with code context)
}

class BossBlock {
  const BossBlock({required this.id, required this.label, this.detail});
  final String id;
  final String label;
  final String? detail;
}

class BossOption {
  const BossOption({required this.id, required this.label, required this.description});
  final String id;
  final String label;
  final String description;
}

/// Single phase of a boss fight. Pure data, deterministic validation.
class BossPhase {
  const BossPhase({
    required this.id,
    required this.title,
    required this.instruction,
    required this.type,
    this.options,
    this.correctOptionId,
    this.blocks,
    this.correctOrder,
    this.initialState,
    this.targetState,
    required this.damage,
    this.criticalDamage = 10,
    required this.counterAttackMessage,
    this.hint,
    this.codeSnippet,
    this.explanation,
  });

  final String id;
  final String title;
  final String instruction;
  final BossPhaseType type;
  final List<BossOption>? options; // for select/repair
  final String? correctOptionId;
  final List<BossBlock>? blocks; // for arrange
  final List<String>? correctOrder; // for arrange: ordered ids
  final List<int>? initialState; // for toggle
  final List<int>? targetState; // for toggle
  final int damage; // base damage on correct
  final int criticalDamage; // extra if critical
  final String counterAttackMessage;
  final String? hint;
  final String? codeSnippet;
  final String? explanation;

  /// Validate phase invariants.
  bool get isValid {
    if (id.isEmpty || title.isEmpty || instruction.isEmpty) return false;
    if (damage <= 0) return false;
    if (counterAttackMessage.isEmpty) return false;
    switch (type) {
      case BossPhaseType.select:
      case BossPhaseType.repair:
        if (options == null || options!.length < 2) return false;
        if (correctOptionId == null) return false;
        if (!options!.any((o) => o.id == correctOptionId)) return false;
        final ids = options!.map((o) => o.id).toSet();
        if (ids.length != options!.length) return false;
        return true;
      case BossPhaseType.arrange:
        if (blocks == null || blocks!.length < 2) return false;
        if (correctOrder == null || correctOrder!.length != blocks!.length) return false;
        final bIds = blocks!.map((b) => b.id).toSet();
        if (bIds.length != blocks!.length) return false;
        for (final cid in correctOrder!) {
          if (!bIds.contains(cid)) return false;
        }
        return true;
      case BossPhaseType.toggle:
        if (initialState == null || targetState == null) return false;
        if (initialState!.length != targetState!.length) return false;
        if (initialState!.length < 2) return false;
        return true;
    }
  }

  bool isSelectCorrect(String selectedId) {
    if (type != BossPhaseType.select && type != BossPhaseType.repair) return false;
    return selectedId == correctOptionId;
  }

  bool isArrangeCorrect(List<String> orderedIds) {
    if (type != BossPhaseType.arrange) return false;
    if (orderedIds.length != correctOrder!.length) return false;
    for (var i = 0; i < correctOrder!.length; i++) {
      if (orderedIds[i] != correctOrder![i]) return false;
    }
    return true;
  }

  bool isToggleCorrect(List<int> finalState) {
    if (type != BossPhaseType.toggle) return false;
    if (finalState.length != targetState!.length) return false;
    for (var i = 0; i < targetState!.length; i++) {
      if (finalState[i] != targetState![i]) return false;
    }
    return true;
  }

  /// Generic checker for any player answer shape - for tests.
  bool isCorrectDynamic(dynamic answer) {
    switch (type) {
      case BossPhaseType.select:
      case BossPhaseType.repair:
        return answer is String && isSelectCorrect(answer);
      case BossPhaseType.arrange:
        return answer is List<String> && isArrangeCorrect(answer);
      case BossPhaseType.toggle:
        return answer is List<int> && isToggleCorrect(answer);
    }
  }
}

/// Boss definition — pure Dart.
class BossBattle {
  const BossBattle({
    required this.id,
    required this.name,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.intro,
    required this.story,
    required this.learningObjective,
    required this.maxHp,
    required this.phases,
    required this.explanation,
    required this.conceptExplanation,
    required this.victoryMessage,
    this.hint,
  });

  final String id;
  final String name; // e.g., DEADLOCK TITAN
  final String title; // e.g., Titan of Frozen Threads
  final String topic;
  final GameDifficulty difficulty;
  final String intro;
  final String story;
  final String learningObjective;
  final int maxHp;
  final List<BossPhase> phases;
  final String explanation;
  final String conceptExplanation;
  final String victoryMessage;
  final String? hint;

  static int hpForDifficulty(GameDifficulty d) => switch (d) {
        GameDifficulty.easy => 80,
        GameDifficulty.medium => 100,
        GameDifficulty.hard => 120,
      };

  bool get isValid {
    if (id.isEmpty || name.isEmpty || title.isEmpty) return false;
    if (topic.isEmpty) return false;
    if (intro.isEmpty || story.isEmpty || learningObjective.isEmpty) return false;
    if (explanation.isEmpty || conceptExplanation.isEmpty || victoryMessage.isEmpty) return false;
    if (phases.length < 3) return false;
    // difficulty -> phase count enforcement
    final minPhases = switch (difficulty) {
      GameDifficulty.easy => 3,
      GameDifficulty.medium => 4,
      GameDifficulty.hard => 5,
    };
    if (phases.length < minPhases) return false;
    if (maxHp != hpForDifficulty(difficulty)) return false;
    final pIds = phases.map((p) => p.id).toSet();
    if (pIds.length != phases.length) return false;
    for (final p in phases) {
      if (!p.isValid) return false;
    }
    return true;
  }

  int get totalDamagePotential => phases.fold(0, (sum, p) => sum + p.damage);
}

/// Mutable session state for deterministic simulation and testing.
class BossBattleState {
  final BossBattle boss;
  int currentPhaseIndex = 0;
  late int bossHp;
  late int maxHp;

  int lives = 3;
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  List<bool> phaseCompleted = [];

  BossBattleState._init(this.boss)
      : bossHp = boss.maxHp,
        maxHp = boss.maxHp {
    phaseCompleted = List.filled(boss.phases.length, false);
  }

  factory BossBattleState.create(BossBattle boss) => BossBattleState._init(boss);

  BossPhase get currentPhase => boss.phases[currentPhaseIndex];
  bool get isLastPhase => currentPhaseIndex >= boss.phases.length - 1;
  bool get isDefeated => bossHp <= 0;
  bool get isGameOver => lives <= 0;
  double get hpProgress => maxHp == 0 ? 0 : bossHp / maxHp;
  int get totalPhases => boss.phases.length;

  /// Apply correct action: damage boss, update combo, return damage dealt (including critical if applicable).
  /// critical if caller determines efficient/perfect.
  int applyCorrect({bool critical = false, int comboBefore = 0}) {
    final phase = currentPhase;
    int dmg = phase.damage;
    if (critical) dmg += phase.criticalDamage;
    bossHp -= dmg;
    if (bossHp < 0) bossHp = 0;
    phaseCompleted[currentPhaseIndex] = true;
    // combo handled outside, but track max
    combo = comboBefore + 1;
    if (combo > maxCombo) maxCombo = combo;
    return dmg;
  }

  /// Apply incorrect action: trigger counterattack, lose life, break combo.
  void applyIncorrect() {
    lives--;
    if (lives < 0) lives = 0;
    combo = 0;
  }

  /// Advance to next phase if not last.
  bool advancePhase() {
    if (isLastPhase) return false;
    currentPhaseIndex++;
    return true;
  }

  void reset() {
    currentPhaseIndex = 0;
    bossHp = boss.maxHp;
    maxHp = boss.maxHp;
    lives = 3;
    score = 0;
    combo = 0;
    maxCombo = 0;
    phaseCompleted = List.filled(boss.phases.length, false);
  }

  /// Damage boss directly (test helper).
  void damageBoss(int amount) {
    bossHp -= amount;
    if (bossHp < 0) bossHp = 0;
  }

  bool canAffordCritical({required bool noMistakes, required int currentCombo}) {
    // Critical if no mistakes and combo >=2
    return noMistakes && currentCombo >= 2;
  }
}

abstract final class BossBattleValidator {
  static bool hasNoDuplicateIds(List<BossBattle> bosses) {
    final ids = bosses.map((b) => b.id).toSet();
    return ids.length == bosses.length;
  }

  static Set<String> topicsOf(List<BossBattle> bosses) => bosses.map((b) => b.topic).toSet();
  static Set<GameDifficulty> difficultiesOf(List<BossBattle> bosses) => bosses.map((b) => b.difficulty).toSet();
}
