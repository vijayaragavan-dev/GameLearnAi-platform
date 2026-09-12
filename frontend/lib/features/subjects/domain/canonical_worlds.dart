import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/models/content_models.dart';

/// Canonical learning-world domain — the ONE authoritative source for world
/// identity across the frontend.
///
/// ## Non-negotiable domain rules (product requirement)
/// - Every world has an immutable stable [WorldId] + [WorldKey]. Display
///   names are presentation-layer only and MUST never be used as IDs.
/// - There is exactly ONE world catalogue: [WorldCatalog]. Do NOT create
///   parallel subject lists in dashboard / learning-path / game-zone / tutor /
///   analytics — those screens consume this catalogue (or the backend
///   [Subject] mapped through it).
/// - Content isolation: a subject-world game/topic/path MUST only show that
///   world's content. Mixed content is allowed ONLY in the Global Game Arena
///   (see [WorldScope]).
///
/// ## Backend compatibility
/// Backend [Subject] objects remain authoritative for persistence (UUID ids,
/// mastery, paths, tutor context). [WorldCatalog.resolveSubject] maps any
/// backend [Subject] to its canonical [WorldId] via iconKey/name heuristics
/// without changing API contracts. Unknown backend subjects resolve to null
/// (caller falls back to generic presentation) — never throws.

/// Stable immutable world identity. Never rename values; only append.
enum WorldId {
  programming('PROGRAMMING'),
  dataStructures('DATA_STRUCTURES'),
  algorithms('ALGORITHMS'),
  dbms('DBMS'),
  computerNetworks('COMPUTER_NETWORKS'),
  operatingSystems('OPERATING_SYSTEMS'),
  oop('OOP'),
  aiMl('AI_ML'),
  dataScience('DATA_SCIENCE'),
  webTechnologies('WEB_TECHNOLOGIES'),
  oose('OBJECT_ORIENTED_SOFTWARE_ENGINEERING');

  const WorldId(this.key);
  final String key;

  static WorldId? fromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final normalized = key.trim().toUpperCase();
    for (final w in WorldId.values) {
      if (w.key == normalized) return w;
    }
    return null;
  }
}

/// Content-scope distinction: isolated subject-world vs mixed global arena.
enum WorldScope {
  /// Single-world content only. Questions, topics, mastery, tutor context,
  /// recommendations MUST belong to that world.
  subjectIsolated,
  /// Mixed content from multiple worlds explicitly allowed.
  /// Only the Global Game Arena may use this scope.
  globalArena,
}

/// Availability of a world's learning material in the frontend.
enum WorldAvailability {
  /// Fully available (backend + frontend presentation ready).
  available,
  /// Backend-driven; frontend presents whatever the backend returns.
  backendDriven,
  /// Architecture ready; detailed syllabus pending backend/content source.
  /// UI MUST render this truthfully (EmptyState), never fabricated content.
  comingSoon,
}

/// Syllabus source backing a world's structure (see world_syllabus.dart).
enum SyllabusSource {
  /// Deterministic static frontend structure (extends backend, never replaces).
  staticCatalog,
  /// Structure comes from backend responses only.
  backend,
  /// No authoritative source yet — architecture only.
  pending,
}

/// First-class world definition. Presentation tokens reuse the existing
/// design system ([AppColors], [AppGradients]) — no second design system.
class WorldDefinition {
  const WorldDefinition({
    required this.id,
    required this.displayName,
    required this.shortName,
    required this.description,
    required this.tagline,
    required this.icon,
    required this.accent,
    required this.atmosphereColor,
    required this.gradient,
    required this.motif,
    required this.iconKeys,
    required this.nameHints,
    required this.availability,
    required this.syllabusSource,
    this.prerequisites = const [],
    this.difficulty = 'MIXED',
    this.displayOrder = 0,
  });

  final WorldId id;
  String get key => id.key;
  final String displayName;
  final String shortName;
  final String description;
  final String tagline;
  final IconData icon;
  final Color accent;
  final Color atmosphereColor;
  final LinearGradient gradient;
  final String motif;

  /// Backend [Subject.iconKey] spellings that map to this world.
  final List<String> iconKeys;

  /// Lowercase name fragments used to resolve backend subjects by name.
  final List<String> nameHints;
  final WorldAvailability availability;
  final SyllabusSource syllabusSource;
  final List<WorldId> prerequisites;
  final String difficulty;
  final int displayOrder;

  WorldScope get scope => WorldScope.subjectIsolated;
}

