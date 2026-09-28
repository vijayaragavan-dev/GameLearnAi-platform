import '../../../game_engine/models/game_models.dart';
import '../models/concept_challenge.dart';

abstract final class ConceptChallenges {
  static const List<ConceptChallenge> all = [
    // Programming — FOR loop (easy)
    ConceptChallenge(
      id: 'cb_01',
      title: 'Build a FOR loop',
      topic: 'Programming',
      difficulty: GameDifficulty.easy,
      learningObjective: 'Understand FOR loop structure',
      instruction: 'Arrange the blocks to build a correct FOR loop that prints 0..4',
      blocks: [
        ConceptBlock(id: 'b1', label: 'initialize i = 0'),
        ConceptBlock(id: 'b2', label: 'check i < 5'),
        ConceptBlock(id: 'b3', label: 'print(i)'),
        ConceptBlock(id: 'b4', label: 'increment i'),
        ConceptBlock(id: 'b5', label: 'stop'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'FOR loop: init → condition → body → increment. Stop is not part of the loop body.',
      hint: 'Start with initialization.',
      conceptSnippet: 'for (int i = 0; i < 5; i++) {\n  print(i);\n}',
    ),
    // Programming — function (medium)
    ConceptChallenge(
      id: 'cb_02',
      title: 'Build a function',
      topic: 'Programming',
      difficulty: GameDifficulty.medium,
      learningObjective: 'Function definition order',
      instruction: 'Build a Dart function that returns the sum of two numbers',
      blocks: [
        ConceptBlock(id: 'b1', label: 'return a + b'),
        ConceptBlock(id: 'b2', label: 'int sum(int a, int b)'),
        ConceptBlock(id: 'b3', label: '{'),
        ConceptBlock(id: 'b4', label: '}'),
        ConceptBlock(id: 'b5', label: 'import dart:math'),
      ],
      correctOrder: ['b2', 'b3', 'b1', 'b4'],
      explanation: 'Function header → open brace → body (return) → close brace. Import is unrelated.',
      conceptSnippet: 'int sum(int a, int b) {\n  return a + b;\n}',
    ),
    // Data Structures — Stack LIFO
    ConceptChallenge(
      id: 'cb_03',
      title: 'Stack operations',
      topic: 'Data Structures',
      difficulty: GameDifficulty.easy,
      learningObjective: 'LIFO order',
      instruction: 'Order the operations to implement LIFO push/pop correctly',
      blocks: [
        ConceptBlock(id: 'b1', label: 'push(item) → top'),
        ConceptBlock(id: 'b2', label: 'pop() ← top'),
        ConceptBlock(id: 'b3', label: 'top--'),
        ConceptBlock(id: 'b4', label: 'enqueue()'),
      ],
      correctOrder: ['b1', 'b2', 'b3'],
      explanation: 'Stack: push adds to top, pop removes from top, adjust top pointer. Enqueue is for queue.',
      hint: 'Stack is LIFO.',
    ),
    // DBMS — ACID
    ConceptChallenge(
      id: 'cb_04',
      title: 'ACID transaction',
      topic: 'DBMS',
      difficulty: GameDifficulty.medium,
      learningObjective: 'ACID properties',
      instruction: 'Build a transaction satisfying ACID in correct conceptual order',
      blocks: [
        ConceptBlock(id: 'b1', label: 'Atomicity'),
        ConceptBlock(id: 'b2', label: 'Consistency'),
        ConceptBlock(id: 'b3', label: 'Isolation'),
        ConceptBlock(id: 'b4', label: 'Durability'),
        ConceptBlock(id: 'b5', label: 'Availability'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'ACID = Atomicity, Consistency, Isolation, Durability. Availability belongs to CAP, not ACID.',
    ),
    // OS — Packet journey / Layers? Use OS process lifecycle
    ConceptChallenge(
      id: 'cb_05',
      title: 'Process lifecycle',
      topic: 'Operating Systems',
      difficulty: GameDifficulty.medium,
      learningObjective: 'Process states',
      instruction: 'Order the process lifecycle states correctly',
      blocks: [
        ConceptBlock(id: 'b1', label: 'New'),
        ConceptBlock(id: 'b2', label: 'Ready'),
        ConceptBlock(id: 'b3', label: 'Running'),
        ConceptBlock(id: 'b4', label: 'Terminated'),
        ConceptBlock(id: 'b5', label: 'Compiled'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Process: New → Ready (scheduler) → Running → Terminated. Compiled is not a runtime state.',
      hint: 'Think scheduler.',
    ),
    // Networks — packet journey
    ConceptChallenge(
      id: 'cb_06',
      title: 'Packet journey',
      topic: 'Computer Networks',
      difficulty: GameDifficulty.medium,
      learningObjective: 'OSI layers order',
      instruction: 'Build the correct packet journey from application to physical',
      blocks: [
        ConceptBlock(id: 'b1', label: 'Application'),
        ConceptBlock(id: 'b2', label: 'Transport'),
        ConceptBlock(id: 'b3', label: 'Network'),
        ConceptBlock(id: 'b4', label: 'Physical'),
        ConceptBlock(id: 'b5', label: 'Session'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Simplified path: Application → Transport → Network → Physical. Session belongs between but not in this simplified journey.',
    ),
    // Mathematics — solution steps
    ConceptChallenge(
      id: 'cb_07',
      title: 'Solve equation',
      topic: 'Mathematics',
      difficulty: GameDifficulty.easy,
      learningObjective: 'Linear equation steps',
      instruction: 'Build correct steps to solve 2x + 3 = 11',
      blocks: [
        ConceptBlock(id: 'b1', label: '2x = 8'),
        ConceptBlock(id: 'b2', label: '2x + 3 = 11'),
        ConceptBlock(id: 'b3', label: 'x = 4'),
        ConceptBlock(id: 'b4', label: 'add 3'),
      ],
      correctOrder: ['b2', 'b1', 'b3'],
      explanation: 'Start with equation, subtract 3 → 2x=8, then divide by 2 → x=4. Adding 3 is wrong direction.',
      conceptSnippet: '2x + 3 = 11\n2x = 8\nx = 4',
    ),
    // DBMS — SQL order
    ConceptChallenge(
      id: 'cb_08',
      title: 'SQL execution order',
      topic: 'DBMS',
      difficulty: GameDifficulty.hard,
      learningObjective: 'SQL logical order',
      instruction: 'Arrange SQL clauses in logical execution order',
      blocks: [
        ConceptBlock(id: 'b1', label: 'FROM'),
        ConceptBlock(id: 'b2', label: 'WHERE'),
        ConceptBlock(id: 'b3', label: 'GROUP BY'),
        ConceptBlock(id: 'b4', label: 'SELECT'),
        ConceptBlock(id: 'b5', label: 'ORDER BY'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4', 'b5'],
      explanation: 'Logical order: FROM → WHERE → GROUP BY → SELECT → ORDER BY (different from written order).',
      hint: 'FROM is first in execution.',
    ),
    // OS — deadlock prevention
    ConceptChallenge(
      id: 'cb_09',
      title: 'Deadlock handling',
      topic: 'Operating Systems',
      difficulty: GameDifficulty.hard,
      learningObjective: 'Deadlock prevention steps',
      instruction: 'Build correct order to prevent deadlock via ordering',
      blocks: [
        ConceptBlock(id: 'b1', label: 'Define lock order'),
        ConceptBlock(id: 'b2', label: 'Acquire locks in order'),
        ConceptBlock(id: 'b3', label: 'Hold and wait? No'),
        ConceptBlock(id: 'b4', label: 'Allow preemption'),
        ConceptBlock(id: 'b5', label: 'Circular wait? Avoid'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b5'],
      explanation: 'Prevent deadlock: define global lock order → acquire in order → avoid hold-and-wait → avoid circular wait. Preemption is not needed if ordering holds.',
    ),
    // Networks — TCP handshake
    ConceptChallenge(
      id: 'cb_10',
      title: 'TCP handshake',
      topic: 'Computer Networks',
      difficulty: GameDifficulty.hard,
      learningObjective: 'Three-way handshake',
      instruction: 'Order the TCP three-way handshake',
      blocks: [
        ConceptBlock(id: 'b1', label: 'SYN'),
        ConceptBlock(id: 'b2', label: 'SYN-ACK'),
        ConceptBlock(id: 'b3', label: 'ACK'),
        ConceptBlock(id: 'b4', label: 'FIN'),
      ],
      correctOrder: ['b1', 'b2', 'b3'],
      explanation: 'TCP handshake: SYN → SYN-ACK → ACK. FIN is for termination.',
    ),
    // Programming — if-else ladder
    ConceptChallenge(
      id: 'cb_11',
      title: 'Grade ladder',
      topic: 'Programming',
      difficulty: GameDifficulty.easy,
      learningObjective: 'If-else ordering',
      instruction: 'Build if-else ladder for grades A/B/C correctly (high to low)',
      blocks: [
        ConceptBlock(id: 'b1', label: 'if (score >= 90) A'),
        ConceptBlock(id: 'b2', label: 'else if (score >= 80) B'),
        ConceptBlock(id: 'b3', label: 'else if (score >= 70) C'),
        ConceptBlock(id: 'b4', label: 'else F'),
        ConceptBlock(id: 'b5', label: 'if (score == 70) C'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Check highest threshold first; otherwise lower checks shadow higher. Exact == is wrong.',
    ),
    // Data Structures — BFS
    ConceptChallenge(
      id: 'cb_12',
      title: 'BFS traversal',
      topic: 'Data Structures',
      difficulty: GameDifficulty.medium,
      learningObjective: 'BFS order',
      instruction: 'Order BFS steps correctly',
      blocks: [
        ConceptBlock(id: 'b1', label: 'Enqueue start'),
        ConceptBlock(id: 'b2', label: 'Dequeue & visit'),
        ConceptBlock(id: 'b3', label: 'Enqueue neighbors'),
        ConceptBlock(id: 'b4', label: 'Stack push'),
      ],
      correctOrder: ['b1', 'b2', 'b3'],
      explanation: 'BFS uses queue: enqueue start → dequeue & visit → enqueue unvisited neighbors. Stack is for DFS.',
      conceptSnippet: 'queue.add(start)\nwhile queue not empty:\n  v = queue.remove()\n  visit(v)\n  queue.addAll(neighbors(v))',
    ),
  ];

  static List<ConceptChallenge> forDifficulty(GameDifficulty d) =>
      all.where((c) => c.difficulty == d).toList();

  static List<ConceptChallenge> session({int count = 4, GameDifficulty? difficulty}) {
    final pool = difficulty == null ? all : all.where((c) => c.difficulty.apiValue == difficulty.apiValue).toList();
    final sorted = [...pool]..sort((a, b) => a.id.compareTo(b.id));
    if (sorted.length <= count) return sorted;
    return sorted.take(count).toList();
  }
}
