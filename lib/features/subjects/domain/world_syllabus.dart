import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'canonical_worlds.dart';

/// Frontend syllabus hierarchy: WORLD → UNIT → TOPIC → SUBTOPIC/CONCEPT.
///
/// This is the ONE source of truth for world→topic structure. Dashboard,
/// learning-path, game-zone, tutor and analytics MUST consume this model
/// (via [syllabusProvider]) instead of duplicating their own topic lists.
///
/// Rules:
/// - Deterministic + ordered: units/topics carry explicit order numbers and
///   the catalog exposes them sorted. Never rely on map iteration order.
/// - Backend remains authoritative for persistence (mastery, lock state,
///   paths). The static topics here carry identity + order + prerequisites;
///   completion/mastery/lock state is attached at runtime from backend data
///   (see [SyllabusTopicProgress]).
/// - Worlds without an authoritative frontend source use
///   [SyllabusSource.pending] with empty units — UI renders EmptyState,
///   never fabricated academic content.
/// - Content isolation: [WorldSyllabus.worldId] owns its topics. A
///   subject-world screen MUST only render topics from its own syllabus.
///   Mixed syllabi are allowed ONLY under [WorldScope.globalArena].

/// Leaf concept / subtopic. Present only where the supplied syllabus material
/// requires finer granularity; otherwise topics stand alone with empty lists.
class SyllabusConcept {
  const SyllabusConcept({
    required this.id,
    required this.title,
    required this.order,
  });

  final String id;
  final String title;
  final int order;
}

/// Topic inside a unit. Descriptions are presentation stubs derived from the
/// topic title itself — no fabricated curriculum beyond the supplied material.
class SyllabusTopic {
  const SyllabusTopic({
    required this.id,
    required this.title,
    this.description = '',
    required this.order,
    this.prerequisites = const [],
    this.concepts = const [],
  });

  final String id;
  final String title;
  final String description;
  final int order;
  final List<String> prerequisites;
  final List<SyllabusConcept> concepts;
}

/// Unit inside a world syllabus.
class SyllabusUnit {
  const SyllabusUnit({
    required this.id,
    required this.worldId,
    required this.title,
    required this.unitNumber,
    required this.topics,
  });

  final String id;
  final WorldId worldId;
  final String title;
  final int unitNumber;
  final List<SyllabusTopic> topics;

  int get topicCount => topics.length;
}

/// Runtime progress attached from backend data (mastery/path/assessment).
/// Never persisted here — computed per render from authoritative responses.
class SyllabusTopicProgress {
  const SyllabusTopicProgress({
    this.mastery,
    this.status = 'UNKNOWN',
    this.isLocked = false,
    this.isCompleted = false,
  });

  final double? mastery;
  final String status;
  final bool isLocked;
  final bool isCompleted;
}

/// Full world syllabus: ordered units + availability truth.
class WorldSyllabus {
  const WorldSyllabus({
    required this.worldId,
    required this.units,
    required this.source,
  });

  final WorldId worldId;
  final List<SyllabusUnit> units;
  final SyllabusSource source;

  bool get isAvailable => source != SyllabusSource.pending && units.isNotEmpty;
  bool get isPending => source == SyllabusSource.pending;

  int get unitCount => units.length;
  int get topicCount => units.fold(0, (n, u) => n + u.topics.length);

  /// Deterministically ordered units (by unitNumber) with ordered topics.
  List<SyllabusUnit> orderedUnits() {
    final sorted = [...units]..sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    return [
      for (final u in sorted)
        SyllabusUnit(
          id: u.id,
          worldId: u.worldId,
          title: u.title,
          unitNumber: u.unitNumber,
          topics: [...u.topics]..sort((a, b) => a.order.compareTo(b.order)),
        ),
    ];
  }

  /// Recommended next topic = first topic id in deterministic order, or null
  /// when the syllabus is pending/empty. Callers combine with backend lock
  /// state to skip locked nodes.
  String? get recommendedNextTopicId {
    for (final u in orderedUnits()) {
      for (final t in u.topics) {
        return t.id;
      }
    }
    return null;
  }