/// The single authoritative 11-world catalogue, in canonical display order.
abstract final class WorldCatalog {
  static const List<WorldDefinition> all = [
    WorldDefinition(
      id: WorldId.programming,
      displayName: 'Programming',
      shortName: 'Code',
      description:
          'Programming fundamentals across C, C++, Java, Python and JavaScript — one world, many languages.',
      tagline: 'Write code. Think clearly.',
      icon: Icons.code_rounded,
      accent: Color(0xFF818CF8),
      atmosphereColor: Color(0xFF4338CA),
      gradient: AppGradients.worldProgramming,
      motif: 'code_matrix',
      iconKeys: ['code', 'programming', 'subject_programming'],
      nameHints: ['programming', 'coding', 'code'],
      availability: WorldAvailability.backendDriven,
      syllabusSource: SyllabusSource.backend,
      difficulty: 'MIXED',
      displayOrder: 1,
    ),
    WorldDefinition(
      id: WorldId.dataStructures,
      displayName: 'Data Structures',
      shortName: 'DS',
      description:
          'Lists, stacks, queues, trees, graphs, sorting and hashing — the vocabulary of efficient programs.',
      tagline: 'Structure data. Master performance.',
      icon: Icons.account_tree_rounded,
      accent: Color(0xFF34D399),
      atmosphereColor: Color(0xFF059669),
      gradient: AppGradients.worldDataStructures,
      motif: 'tree_graph',
      iconKeys: ['data_structures', 'dsa', 'ds', 'subject_ds'],
      nameHints: ['data structure'],
      availability: WorldAvailability.available,
      syllabusSource: SyllabusSource.staticCatalog,
      difficulty: 'MIXED',
      displayOrder: 2,
    ),
    WorldDefinition(
      id: WorldId.algorithms,
      displayName: 'Algorithms',
      shortName: 'Algo',
      description:
          'Design paradigms and analysis — from brute force to dynamic programming, NP theory and approximation.',
      tagline: 'Design. Analyze. Optimize.',
      icon: Icons.functions_rounded,
      accent: Color(0xFFA78BFA),
      atmosphereColor: Color(0xFF7C3AED),
      gradient: AppGradients.worldAlgorithms,
      motif: 'flow_chart',
      iconKeys: ['algorithms', 'algo', 'subject_algorithms'],
      nameHints: ['algorithm'],
      availability: WorldAvailability.available,
      syllabusSource: SyllabusSource.staticCatalog,
      prerequisites: [WorldId.dataStructures],
      difficulty: 'ADVANCED',
      displayOrder: 3,
    ),
    WorldDefinition(
      id: WorldId.dbms,
      displayName: 'Database Management Systems',
      shortName: 'DBMS',
      description:
          'From ER modeling and SQL to normalization, transactions, indexing and NoSQL.',
      tagline: 'Model data. Query anything.',
      icon: Icons.storage_rounded,
      accent: Color(0xFFFB923C),
      atmosphereColor: Color(0xFFEA580C),
      gradient: AppGradients.worldDatabase,
      motif: 'data_vault',
      iconKeys: ['database', 'dbms', 'sql', 'subject_dbms', 'subject_database'],
      nameHints: ['database', 'dbms', 'sql'],
      availability: WorldAvailability.available,
      syllabusSource: SyllabusSource.staticCatalog,
      difficulty: 'MIXED',
      displayOrder: 4,
    ),
    WorldDefinition(
      id: WorldId.computerNetworks,
      displayName: 'Computer Networks',
      shortName: 'Nets',
      description:
          'From physical media and Ethernet to IP, routing, TCP and application protocols.',
      tagline: 'Connect everything.',
      icon: Icons.hub_rounded,
      accent: Color(0xFF38BDF8),
      atmosphereColor: Color(0xFF0EA5E9),
      gradient: AppGradients.worldNetworks,
      motif: 'signal_grid',
      iconKeys: ['network', 'computer_networks', 'networks', 'subject_networks'],
      nameHints: ['network'],
      availability: WorldAvailability.available,
      syllabusSource: SyllabusSource.staticCatalog,
      difficulty: 'MIXED',
      displayOrder: 5,
    ),
    WorldDefinition(
      id: WorldId.operatingSystems,
      displayName: 'Operating Systems',
      shortName: 'OS',
      description:
          'Processes, scheduling, synchronization, memory, paging and file systems.',
      tagline: 'Command the machine.',
      icon: Icons.developer_board_rounded,
      accent: Color(0xFF94A3B8),
      atmosphereColor: Color(0xFF64748B),
      gradient: AppGradients.worldOS,
      motif: 'system_core',
      iconKeys: ['os', 'operating_systems', 'subject_os'],
      nameHints: ['operating system'],
      availability: WorldAvailability.available,
      syllabusSource: SyllabusSource.staticCatalog,
      difficulty: 'MIXED',
      displayOrder: 6,
    ),
    WorldDefinition(
      id: WorldId.oop,
      displayName: 'Object-Oriented Programming',
      shortName: 'OOP',
      description:
          'Classes, inheritance, polymorphism and design through Java — from basics to JDBC.',
      tagline: 'Model the world in objects.',
      icon: Icons.class_rounded,
      accent: AppColors.secondary,
      atmosphereColor: AppColors.secondaryDeep,
      gradient: AppGradients.worldOOP,
      motif: 'object_graph',
      iconKeys: ['oop', 'java', 'subject_oop'],
      nameHints: ['object-oriented programming', 'object oriented', 'java', ' oop'],
      availability: WorldAvailability.available,
      syllabusSource: SyllabusSource.staticCatalog,
      prerequisites: [WorldId.programming],
      difficulty: 'MIXED',
      displayOrder: 7,
    ),
    WorldDefinition(
      id: WorldId.aiMl,
      displayName: 'Artificial Intelligence & Machine Learning',
      shortName: 'AI/ML',
      description:
          'A growing world for intelligent systems. Detailed syllabus arrives with the content backend.',
      tagline: 'Learn how machines learn.',
      icon: Icons.psychology_rounded,
      accent: Color(0xFFF472B6),
      atmosphereColor: Color(0xFFBE185D),
      gradient: AppGradients.worldAIML,
      motif: 'neural_net',
      iconKeys: ['ai_ml', 'ai', 'ml', 'subject_ai_ml'],
      nameHints: ['artificial intelligence', 'machine learning', 'ai & ml', 'ai/ml'],
      availability: WorldAvailability.comingSoon,
      syllabusSource: SyllabusSource.pending,
      prerequisites: [WorldId.algorithms, WorldId.dataScience],
      difficulty: 'ADVANCED',
      displayOrder: 8,
    ),
    WorldDefinition(
      id: WorldId.dataScience,
      displayName: 'Data Science',
      shortName: 'DSci',
      description:
          'Describe, relate and visualize data — from correlation and regression to NumPy, Pandas and Seaborn.',
      tagline: 'Ask data. Get answers.',
      icon: Icons.analytics_rounded,
      accent: Color(0xFF2DD4BF),
      atmosphereColor: Color(0xFF0F766E),
      gradient: AppGradients.worldDataScience,
      motif: 'data_canvas',
      iconKeys: ['data_science', 'datascience', 'subject_data_science'],
      nameHints: ['data science'],
      availability: WorldAvailability.available,
      syllabusSource: SyllabusSource.staticCatalog,
      difficulty: 'MIXED',
      displayOrder: 9,
    ),
    WorldDefinition(
      id: WorldId.webTechnologies,
      displayName: 'Web Technologies',
      shortName: 'Web',
      description:
          'A growing world for the modern web. Detailed syllabus arrives with the content backend.',
      tagline: 'Build for the browser.',
      icon: Icons.language_rounded,
      accent: Color(0xFF60A5FA),
      atmosphereColor: Color(0xFF1D4ED8),
      gradient: AppGradients.worldWeb,
      motif: 'browser_grid',
      iconKeys: ['web', 'web_technologies', 'subject_web'],
      nameHints: ['web technolog', 'web development', 'html', 'frontend'],
      availability: WorldAvailability.comingSoon,
      syllabusSource: SyllabusSource.pending,
      prerequisites: [WorldId.programming],
      difficulty: 'MIXED',
      displayOrder: 10,
    ),
    WorldDefinition(
      id: WorldId.oose,
      displayName: 'Object-Oriented Software Engineering',
      shortName: 'OOSE',
      description:
          'A growing world for engineering software with objects. Detailed syllabus arrives with the content backend.',
      tagline: 'Engineer software that lasts.',
      icon: Icons.architecture_rounded,
      accent: AppColors.warning,
      atmosphereColor: Color(0xFF92400E),
      gradient: AppGradients.worldOOSE,
      motif: 'blueprint_stack',
      iconKeys: ['oose', 'software_engineering', 'subject_oose'],
      nameHints: [
        'object-oriented software engineering',
        'object oriented software',
        'software engineering',
      ],
      availability: WorldAvailability.comingSoon,
      syllabusSource: SyllabusSource.pending,
      prerequisites: [WorldId.oop],
      difficulty: 'ADVANCED',
      displayOrder: 11,
    ),
  ];

