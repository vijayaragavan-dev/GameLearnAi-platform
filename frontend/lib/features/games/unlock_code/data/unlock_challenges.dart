import '../../../game_engine/models/game_models.dart';
import '../models/unlock_challenge.dart';

/// Isolated frontend catalog for Unlock the Code v1.
/// No backend; deterministic vault code "7 2 9 4" (first 4 fragments).
/// Each correct answer reveals exactly one code component in order.
abstract final class UnlockChallenges {
  /// Deterministic vault code for v1 — simple digits, testable.
  static const VaultCode vaultCode = VaultCode(fragments: ['7', '2', '9', '4']);

  static const List<UnlockChallenge> all = [
    UnlockChallenge(
      id: 'ulc_01',
      title: 'Loop Output',
      topic: 'Programming',
      difficulty: GameDifficulty.easy,
      prompt: 'What is the output?\nfor (int i = 0; i < 3; i++) print(i);',
      codeSnippet: 'for (int i = 0; i < 3; i++) print(i);',
      choices: ['0 1 2', '1 2 3', '0 1 2 3', '2 1 0'],
      correctAnswer: '0 1 2',
      explanation: 'Loop runs i=0,1,2 then stops before 3.',
      codeReward: '7',
      hint: 'Check start and end.',
    ),
    UnlockChallenge(
      id: 'ulc_02',
      title: 'Data Structure Choice',
      topic: 'Data Structures',
      difficulty: GameDifficulty.easy,
      prompt: 'Which structure is LIFO?',
      choices: ['Queue', 'Stack', 'Array', 'Tree'],
      correctAnswer: 'Stack',
      explanation: 'Stack is Last-In-First-Out; queue is FIFO.',
      codeReward: '2',
    ),
    UnlockChallenge(
      id: 'ulc_03',
      title: 'SQL Filter',
      topic: 'DBMS',
      difficulty: GameDifficulty.medium,
      prompt: 'Which clause filters rows after aggregation?',
      choices: ['WHERE', 'HAVING', 'ORDER BY', 'GROUP BY'],
      correctAnswer: 'HAVING',
      explanation: 'WHERE filters before aggregation; HAVING filters after GROUP BY.',
      codeReward: '9',
      hint: 'Think GROUP BY + filter.',
    ),
    UnlockChallenge(
      id: 'ulc_04',
      title: 'OS Scheduling',
      topic: 'Operating Systems',
      difficulty: GameDifficulty.medium,
      prompt: 'Which algorithm may cause starvation?',
      choices: ['Round Robin', 'FCFS', 'Priority Scheduling', 'SJF (non-preemptive)'],
      correctAnswer: 'Priority Scheduling',
      explanation: 'Low-priority processes can starve in strict priority scheduling.',
      codeReward: '4',
    ),
    UnlockChallenge(
      id: 'ulc_05',
      title: 'Network Layer',
      topic: 'Computer Networks',
      difficulty: GameDifficulty.easy,
      prompt: 'Which layer handles routing?',
      choices: ['Physical', 'Data Link', 'Network', 'Transport'],
      correctAnswer: 'Network',
      explanation: 'Network layer (L3) handles routing and logical addressing.',
      codeReward: '7',
    ),
    UnlockChallenge(
      id: 'ulc_06',
      title: 'Equation Solve',
      topic: 'Programming',
      difficulty: GameDifficulty.medium,
      prompt: 'Solve: int x = 5 + 2 * 3; // x = ?',
      codeSnippet: 'int x = 5 + 2 * 3;',
      choices: ['21', '11', '10', '13'],
      correctAnswer: '11',
      explanation: 'Multiplication first: 2*3=6, then 5+6=11.',
      codeReward: '2',
    ),
    UnlockChallenge(
      id: 'ulc_07',
      title: 'Binary Search',
      topic: 'Data Structures',
      difficulty: GameDifficulty.hard,
      prompt: 'Best case time of binary search?',
      choices: ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
      correctAnswer: 'O(1)',
      explanation: 'If target is middle element, found in one comparison.',
      codeReward: '9',
    ),
    UnlockChallenge(
      id: 'ulc_08',
      title: 'ACID Property',
      topic: 'DBMS',
      difficulty: GameDifficulty.hard,
      prompt: 'Which ACID property ensures all-or-nothing?',
      choices: ['Atomicity', 'Consistency', 'Isolation', 'Durability'],
      correctAnswer: 'Atomicity',
      explanation: 'Atomicity guarantees transaction completes fully or not at all.',
      codeReward: '4',
    ),
    UnlockChallenge(
      id: 'ulc_09',
      title: 'Deadlock Condition',
      topic: 'Operating Systems',
      difficulty: GameDifficulty.hard,
      prompt: 'Which is NOT a Coffman deadlock condition?',
      choices: ['Mutual exclusion', 'Hold and wait', 'Preemption allowed', 'Circular wait'],
      correctAnswer: 'Preemption allowed',
      explanation: 'Deadlock requires no preemption; preemption allowed prevents it.',
      codeReward: '7',
    ),
    UnlockChallenge(
      id: 'ulc_10',
      title: 'Subnet Mask',
      topic: 'Computer Networks',
      difficulty: GameDifficulty.medium,
      prompt: 'How many host bits in /26?',
      choices: ['6', '26', '32', '24'],
      correctAnswer: '6',
      explanation: '32 total - 26 network = 6 host bits (64 addresses).',
      codeReward: '2',
    ),
    UnlockChallenge(
      id: 'ulc_11',
      title: 'Recursion Base',
      topic: 'Programming',
      difficulty: GameDifficulty.easy,
      prompt: 'What stops recursion?',
      choices: ['Base case', 'Loop', 'Variable', 'Compiler'],
      correctAnswer: 'Base case',
      explanation: 'Base case terminates recursion; without it, stack overflow.',
      codeReward: '9',
    ),
    UnlockChallenge(
      id: 'ulc_12',
      title: 'Indexing',
      topic: 'DBMS',
      difficulty: GameDifficulty.medium,
      prompt: 'Which index speeds up equality lookup?',
      choices: ['B-Tree', 'Hash', 'Bitmap', 'Full-text'],
      correctAnswer: 'Hash',
      explanation: 'Hash index excels at exact equality searches.',
      codeReward: '4',
    ),
  ];

  static List<UnlockChallenge> forDifficulty(GameDifficulty d) =>
      all.where((c) => c.difficulty == d).toList();

  /// Deterministic session: first [count] challenges sorted by id, mapped to vault fragments in order.
  static List<UnlockChallenge> session({int count = 4, GameDifficulty? difficulty}) {
    final pool = difficulty == null ? all : all.where((c) => c.difficulty.apiValue == difficulty.apiValue).toList();
    final sorted = [...pool]..sort((a, b) => a.id.compareTo(b.id));
    if (sorted.length <= count) return sorted;
    return sorted.take(count).toList();
  }

  /// Returns vault that aligns with session order: fragment i corresponds to challenge i.
  static VaultCode vaultForSession(List<UnlockChallenge> session) {
    // For v1, always use the fixed vaultCode truncated/padded to session length.
    if (session.length == vaultCode.length) return vaultCode;
    final frags = List.generate(session.length, (i) => vaultCode.fragments[i % vaultCode.length]);
    return VaultCode(fragments: frags);
  }
}
