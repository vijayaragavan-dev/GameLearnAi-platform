import '../../../game_engine/models/game_models.dart';

enum TargetMode { valueTarget, stateTarget, conceptTarget }

class TargetAction {
  const TargetAction({required this.id, required this.label, required this.type, this.value, this.toggleIndex});
  final String id;
  final String label; // e.g., "+3", "×2", "Toggle bit 1"
  final String type; // "add", "multiply", "subtract", "divide", "toggle"
  final int? value; // for arithmetic
  final int? toggleIndex; // for state
}

class TargetChallenge {
  const TargetChallenge({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.mode,
    required this.learningObjective,
    required this.instruction,
    required this.initialValue,
    required this.targetValue,
    this.initialState,
    this.targetState,
    required this.availableActions,
    this.correctSequence,
    required this.explanation,
    this.hint,
    this.conceptSnippet,
    this.maxActions = 8,
    this.optimalActions,
  });

  final String id;
  final String title;
  final String topic;
  final GameDifficulty difficulty;
  final TargetMode mode;
  final String learningObjective;
  final String instruction;
  final int initialValue; // for valueTarget: start int
  final int targetValue; // for valueTarget: exact target int
  final List<int>? initialState; // for stateTarget: e.g., [0,0,0]
  final List<int>? targetState; // for stateTarget: e.g., [1,1,0]
  final List<TargetAction> availableActions;
  final List<String>? correctSequence; // one valid solution (list of action ids) for explanation
  final String explanation;
  final String? hint;
  final String? conceptSnippet;
  final int maxActions;
  final int? optimalActions;

  bool get isValueMode => mode == TargetMode.valueTarget;
  bool get isStateMode => mode == TargetMode.stateTarget;

  /// Simulate applying actions in order; returns final value/state.
  /// For value mode, returns final int value. For state mode, returns equality bool.
  /// If division would be non-integer or invalid, returns null to indicate invalid path.

  int? simulateValue(List<String> actionIds) {
    int current = initialValue;
    for (final aid in actionIds) {
      final act = availableActions.firstWhere((a) => a.id == aid, orElse: () => const TargetAction(id: '', label: '', type: ''));
      if (act.id.isEmpty) return null;
      switch (act.type) {
        case 'add':
          current += act.value ?? 0;
          break;
        case 'subtract':
          current -= act.value ?? 0;
          break;
        case 'multiply':
          current *= act.value ?? 1;
          break;
        case 'divide':
          if (act.value == null || act.value == 0) return null;
          if (current % act.value! != 0) return null; // require exact integer division educational
          current ~/= act.value!;
          break;
        default:
          return null;
      }
      // Prevent wild infinite explosion
      if (current < -1000 || current > 1000) return null;
    }
    return current;
  }

  bool isValueReached(List<String> actionIds) {
    final v = simulateValue(actionIds);
    return v != null && v == targetValue;
  }

  List<int>? simulateState(List<String> actionIds) {
    if (initialState == null || targetState == null) return null;
    var state = List<int>.from(initialState!);
    for (final aid in actionIds) {
      final act = availableActions.firstWhere((a) => a.id == aid, orElse: () => const TargetAction(id: '', label: '', type: ''));
      if (act.type == 'toggle' && act.toggleIndex != null) {
        final idx = act.toggleIndex!;
        if (idx < 0 || idx >= state.length) return null;
        state[idx] = state[idx] == 0 ? 1 : 0;
      } else {
        return null;
      }
    }
    return state;
  }

  bool isStateReached(List<String> actionIds) {
    final s = simulateState(actionIds);
    if (s == null || targetState == null) return false;
    if (s.length != targetState!.length) return false;
    for (var i = 0; i < s.length; i++) {
      if (s[i] != targetState![i]) return false;
    }
    return true;
  }

  bool isReached(List<String> actionIds) {
    if (isValueMode) return isValueReached(actionIds);
    if (isStateMode) return isStateReached(actionIds);
    // conceptTarget: treat as value
    return isValueReached(actionIds);
  }
}