  /// Lookup by stable [WorldId]. Never throws.
  static WorldDefinition? byId(WorldId? id) {
    if (id == null) return null;
    for (final w in all) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Lookup by stable key (e.g. "ALGORITHMS"). Case-insensitive. Null on miss.
  static WorldDefinition? byKey(String? key) {
    final id = WorldId.fromKey(key);
    return byId(id);
  }

  /// Resolve a backend [Subject] to its canonical world. Null when unknown —
  /// caller MUST fall back to generic presentation (never fabricate identity).
  ///
  /// Matching is two-pass and order-independent: exact alias matches across
  /// ALL worlds win first; only then are partial (compound-key) matches
  /// considered, preferring the longest alias for specificity.
  static WorldDefinition? resolveSubject(Subject subject) {
    final iconKey = subject.iconKey.toLowerCase().trim();
    if (iconKey.isNotEmpty) {
      for (final w in all) {
        for (final alias in w.iconKeys) {
          if (alias.toLowerCase() == iconKey) return w;
        }
      }
      WorldDefinition? best;
      var bestLen = -1;
      for (final w in all) {
        for (final alias in w.iconKeys) {
          final a = alias.toLowerCase();
          if ((iconKey.contains(a) || a.contains(iconKey)) &&
              a.length > bestLen) {
            best = w;
            bestLen = a.length;
          }
        }
      }
      if (best != null) return best;
    }
    final haystack = '${subject.name} ${subject.description}'.toLowerCase();
    WorldDefinition? best;
    var bestLen = 0;
    for (final w in all) {
      for (final hint in w.nameHints) {
        if (haystack.contains(hint) && hint.length > bestLen) {
          best = w;
          bestLen = hint.length;
        }
      }
    }
    return best;
  }

  /// Resolve by display name (presentation helper only — never use as ID).
  static WorldDefinition? resolveDisplayName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return null;
    WorldDefinition? best;
    var bestLen = 0;
    for (final w in all) {
      if (w.displayName.toLowerCase() == lower) return w;
      for (final hint in [...w.nameHints, w.displayName.toLowerCase()]) {
        if (lower.contains(hint) && hint.length > bestLen) {
          best = w;
          bestLen = hint.length;
        }
      }
    }
    return best;
  }

