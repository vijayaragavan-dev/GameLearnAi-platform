import '../../../game_engine/models/game_models.dart';
import '../models/debug_challenge.dart';

/// Isolated frontend challenge catalog for Debug Arena v1.
/// No backend required; documented limitation. Each challenge is
/// self-contained: buggyCode never executed, only displayed.
///
/// 14 challenges covering 6 bug categories across levels 1-5.
/// Educational, language-agnostic but prefers Dart/Java/Python
/// (topics already in GameLearn AI).
abstract final class DebugChallenges {
  static const List<DebugChallenge> all = [
    // LEVEL 1 — FIND THE BUG (Syntax)
    DebugChallenge(
      id: 'dbg_01',
      title: 'Missing Semicolon',
      language: 'Java',
      topic: 'Syntax',
      bugCategory: BugCategory.syntax,
      buggyCode: 'int x = 5\nSystem.out.println(x)',
      explanation: 'Java statements must end with a semicolon. The first line lacks `;`.',
      correctDiagnosis: 'Syntax error',
      choices: ['Syntax error', 'Infinite loop', 'Wrong variable', 'Off-by-one'],
      difficulty: GameDifficulty.easy,
      level: DebugLevel.findTheBug,
      hint: 'Look at line endings.',
      fixedCode: 'int x = 5;\nSystem.out.println(x);',
    ),
    DebugChallenge(
      id: 'dbg_02',
      title: 'Infinite Countdown',
      language: 'Dart',
      topic: 'Loops',
      bugCategory: BugCategory.infiniteLoop,
      buggyCode: 'for (int i = 0; i < 10; i--) {\n  print(i);\n}',
      explanation: 'i-- decreases each iteration, so i < 10 stays true forever. Should be i++.',
      correctDiagnosis: 'Infinite loop',
      choices: ['Infinite loop', 'Syntax error', 'Wrong datatype', 'Missing function'],
      difficulty: GameDifficulty.easy,
      level: DebugLevel.findTheBug,
      fixedCode: 'for (int i = 0; i < 10; i++) {\n  print(i);\n}',
    ),
    // LEVEL 1 — Logic
    DebugChallenge(
      id: 'dbg_03',
      title: 'Average Miscalculation',
      language: 'Python',
      topic: 'Logic',
      bugCategory: BugCategory.logic,
      buggyCode: 'def avg(a, b):\n    return a + b / 2',
      explanation: 'Operator precedence: `a + b / 2` is a + (b/2). Needs `(a + b) / 2`.',
      correctDiagnosis: 'Logic bug',
      choices: ['Logic bug', 'Syntax error', 'Infinite loop', 'Wrong variable'],
      difficulty: GameDifficulty.easy,
      level: DebugLevel.findTheBug,
    ),
    // LEVEL 2 — IDENTIFY CAUSE (Wrong Condition)
    DebugChallenge(
      id: 'dbg_04',
      title: 'Eligible Check',
      language: 'Dart',
      topic: 'Conditions',
      bugCategory: BugCategory.wrongCondition,
      buggyCode: 'if (age > 18) {\n  print("eligible");\n} else {\n  print("not eligible");\n}\n// age = 18 should be eligible',
      explanation: 'Condition uses `>` instead of `>=`. 18 is excluded incorrectly.',
      correctDiagnosis: 'Wrong condition',
      choices: ['Wrong condition', 'Syntax error', 'Infinite loop', 'Wrong variable'],
      difficulty: GameDifficulty.medium,
      level: DebugLevel.identifyCause,
      fixedCode: 'if (age >= 18) {',
    ),
    DebugChallenge(
      id: 'dbg_05',
      title: 'Off By One Loop',
      language: 'Java',
      topic: 'Loops',
      bugCategory: BugCategory.offByOne,
      buggyCode: 'for (int i = 0; i <= arr.length; i++) {\n  sum += arr[i];\n}',
      explanation: 'Array indices go 0..length-1. `<= length` accesses out-of-bounds. Should be `< length`.',
      correctDiagnosis: 'Off-by-one',
      choices: ['Off-by-one', 'Wrong variable', 'Syntax error', 'Infinite loop'],
      difficulty: GameDifficulty.medium,
      level: DebugLevel.identifyCause,
      fixedCode: 'for (int i = 0; i < arr.length; i++) {',
    ),
    DebugChallenge(
      id: 'dbg_06',
      title: 'Swapped Variables',
      language: 'Python',
      topic: 'Variables',
      bugCategory: BugCategory.wrongVariable,
      buggyCode: 'def area(w, h):\n    return w * w  # should be w * h',
      explanation: 'Uses `w` twice instead of `w * h`. Wrong variable copied.',
      correctDiagnosis: 'Wrong variable',
      choices: ['Wrong variable', 'Syntax error', 'Wrong condition', 'Infinite loop'],
      difficulty: GameDifficulty.medium,
      level: DebugLevel.identifyCause,
    ),
    // LEVEL 3 — CHOOSE THE FIX
    DebugChallenge(
      id: 'dbg_07',
      title: 'Fix the Loop Header',
      language: 'Dart',
      topic: 'Loops',
      bugCategory: BugCategory.infiniteLoop,
      buggyCode: 'int i = 0;\nwhile (i < 5) {\n  print(i);\n  // missing increment\n}',
      explanation: '`i` never increments, so `i < 5` stays true. Add `i++;`.',
      correctDiagnosis: 'Add i++ inside loop',
      choices: ['Add i++ inside loop', 'Change to i--', 'Change condition to i > 5', 'Remove loop'],
      difficulty: GameDifficulty.medium,
      level: DebugLevel.chooseTheFix,
      fixedCode: 'while (i < 5) {\n  print(i);\n  i++;\n}',
    ),
    DebugChallenge(
      id: 'dbg_08',
      title: 'String vs Int',
      language: 'Dart',
      topic: 'Types',
      bugCategory: BugCategory.syntax,
      buggyCode: 'int score = "100";',
      explanation: 'String literal `"100"` cannot be assigned to int. Use 100 or parse.',
      correctDiagnosis: 'int score = 100;',
      choices: ['int score = 100;', 'String score = 100;', 'int score = true;', 'var score = ;'],
      difficulty: GameDifficulty.easy,
      level: DebugLevel.chooseTheFix,
    ),
    DebugChallenge(
      id: 'dbg_09',
      title: 'Condition Flip',
      language: 'Java',
      topic: 'Conditions',
      bugCategory: BugCategory.wrongCondition,
      buggyCode: 'if (a = b) { // assignment not comparison\n  System.out.println("equal");\n}',
      explanation: 'Single `=` assigns, not compares. Should be `==` (or equals).',
      correctDiagnosis: 'if (a == b)',
      choices: ['if (a == b)', 'if (a = b)', 'if (a != b)', 'if (a > b)'],
      difficulty: GameDifficulty.hard,
      level: DebugLevel.chooseTheFix,
    ),
    // LEVEL 4 — APPLY THE FIX (select fragment)
    DebugChallenge(
      id: 'dbg_10',
      title: 'Patch the Index',
      language: 'Python',
      topic: 'Loops',
      bugCategory: BugCategory.offByOne,
      buggyCode: 'for i in range(0, len(arr)):\n    print(arr[i+1])  # off by one on access',
      explanation: 'Accessing `arr[i+1]` shifts index; last iteration goes out of bounds. Use `arr[i]`.',
      correctDiagnosis: 'print(arr[i])',
      choices: ['print(arr[i])', 'print(arr[i+1])', 'print(arr[i-1])', 'print(arr)'],
      difficulty: GameDifficulty.hard,
      level: DebugLevel.applyTheFix,
    ),
    DebugChallenge(
      id: 'dbg_11',
      title: 'Variable Patch',
      language: 'Dart',
      topic: 'Variables',
      bugCategory: BugCategory.wrongVariable,
      buggyCode: 'int total = price * quantity;\nint discount = total * 0.1;\nint finalPrice = price - discount; // wrong base',
      explanation: 'Discount should subtract from `total`, not `price`.',
      correctDiagnosis: 'finalPrice = total - discount',
      choices: ['finalPrice = total - discount', 'finalPrice = price - discount', 'finalPrice = total + discount', 'finalPrice = discount - total'],
      difficulty: GameDifficulty.hard,
      level: DebugLevel.applyTheFix,
    ),
    // LEVEL 5 — CHALLENGE MODE (combine concepts)
    DebugChallenge(
      id: 'dbg_12',
      title: 'Loop AND Condition',
      language: 'Java',
      topic: 'Loops',
      bugCategory: BugCategory.logic,
      buggyCode: 'int count = 0;\nfor (int i = 1; i < 10; i++) {\n  if (i % 2 = 0) count++;\n}',
      explanation: 'Two issues: `=` vs `==` and logic: counting evens needs `i % 2 == 0`.',
      correctDiagnosis: 'Logic + Wrong condition',
      choices: ['Logic + Wrong condition', 'Syntax only', 'Infinite loop', 'Off-by-one only'],
      difficulty: GameDifficulty.hard,
      level: DebugLevel.challengeMode,
    ),
    DebugChallenge(
      id: 'dbg_13',
      title: 'While Never Ends',
      language: 'Python',
      topic: 'Loops',
      bugCategory: BugCategory.infiniteLoop,
      buggyCode: 'x = 10\nwhile x > 0:\n    print(x)\n    x = x + 1  # should decrease',
      explanation: 'x grows, so `x > 0` stays true. Should be `x - 1` or `x -= 1`.',
      correctDiagnosis: 'Infinite loop — wrong update',
      choices: ['Infinite loop — wrong update', 'Off-by-one', 'Syntax error', 'Wrong variable'],
      difficulty: GameDifficulty.hard,
      level: DebugLevel.challengeMode,
    ),
    DebugChallenge(
      id: 'dbg_14',
      title: 'Fence Post',
      language: 'Dart',
      topic: 'Loops',
      bugCategory: BugCategory.offByOne,
      buggyCode: 'for (int i = 1; i <= 10; i++) {\n  print("Item \$i");\n}\n// prints 10 items but array has 10 slots 0..9',
      explanation: 'When mapping to 0-based array, should start at 0 and go <10. Mixing 1-based count with 0-based index is off-by-one.',
      correctDiagnosis: 'Off-by-one',
      choices: ['Off-by-one', 'Syntax error', 'Infinite loop', 'Wrong condition'],
      difficulty: GameDifficulty.medium,
      level: DebugLevel.challengeMode,
    ),
  ];

  static List<DebugChallenge> forDifficulty(GameDifficulty d) =>
      all.where((c) => c.difficulty == d).toList();

  static List<DebugChallenge> forLevel(DebugLevel l) =>
      all.where((c) => c.level == l).toList();

  /// Deterministic selection for a session: take first N shuffled with seed, filtered by difficulty if requested.
  static List<DebugChallenge> session({int count = 8, GameDifficulty? difficulty}) {
    final pool = difficulty == null ? all : all.where((c) => c.difficulty.apiValue == difficulty.apiValue).toList();
    // Deterministic: sort by id then take
    final sorted = [...pool]..sort((a, b) => a.id.compareTo(b.id));
    if (sorted.length <= count) return sorted;
    // Take with pseudo-random but deterministic: every other starting at 0
    return sorted.take(count).toList();
  }
}
