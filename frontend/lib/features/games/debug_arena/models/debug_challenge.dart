import '../../../game_engine/models/game_models.dart';

/// Bug category taxonomy for Debug Arena (6 approved categories).
enum BugCategory {
  syntax('Syntax Bug', 'SYNTAX', 'Typo or invalid language syntax'),
  logic('Logic Bug', 'LOGIC', 'Wrong reasoning, program runs but result is incorrect'),
  infiniteLoop('Infinite Loop', 'INFINITE_LOOP', 'Loop never terminates'),
  wrongCondition('Wrong Condition', 'WRONG_CONDITION', 'If/while condition is flawed'),
  wrongVariable('Wrong Variable', 'WRONG_VARIABLE', 'Incorrect variable used'),
  offByOne('Off-By-One', 'OFF_BY_ONE', 'Loop or index boundary off by one');

  const BugCategory(this.displayName, this.id, this.hint);
  final String displayName;
  final String id;
  final String hint;
}

/// Progressive level inside Debug Arena.
enum DebugLevel {
  findTheBug(1, 'FIND THE BUG', 'Spot the faulty line'),
  identifyCause(2, 'IDENTIFY CAUSE', 'Why does it misbehave?'),
  chooseTheFix(3, 'CHOOSE THE FIX', 'Pick the correct correction'),
  applyTheFix(4, 'APPLY THE FIX', 'Select the code fragment to patch'),
  challengeMode(5, 'CHALLENGE MODE', 'Multiple bug concepts');

  const DebugLevel(this.number, this.label, this.description);
  final int number;
  final String label;
  final String description;
}

/// Single debug challenge. Frontend-only for v1 (isolated data layer).
class DebugChallenge {
  const DebugChallenge({
    required this.id,
    required this.title,
    required this.language,
    required this.topic,
    required this.bugCategory,
    required this.buggyCode,
    required this.explanation,
    required this.correctDiagnosis,
    required this.choices,
    required this.difficulty,
    required this.level,
    this.hint,
    this.fixedCode,
  });

  final String id;
  final String title;
  final String language; // e.g., Dart, Java, Python
  final String topic; // e.g., Loops, Conditions
  final BugCategory bugCategory;
  final String buggyCode; // displayed verbatim, monospace
  final String explanation; // shown after answer
  final String correctDiagnosis; // must be one of choices
  final List<String> choices; // 4 choices
  final GameDifficulty difficulty;
  final DebugLevel level;
  final String? hint;
  final String? fixedCode; // optional correct snippet for level 3/4 display

  bool isCorrect(String selected) => selected == correctDiagnosis;
}

/// Extension to map DebugLevel to prompt question text.
extension DebugChallengePrompt on DebugChallenge {
  String get prompt {
    switch (level) {
      case DebugLevel.findTheBug:
        return 'WHAT IS WRONG?';
      case DebugLevel.identifyCause:
        return 'WHY DOES IT FAIL?';
      case DebugLevel.chooseTheFix:
        return 'PICK THE FIX';
      case DebugLevel.applyTheFix:
        return 'WHICH LINE TO PATCH?';
      case DebugLevel.challengeMode:
        return 'DIAGNOSE THE ERROR';
    }
  }

  String get levelHelp {
    switch (level) {
      case DebugLevel.findTheBug:
        return 'Inspect the code and name the bug category.';
      case DebugLevel.identifyCause:
        return 'Understand why the behaviour is wrong.';
      case DebugLevel.chooseTheFix:
        return 'Select the correction that makes the program behave correctly.';
      case DebugLevel.applyTheFix:
        return 'Choose the fragment to replace to ship the fix.';
      case DebugLevel.challengeMode:
        return 'Multiple concepts — stay sharp.';
    }
  }
}