  /// Deterministic ordering by [WorldDefinition.displayOrder].
  static List<WorldDefinition> ordered() =>
      [...all]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  /// The 5 legacy worlds that predate the 11-world expansion. Used only for
  /// backwards-compatibility assertions — never gate features on this list.
  static const Set<WorldId> legacyFive = {
    WorldId.programming,
    WorldId.dataStructures,
    WorldId.dbms,
    WorldId.computerNetworks,
    WorldId.operatingSystems,
  };

  /// True when [topicSubjectName] belongs to [world]'s content scope.
  /// Presentation names are compared via canonical resolution so display
  /// renames never break isolation. The Global Arena bypasses this by using
  /// [WorldScope.globalArena] explicitly.
  static bool topicBelongsToWorld({
    required WorldDefinition world,
    required String topicSubjectName,
    WorldScope scope = WorldScope.subjectIsolated,
  }) {
    if (scope == WorldScope.globalArena) return true;
    if (topicSubjectName.trim().isEmpty) return false;
    final resolved = resolveDisplayName(topicSubjectName);
    return resolved?.id == world.id;
  }
}

// ── Providers: single consumption point for UI ─────────────────────────────

/// All 11 canonical worlds, deterministically ordered.
final canonicalWorldsProvider = Provider<List<WorldDefinition>>((ref) {
  return WorldCatalog.ordered();
});

/// Lookup one world by stable id. Null for unknown — render EmptyState.
final worldByIdProvider =
    Provider.family<WorldDefinition?, WorldId?>((ref, id) {
  return WorldCatalog.byId(id);
});

/// Resolve a backend subject to its canonical world (null when unmapped).
final worldForSubjectProvider =
    Provider.family<WorldDefinition?, Subject>((ref, subject) {
  return WorldCatalog.resolveSubject(subject);
});