  SyllabusTopic? topicById(String topicId) {
    for (final u in units) {
      for (final t in u.topics) {
        if (t.id == topicId) return t;
      }
    }
    return null;
  }

  /// Isolation check: true only when [topicId] belongs to this world's
  /// syllabus. The Global Arena ([WorldScope.globalArena]) bypasses this.
  bool containsTopic(String topicId, {WorldScope scope = WorldScope.subjectIsolated}) {
    if (scope == WorldScope.globalArena) return true;
    return topicById(topicId) != null;
  }
}

SyllabusTopic _t(WorldId w, String id, String title, int order) => SyllabusTopic(
      id: '${w.key.toLowerCase()}_$id',
      title: title,
      description: title,
      order: order,
    );

/// Authoritative static syllabus catalog. Topics below are the supplied
/// syllabus material only. Worlds without supplied material expose
/// [SyllabusSource.pending] with empty units (extensible, truthful).
abstract final class WorldSyllabusCatalog {
  static const List<WorldId> staticWorlds = [
    WorldId.algorithms,
    WorldId.dbms,
    WorldId.dataScience,
    WorldId.operatingSystems,
    WorldId.oop,
    WorldId.dataStructures,
    WorldId.computerNetworks,
  ];

  static const Map<WorldId, WorldSyllabus> _all = {
    WorldId.algorithms: WorldSyllabus(
      worldId: WorldId.algorithms,
      source: SyllabusSource.staticCatalog,
      units: [
        SyllabusUnit(
          id: 'algorithms_u1',
          worldId: WorldId.algorithms,
          title: 'Foundations & Analysis',
          unitNumber: 1,
          topics: [],
        ),
        SyllabusUnit(
          id: 'algorithms_u2',
          worldId: WorldId.algorithms,
          title: 'Paradigms I — Search, Divide & Conquer',
          unitNumber: 2,
          topics: [],
        ),
        SyllabusUnit(
          id: 'algorithms_u3',
          worldId: WorldId.algorithms,
          title: 'Paradigms II — Dynamic, Greedy, Iterative',
          unitNumber: 3,
          topics: [],
        ),
        SyllabusUnit(
          id: 'algorithms_u4',
          worldId: WorldId.algorithms,
          title: 'Limits, NP Theory & Reduction',
          unitNumber: 4,
          topics: [],
        ),
        SyllabusUnit(
          id: 'algorithms_u5',
          worldId: WorldId.algorithms,
          title: 'Advanced Search & Approximation',
          unitNumber: 5,
          topics: [],
        ),
      ],
    ),
    WorldId.dbms: WorldSyllabus(
      worldId: WorldId.dbms,
      source: SyllabusSource.staticCatalog,
      units: [
        SyllabusUnit(
          id: 'dbms_u1',
          worldId: WorldId.dbms,
          title: 'Concepts, Architecture & Models',
          unitNumber: 1,
          topics: [],
        ),
        SyllabusUnit(
          id: 'dbms_u2',
          worldId: WorldId.dbms,
          title: 'ER Modeling & Relational Design',
          unitNumber: 2,
          topics: [],
        ),
        SyllabusUnit(
          id: 'dbms_u3',
          worldId: WorldId.dbms,
          title: 'SQL, Algebra, Normalization',
          unitNumber: 3,
          topics: [],
        ),
        SyllabusUnit(
          id: 'dbms_u4',
          worldId: WorldId.dbms,
          title: 'Processing, Transactions & Concurrency',
          unitNumber: 4,
          topics: [],
        ),
        SyllabusUnit(
          id: 'dbms_u5',
          worldId: WorldId.dbms,
          title: 'Storage, Distribution & NoSQL',
          unitNumber: 5,
          topics: [],
        ),
      ],
    ),
    WorldId.dataScience: WorldSyllabus(
      worldId: WorldId.dataScience,
      source: SyllabusSource.staticCatalog,
      units: [
        SyllabusUnit(
          id: 'data_science_u1',
          worldId: WorldId.dataScience,
          title: 'Foundations & Description',
          unitNumber: 1,
          topics: [],
        ),
        SyllabusUnit(
          id: 'data_science_u2',
          worldId: WorldId.dataScience,
          title: 'Relationships, Correlation & Regression',
          unitNumber: 2,
          topics: [],
        ),
        SyllabusUnit(
          id: 'data_science_u3',
          worldId: WorldId.dataScience,
          title: 'NumPy, Pandas & Wrangling',
          unitNumber: 3,
          topics: [],
        ),
        SyllabusUnit(
          id: 'data_science_u4',
          worldId: WorldId.dataScience,
          title: 'Visualization — Matplotlib, Seaborn, Geo',
          unitNumber: 4,
          topics: [],
        ),
      ],
    ),
    WorldId.operatingSystems: WorldSyllabus(
      worldId: WorldId.operatingSystems,
      source: SyllabusSource.staticCatalog,
      units: [
        SyllabusUnit(
          id: 'operating_systems_u1',
          worldId: WorldId.operatingSystems,
          title: 'Structure, Processes & Threads',
          unitNumber: 1,
          topics: [],
        ),
        SyllabusUnit(
          id: 'operating_systems_u2',
          worldId: WorldId.operatingSystems,
          title: 'Synchronization & Deadlocks',
          unitNumber: 2,
          topics: [],
        ),
        SyllabusUnit(
          id: 'operating_systems_u3',
          worldId: WorldId.operatingSystems,
          title: 'Memory, Paging & Virtual Memory',
          unitNumber: 3,
          topics: [],
        ),
        SyllabusUnit(
          id: 'operating_systems_u4',
          worldId: WorldId.operatingSystems,
          title: 'Storage, Files & I/O',
          unitNumber: 4,
          topics: [],
        ),
      ],
    ),
    WorldId.oop: WorldSyllabus(
      worldId: WorldId.oop,
      source: SyllabusSource.staticCatalog,
      units: [
        SyllabusUnit(
          id: 'oop_u1',
          worldId: WorldId.oop,
          title: 'Java Basics & Control',
          unitNumber: 1,
          topics: [],
        ),
        SyllabusUnit(
          id: 'oop_u2',
          worldId: WorldId.oop,
          title: 'Classes, Objects & Inheritance',
          unitNumber: 2,
          topics: [],
        ),
        SyllabusUnit(
          id: 'oop_u3',
          worldId: WorldId.oop,
          title: 'Polymorphism, Abstraction & Interfaces',
          unitNumber: 3,
          topics: [],
        ),
        SyllabusUnit(
          id: 'oop_u4',
          worldId: WorldId.oop,
          title: 'Packages, Exceptions & Threads',
          unitNumber: 4,
          topics: [],
        ),
        SyllabusUnit(
          id: 'oop_u5',
          worldId: WorldId.oop,
          title: 'Collections, I/O, JavaFX & JDBC',
          unitNumber: 5,
          topics: [],
        ),
      ],
    ),
    WorldId.dataStructures: WorldSyllabus(
      worldId: WorldId.dataStructures,
      source: SyllabusSource.staticCatalog,
      units: [
        SyllabusUnit(
          id: 'data_structures_u1',
          worldId: WorldId.dataStructures,
          title: 'Linear Structures',
          unitNumber: 1,
          topics: [],
        ),
        SyllabusUnit(
          id: 'data_structures_u2',
          worldId: WorldId.dataStructures,
          title: 'Stacks, Queues & Deques',
          unitNumber: 2,
          topics: [],
        ),
        SyllabusUnit(
          id: 'data_structures_u3',
          worldId: WorldId.dataStructures,
          title: 'Trees, Heaps & Hashing',
          unitNumber: 3,
          topics: [],
        ),
        SyllabusUnit(
          id: 'data_structures_u4',
          worldId: WorldId.dataStructures,
          title: 'Graphs & Shortest Paths',
          unitNumber: 4,
          topics: [],
        ),
        SyllabusUnit(
          id: 'data_structures_u5',
          worldId: WorldId.dataStructures,
          title: 'Sorting',
          unitNumber: 5,
          topics: [],
        ),
      ],
    ),
    WorldId.computerNetworks: WorldSyllabus(
      worldId: WorldId.computerNetworks,
      source: SyllabusSource.staticCatalog,
      units: [
        SyllabusUnit(
          id: 'computer_networks_u1',
          worldId: WorldId.computerNetworks,
          title: 'Foundations & Physical Layer',
          unitNumber: 1,
          topics: [],
        ),
        SyllabusUnit(
          id: 'computer_networks_u2',
          worldId: WorldId.computerNetworks,
          title: 'Data Link & Access Control',
          unitNumber: 2,
          topics: [],
        ),
        SyllabusUnit(
          id: 'computer_networks_u3',
          worldId: WorldId.computerNetworks,
          title: 'Network Layer & Routing',
          unitNumber: 3,
          topics: [],
        ),
        SyllabusUnit(
          id: 'computer_networks_u4',
          worldId: WorldId.computerNetworks,
          title: 'Transport Layer',
          unitNumber: 4,
          topics: [],
        ),
        SyllabusUnit(
          id: 'computer_networks_u5',
          worldId: WorldId.computerNetworks,
          title: 'Application Layer & Wireless',
          unitNumber: 5,
          topics: [],
        ),
      ],
    ),
  };

