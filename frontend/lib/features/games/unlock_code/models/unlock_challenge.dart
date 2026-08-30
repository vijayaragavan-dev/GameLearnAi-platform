import '../../../game_engine/models/game_models.dart';

/// Single educational challenge that yields a code fragment when solved.
class UnlockChallenge {
  const UnlockChallenge({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.prompt,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
    required this.codeReward,
    this.hint,
    this.codeSnippet,
  });

  final String id;
  final String title; // e.g., "Loop Output"
  final String topic; // e.g., "Programming", "DBMS"
  final GameDifficulty difficulty;
  final String prompt; // question text
  final List<String> choices; // 4
  final String correctAnswer; // must be in choices
  final String explanation;
  final String codeReward; // single digit/letter/symbol e.g., "7"
  final String? hint;
  final String? codeSnippet; // optional code block for prompt

  bool isCorrect(String selected) => selected == correctAnswer;
}

/// Vault code abstraction: deterministic sequence of fragments.
class VaultCode {
  const VaultCode({required this.fragments});

  final List<String> fragments; // e.g., ["7","2","9","4"]

  int get length => fragments.length;

  String get display => fragments.join(' ');

  /// Returns revealed state for [correctCount] fragments.
  List<String?> revealed(int correctCount) {
    return List.generate(length, (i) => i < correctCount ? fragments[i] : null);
  }

  bool isUnlocked(int correctCount) => correctCount >= length;

  String get codeString => fragments.join();
}
