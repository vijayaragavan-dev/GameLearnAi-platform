import '../../../game_engine/models/game_models.dart';
import '../models/sequence_challenge.dart';

abstract final class SequenceChallenges {
  static const List<SequenceChallenge> all = [
    // Programming — program execution (arrange)
    SequenceChallenge(
      id: 'sm_01',
      title: 'Program execution',
      topic: 'Programming',
      difficulty: GameDifficulty.easy,
      mode: SequenceMode.arrange,
      learningObjective: 'Program lifecycle order',
      instruction: 'Arrange the program execution flow correctly',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'START'),
        SequenceBlock(id: 'b2', label: 'Read input'),
        SequenceBlock(id: 'b3', label: 'Process input'),
        SequenceBlock(id: 'b4', label: 'Generate output'),
        SequenceBlock(id: 'b5', label: 'END'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4', 'b5'],
      explanation: 'Program: START → Read input → Process → Generate output → END. Correct chronology is essential.',
      hint: 'START is first.',
    ),
    // Programming — function call flow (arrange)
    SequenceChallenge(
      id: 'sm_02',
      title: 'Function call flow',
      topic: 'Programming',
      difficulty: GameDifficulty.medium,
      mode: SequenceMode.arrange,
      learningObjective: 'Function call stack',
      instruction: 'Order the function call steps',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Call function'),
        SequenceBlock(id: 'b2', label: 'Push stack frame'),
        SequenceBlock(id: 'b3', label: 'Execute body'),
        SequenceBlock(id: 'b4', label: 'Return value'),
        SequenceBlock(id: 'b5', label: 'Pop frame'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4', 'b5'],
      explanation: 'Call → push frame → execute → return → pop. Stack frames isolate calls.',
    ),
    // Programming — loop execution (arrange)
    SequenceChallenge(
      id: 'sm_03',
      title: 'Loop execution',
      topic: 'Programming',
      difficulty: GameDifficulty.easy,
      mode: SequenceMode.arrange,
      learningObjective: 'Loop phases',
      instruction: 'Build the loop execution order',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Initialize'),
        SequenceBlock(id: 'b2', label: 'Condition check'),
        SequenceBlock(id: 'b3', label: 'Process'),
        SequenceBlock(id: 'b4', label: 'Update'),
        SequenceBlock(id: 'b5', label: 'Repeat / Exit'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4', 'b5'],
      explanation: 'Loop: Initialize → Condition → Process → Update → Repeat/Exit.',
    ),
    // Data Structures — stack operations (arrange)
    SequenceChallenge(
      id: 'sm_04',
      title: 'Stack LIFO',
      topic: 'Data Structures',
      difficulty: GameDifficulty.easy,
      mode: SequenceMode.arrange,
      learningObjective: 'Stack operations order',
      instruction: 'Arrange stack push/pop sequence for LIFO',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'push(A)'),
        SequenceBlock(id: 'b2', label: 'push(B)'),
        SequenceBlock(id: 'b3', label: 'pop() → B'),
        SequenceBlock(id: 'b4', label: 'pop() → A'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Stack LIFO: push A, push B, pop gets B first, then A.',
    ),
    // Data Structures — queue operations (arrange)
    SequenceChallenge(
      id: 'sm_05',
      title: 'Queue FIFO',
      topic: 'Data Structures',
      difficulty: GameDifficulty.easy,
      mode: SequenceMode.arrange,
      learningObjective: 'Queue order',
      instruction: 'Order queue operations for FIFO',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'enqueue(X)'),
        SequenceBlock(id: 'b2', label: 'enqueue(Y)'),
        SequenceBlock(id: 'b3', label: 'dequeue() → X'),
        SequenceBlock(id: 'b4', label: 'dequeue() → Y'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Queue FIFO: enqueue X/Y, dequeue X first, then Y.',
    ),
    // Data Structures — BFS (arrange)
    SequenceChallenge(
      id: 'sm_06',
      title: 'BFS order',
      topic: 'Data Structures',
      difficulty: GameDifficulty.medium,
      mode: SequenceMode.arrange,
      learningObjective: 'BFS traversal',
      instruction: 'Arrange BFS steps',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Enqueue start'),
        SequenceBlock(id: 'b2', label: 'Dequeue & visit'),
        SequenceBlock(id: 'b3', label: 'Enqueue neighbors'),
        SequenceBlock(id: 'b4', label: 'Repeat until empty'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'BFS: Enqueue start → Dequeue & visit → Enqueue neighbors → Repeat.',
    ),
    // DBMS — SQL execution order (arrange)
    SequenceChallenge(
      id: 'sm_07',
      title: 'SQL execution',
      topic: 'DBMS',
      difficulty: GameDifficulty.hard,
      mode: SequenceMode.arrange,
      learningObjective: 'SQL logical order',
      instruction: 'Arrange SQL logical execution order',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'FROM'),
        SequenceBlock(id: 'b2', label: 'WHERE'),
        SequenceBlock(id: 'b3', label: 'GROUP BY'),
        SequenceBlock(id: 'b4', label: 'HAVING'),
        SequenceBlock(id: 'b5', label: 'SELECT'),
        SequenceBlock(id: 'b6', label: 'ORDER BY'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4', 'b5', 'b6'],
      explanation: 'Logical order: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY.',
      hint: 'FROM is first in execution.',
    ),
    // DBMS — transaction lifecycle (arrange)
    SequenceChallenge(
      id: 'sm_08',
      title: 'Transaction lifecycle',
      topic: 'DBMS',
      difficulty: GameDifficulty.medium,
      mode: SequenceMode.arrange,
      learningObjective: 'Transaction states',
      instruction: 'Order transaction lifecycle',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Begin'),
        SequenceBlock(id: 'b2', label: 'Execute operations'),
        SequenceBlock(id: 'b3', label: 'Commit / Rollback'),
        SequenceBlock(id: 'b4', label: 'End'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Transaction: Begin → Execute → Commit/Rollback → End.',
    ),
    // DBMS — commit flow (complete)
    SequenceChallenge(
      id: 'sm_09',
      title: 'Transaction commit',
      topic: 'DBMS',
      difficulty: GameDifficulty.medium,
      mode: SequenceMode.complete,
      learningObjective: 'Commit sequence',
      instruction: 'Complete the transaction commit flow',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Begin'),
        SequenceBlock(id: 'b2', label: '???'),
        SequenceBlock(id: 'b3', label: 'Commit'),
      ],
      correctOrder: ['b1', 'b2', 'b3'],
      missingPositions: [1],
      candidateBlocks: [
        SequenceBlock(id: 'c1', label: 'Execute operations'),
        SequenceBlock(id: 'c2', label: 'Drop table'),
        SequenceBlock(id: 'c3', label: 'Reboot OS'),
      ],
      correctAnswer: 'c1',
      explanation: 'Commit flow: Begin → Execute operations → Commit. Other candidates are unrelated.',
    ),
    // OS — process lifecycle (arrange)
    SequenceChallenge(
      id: 'sm_10',
      title: 'Process lifecycle',
      topic: 'Operating Systems',
      difficulty: GameDifficulty.medium,
      mode: SequenceMode.arrange,
      learningObjective: 'Process states',
      instruction: 'Order process lifecycle states',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'New'),
        SequenceBlock(id: 'b2', label: 'Ready'),
        SequenceBlock(id: 'b3', label: 'Running'),
        SequenceBlock(id: 'b4', label: 'Terminated'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Process: New → Ready → Running → Terminated.',
    ),
    // OS — CPU scheduling flow (arrange)
    SequenceChallenge(
      id: 'sm_11',
      title: 'CPU scheduling',
      topic: 'Operating Systems',
      difficulty: GameDifficulty.medium,
      mode: SequenceMode.arrange,
      learningObjective: 'Scheduling flow',
      instruction: 'Arrange CPU scheduling steps',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Job arrives'),
        SequenceBlock(id: 'b2', label: 'Scheduler selects'),
        SequenceBlock(id: 'b3', label: 'Dispatch to CPU'),
        SequenceBlock(id: 'b4', label: 'Execute'),
        SequenceBlock(id: 'b5', label: 'Preempt / Complete'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4', 'b5'],
      explanation: 'Scheduling: arrival → selection → dispatch → execute → preempt/complete.',
    ),
    // OS — deadlock handling (arrange)
    SequenceChallenge(
      id: 'sm_12',
      title: 'Deadlock handling',
      topic: 'Operating Systems',
      difficulty: GameDifficulty.hard,
      mode: SequenceMode.arrange,
      learningObjective: 'Deadlock prevention',
      instruction: 'Order deadlock prevention steps',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Define lock order'),
        SequenceBlock(id: 'b2', label: 'Acquire in order'),
        SequenceBlock(id: 'b3', label: 'Avoid hold-and-wait'),
        SequenceBlock(id: 'b4', label: 'Avoid circular wait'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Prevention: define order → acquire in order → avoid hold-and-wait → avoid circular wait.',
    ),
    // Networks — TCP handshake (complete, missing middle)
    SequenceChallenge(
      id: 'sm_13',
      title: 'TCP handshake',
      topic: 'Computer Networks',
      difficulty: GameDifficulty.hard,
      mode: SequenceMode.complete,
      learningObjective: 'Three-way handshake',
      instruction: 'Complete the TCP handshake sequence',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'SYN'),
        SequenceBlock(id: 'b2', label: '???'),
        SequenceBlock(id: 'b3', label: 'ACK'),
      ],
      correctOrder: ['b1', 'b2', 'b3'],
      missingPositions: [1],
      candidateBlocks: [
        SequenceBlock(id: 'c1', label: 'SYN-ACK'),
        SequenceBlock(id: 'c2', label: 'FIN'),
        SequenceBlock(id: 'c3', label: 'RST'),
      ],
      correctAnswer: 'c1',
      explanation: 'TCP handshake: SYN → SYN-ACK → ACK. SYN-ACK is the missing middle.',
      hint: 'Second is combined.',
    ),
    // Networks — packet journey (arrange)
    SequenceChallenge(
      id: 'sm_14',
      title: 'Packet journey',
      topic: 'Computer Networks',
      difficulty: GameDifficulty.medium,
      mode: SequenceMode.arrange,
      learningObjective: 'OSI path',
      instruction: 'Build packet journey from app to physical',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Application'),
        SequenceBlock(id: 'b2', label: 'Transport'),
        SequenceBlock(id: 'b3', label: 'Network'),
        SequenceBlock(id: 'b4', label: 'Physical'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Simplified: Application → Transport → Network → Physical.',
    ),
    // Networks — DNS lookup (arrange)
    SequenceChallenge(
      id: 'sm_15',
      title: 'DNS lookup',
      topic: 'Computer Networks',
      difficulty: GameDifficulty.medium,
      mode: SequenceMode.arrange,
      learningObjective: 'DNS steps',
      instruction: 'Order DNS lookup steps',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Query DNS'),
        SequenceBlock(id: 'b2', label: 'Cache check'),
        SequenceBlock(id: 'b3', label: 'Recursive search'),
        SequenceBlock(id: 'b4', label: 'Return IP'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'DNS: Query → Cache check → Recursive search → Return IP.',
    ),
    // Mathematics — arithmetic progression (complete, missing term)
    SequenceChallenge(
      id: 'sm_16',
      title: 'Arithmetic progression',
      topic: 'Mathematics',
      difficulty: GameDifficulty.easy,
      mode: SequenceMode.complete,
      learningObjective: 'Pattern completion',
      instruction: 'Complete the arithmetic progression',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: '2'),
        SequenceBlock(id: 'b2', label: '5'),
        SequenceBlock(id: 'b3', label: '???'),
        SequenceBlock(id: 'b4', label: '11'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      missingPositions: [2],
      candidateBlocks: [
        SequenceBlock(id: 'c1', label: '8'),
        SequenceBlock(id: 'c2', label: '9'),
        SequenceBlock(id: 'c3', label: '7'),
      ],
      correctAnswer: 'c1',
      explanation: 'Progression +3: 2,5,8,11. Missing is 8.',
    ),
    // Mathematics — equation steps (arrange)
    SequenceChallenge(
      id: 'sm_17',
      title: 'Equation steps',
      topic: 'Mathematics',
      difficulty: GameDifficulty.easy,
      mode: SequenceMode.arrange,
      learningObjective: 'Solve linear equation',
      instruction: 'Order steps to solve 2x+3=11',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: '2x+3=11'),
        SequenceBlock(id: 'b2', label: '2x=8'),
        SequenceBlock(id: 'b3', label: 'x=4'),
      ],
      correctOrder: ['b1', 'b2', 'b3'],
      explanation: '2x+3=11 → subtract 3 →2x=8 → divide by2 →x=4.',
    ),
    // Science — cause → effect (arrange)
    SequenceChallenge(
      id: 'sm_18',
      title: 'Scientific process',
      topic: 'Science',
      difficulty: GameDifficulty.easy,
      mode: SequenceMode.arrange,
      learningObjective: 'Cause-effect chain',
      instruction: 'Order the cause-effect sequence',
      sequenceBlocks: [
        SequenceBlock(id: 'b1', label: 'Sun heats water'),
        SequenceBlock(id: 'b2', label: 'Water evaporates'),
        SequenceBlock(id: 'b3', label: 'Clouds form'),
        SequenceBlock(id: 'b4', label: 'Rain falls'),
      ],
      correctOrder: ['b1', 'b2', 'b3', 'b4'],
      explanation: 'Water cycle: heat → evaporation → clouds → rain.',
    ),
  ];

  static List<SequenceChallenge> forDifficulty(GameDifficulty d) =>
      all.where((c) => c.difficulty == d).toList();

  static List<SequenceChallenge> forMode(SequenceMode m) =>
      all.where((c) => c.mode == m).toList();

  static List<SequenceChallenge> session({int count = 4, GameDifficulty? difficulty, SequenceMode? mode}) {
    List<SequenceChallenge> pool = all;
    if (difficulty != null) pool = pool.where((c) => c.difficulty.apiValue == difficulty.apiValue).toList();
    if (mode != null) pool = pool.where((c) => c.mode == mode).toList();
    final sorted = [...pool]..sort((a, b) => a.id.compareTo(b.id));
    if (sorted.length <= count) return sorted;
    return sorted.take(count).toList();
  }
}