  // Supplied topic titles per static world, in authoritative order.
  // Unit assignment is positional (round-robin by unit capacity is avoided;
  // explicit slices keep the mapping reviewable and deterministic).
  static const Map<WorldId, List<String>> _suppliedTopics = {
    WorldId.algorithms: [
      'Fundamentals of Algorithm',
      'Analysis of Algorithms',
      'Exhaustive Search',
      'Divide and Conquer',
      'Dynamic Programming',
      'Greedy Technique',
      'Iterative Improvement',
      'Limitations of Algorithm Power',
      'NP / NP-Complete / NP-Hard',
      'Problem Reduction',
      'Backtracking',
      'Branch and Bound',
      'Approximation Algorithms',
    ],
    WorldId.dbms: [
      'Database System Concepts',
      'Architecture',
      'Data Models',
      'ER Modeling',
      'Relational Database Design',
      'SQL',
      'Relational Algebra',
      'Normalization',
      'Functional Dependencies',
      'Query Processing',
      'Transaction Processing',
      'Concurrency Control',
      'Indexing',
      'Physical Database Design',
      'Distributed Storage',
      'NoSQL / MongoDB',
    ],
    WorldId.dataScience: [
      'Introduction to Data Science',
      'Data Description',
      'Relationships',
      'Correlation',
      'Regression',
      'NumPy',
      'Pandas',
      'Data Wrangling',
      'Matplotlib',
      'Visualization',
      'Seaborn',
      'Geographic Data',
    ],
    WorldId.operatingSystems: [
      'OS Structure and Services',
      'Processes',
      'Process Scheduling',
      'Threads',
      'Process Synchronization',
      'Deadlocks',
      'Memory Management',
      'Paging',
      'Segmentation',
      'Virtual Memory',
      'Page Replacement',
      'Storage Management',
      'File Systems',
      'Disk Scheduling',
      'I/O Systems',
    ],
    WorldId.oop: [
      'Java fundamentals',
      'Variables/types/operators',
      'Control structures',
      'Classes and objects',
      'Constructors',
      'Inheritance',
      'Polymorphism',
      'Abstraction',
      'Interfaces',
      'Packages',
      'Exception Handling',
      'Multithreading',
      'Collections',
      'Strings',
      'I/O Streams',
      'JavaFX',
      'JDBC',
    ],
    WorldId.dataStructures: [
      'Lists',
      'Linked Lists',
      'Circular Linked Lists',
      'Doubly Linked Lists',
      'Stacks',
      'Queues',
      'Circular Queue',
      'Deque',
      'Trees',
      'Binary Trees',
      'Binary Search Trees',
      'AVL Trees',
      'Heaps / Priority Queue',
      'Graphs',
      'BFS',
      'DFS',
      'Shortest Path',
      'Minimum Spanning Tree',
      'Sorting',
      'Hashing',
    ],
    WorldId.computerNetworks: [
      'Introduction',
      'Physical Layer',
      'OSI',
      'TCP/IP',
      'Transmission Media',
      'Switching',
      'Data Link Layer',
      'Framing',
      'Error Detection',
      'Error Correction',
      'Flow Control',
      'ARQ',
      'ALOHA',
      'CSMA/CD',
      'Ethernet',
      'Network Layer',
      'IPv4',
      'IPv6',
      'Subnetting',
      'Routing',
      'RIP',
      'OSPF',
      'Congestion Control',
      'ICMP',
      'Transport Layer',
      'UDP',
      'TCP',
      'Port Addressing',
      'Socket Programming',
      'QoS',
      'Application Layer',
      'HTTP',
      'FTP',
      'SMTP',
      'DNS',
      'WLAN',
      'Bluetooth',
      'Wi-Fi',
    ],
  };

  // Explicit per-world unit slices (counts must sum to the topic list length).
  // Kept as data so reviewers can verify unit boundaries at a glance.
  static const Map<WorldId, List<int>> _unitSlices = {
    WorldId.algorithms: [2, 2, 3, 3, 3],
    WorldId.dbms: [3, 2, 4, 3, 4],
    WorldId.dataScience: [2, 3, 3, 4],
    WorldId.operatingSystems: [4, 2, 5, 4],
    WorldId.oop: [3, 3, 3, 3, 5],
    WorldId.dataStructures: [4, 4, 5, 5, 2],
    WorldId.computerNetworks: [6, 9, 9, 6, 8],
  };

  /// Build the fully populated syllabus for [worldId].
  /// Worlds with supplied static material return ordered units. The
  /// backend-driven Programming world returns an empty [SyllabusSource.backend]
  /// syllabus (structure arrives via backend responses at runtime). Worlds
  /// without any authoritative source return [SyllabusSource.pending].
  static WorldSyllabus of(WorldId worldId) {
    final shell = _all[worldId];
    if (shell == null) {
      final def = WorldCatalog.byId(worldId);
      if (def?.syllabusSource == SyllabusSource.backend) {
        return WorldSyllabus(
          worldId: worldId,
          units: const [],
          source: SyllabusSource.backend,
        );
      }
      return WorldSyllabus(
        worldId: worldId,
        units: const [],
        source: SyllabusSource.pending,
      );
    }
    final titles = _suppliedTopics[worldId];
    if (titles == null || titles.isEmpty) {
      return WorldSyllabus(
        worldId: worldId,
        units: const [],
        source: SyllabusSource.pending,
      );
    }
    final slices = _unitSlices[worldId]!;
    assert(
      slices.fold(0, (a, b) => a + b) == titles.length,
      'Unit slices must cover all supplied topics for $worldId',
    );
    var cursor = 0;
    var order = 1;
    final units = <SyllabusUnit>[];
    for (var u = 0; u < shell.units.length; u++) {
      final take = slices[u];
      final topics = <SyllabusTopic>[];
      for (var i = 0; i < take; i++) {
        final title = titles[cursor++];
        topics.add(_t(worldId, 't$order', title, order));
        order++;
      }
      final s = shell.units[u];
      units.add(
        SyllabusUnit(
          id: s.id,
          worldId: s.worldId,
          title: s.title,
          unitNumber: s.unitNumber,
          topics: topics,
        ),
      );
    }
    return WorldSyllabus(
      worldId: worldId,
      units: units,
      source: shell.source,
    );
  }

  /// All populated static syllabi (7 worlds). Pending worlds excluded.
  static List<WorldSyllabus> allStatic() =>
      staticWorlds.map(of).toList(growable: false);

  /// Every world id → syllabus (pending worlds yield empty syllabi).
  static List<WorldSyllabus> allWorlds() =>
      WorldId.values.map(of).toList(growable: false);
}

/// Syllabus for one world (populated, deterministic). Null never returned —
/// pending worlds yield an empty syllabus (check [WorldSyllabus.isPending]).
final syllabusProvider =
    Provider.family<WorldSyllabus, WorldId>((ref, worldId) {
  return WorldSyllabusCatalog.of(worldId);
});

/// All static syllabi (7 worlds with supplied material).
final allSyllabiProvider = Provider<List<WorldSyllabus>>((ref) {
  return WorldSyllabusCatalog.allStatic();
});
