import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cinematic_scenery.dart';

/// Learning-realm domain — the ONE authoritative source for top-level
/// learning-domain identity in the frontend.
///
/// ## Architecture position (additive, never a rewrite)
///
/// ```text
/// LearningRealm (this file — new layer)
///       ↓
/// Computer Science ──references──▶ WorldCatalog (existing 11 worlds)
///       ↓
/// WorldDefinition / WorldSyllabus / WorldContext (untouched)
///       ↓
/// Topic / Game / Result / Progress flow (untouched)
/// ```
///
/// ## Non-negotiable domain rules
/// - Every realm has an immutable stable [RealmId]. Display names are
///   presentation-layer only and MUST never be used as IDs.
/// - There is exactly ONE realm registry: [LearningRealmCatalog]. Do NOT
///   create parallel realm lists in dashboard / shell / analytics.
/// - Computer Science does NOT duplicate worlds: it is a pointer to the
///   existing [WorldCatalog]. World counts shown in UI MUST be derived
///   from `WorldCatalog.all.length` at the call site, never hardcoded
///   in this file (this file stays backend/world-agnostic on purpose).
/// - Future realms are Coming Soon placeholders: no lesson counts, no
///   progress, no XP, no mastery, no questions. UI MUST render them
///   truthfully (locked + dialog), never fabricated content.

/// Stable immutable realm identity. Never rename values; only append.
enum RealmId {
  computerScience('COMPUTER_SCIENCE'),
  aptitude('APTITUDE'),
  verbalEnglish('VERBAL_ENGLISH'),
  fullStack('FULL_STACK'),
  aiData('AI_DATA'),
  cyberSecurity('CYBER_SECURITY');

  const RealmId(this.key);
  final String key;

  static RealmId? fromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final normalized = key.trim().toUpperCase();
    for (final r in RealmId.values) {
      if (r.key == normalized) return r;
    }
    return null;
  }
}

/// Availability of a realm's learning material.
enum RealmAvailability {
  /// Fully navigable — resolves into the existing world experience.
  active,
  /// Announced but without content — honest locked placeholder only.
  comingSoon,
}

/// Internal learning structure of a realm — how a realm organizes its
/// learnable content below the realm level.
///
/// This is a *declaration*, not an implementation: only [worldBased]
/// has a backing implementation today ([WorldCatalog]). Every other
/// value is a planned capability describing where that realm's future
/// content source must plug in. Values are append-only; never rename.
enum RealmLearningStructure {
  /// Content organized as Worlds (see [WorldCatalog]).
  /// The ONLY implemented structure. Reserved for Computer Science
  /// until a backend-owned alternative exists.
  worldBased,
  /// Content organized as Skills → Question Types (planned: Aptitude,
  /// Verbal & English). No implementation yet.
  skillBased,
  /// Content organized as Technologies → Topics (planned: Full Stack
  /// Development). No implementation yet.
  technologyBased,
  /// Content organized as Domains → Topics (planned: AI & Data,
  /// Cyber Security). No implementation yet.
  domainBased,
}

/// First-class realm definition. Presentation tokens reuse the existing
/// design system ([AppColors], [ScenePalette]) — no second system.
class LearningRealm {
  const LearningRealm({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.accent,
    required this.scene,
    required this.availability,
    required this.structure,
    this.displayOrder = 0,
  });

  final RealmId id;
  String get key => id.key;
  final String title;
  final String tagline;
  final String description;
  final IconData icon;
  final Color accent;
  final ScenePalette scene;
  final RealmAvailability availability;
  /// How this realm organizes content below itself. Only [worldBased]
  /// is implemented; all other values are planned capabilities.
  final RealmLearningStructure structure;
  final int displayOrder;

  bool get isActive => availability == RealmAvailability.active;
  bool get isComingSoon => availability == RealmAvailability.comingSoon;

  /// True only for the implemented world-backed path. Future
  /// structures MUST NOT be treated as world-backed anywhere.
  bool get isWorldBased =>
      isActive && structure == RealmLearningStructure.worldBased;
}

/// The single authoritative realm registry, in canonical display order.
/// Computer Science is the only ACTIVE realm; everything else is an
/// honest Coming Soon placeholder with zero fabricated metrics.
abstract final class LearningRealmCatalog {
  static const List<LearningRealm> all = [
    LearningRealm(
      id: RealmId.computerScience,
      title: 'Computer Science',
      tagline: 'Code. Systems. Intelligence.',
      description:
          'The complete Computer Science universe — programming, systems, data and AI worlds, all in one realm.',
      icon: Icons.memory_rounded,
      accent: AppColors.primary,
      scene: ScenePalette.violet,
      availability: RealmAvailability.active,
      structure: RealmLearningStructure.worldBased,
      displayOrder: 1,
    ),
    LearningRealm(
      id: RealmId.aptitude,
      title: 'Aptitude',
      tagline: 'Logic. Speed. Precision.',
      description:
          'Quantitative aptitude and logical reasoning — arriving as a future realm.',
      icon: Icons.calculate_rounded,
      accent: AppColors.secondary,
      scene: ScenePalette.abyss,
      availability: RealmAvailability.comingSoon,
      structure: RealmLearningStructure.skillBased,
      displayOrder: 2,
    ),
    LearningRealm(
      id: RealmId.verbalEnglish,
      title: 'Verbal & English',
      tagline: 'Words. Clarity. Expression.',
      description:
          'Verbal ability, grammar and communication — arriving as a future realm.',
      icon: Icons.forum_rounded,
      accent: AppColors.success,
      scene: ScenePalette.verdant,
      availability: RealmAvailability.comingSoon,
      structure: RealmLearningStructure.skillBased,
      displayOrder: 3,
    ),
    LearningRealm(
      id: RealmId.fullStack,
      title: 'Full Stack Development',
      tagline: 'Frontend. Backend. Ship it.',
      description:
          'End-to-end product engineering — arriving as a future realm.',
      icon: Icons.layers_rounded,
      accent: AppColors.xp,
      scene: ScenePalette.ember,
      availability: RealmAvailability.comingSoon,
      structure: RealmLearningStructure.technologyBased,
      displayOrder: 4,
    ),
    LearningRealm(
      id: RealmId.aiData,
      title: 'AI & Data',
      tagline: 'Models. Data. Insight.',
      description:
          'Machine learning and data engineering depth — arriving as a future realm.',
      icon: Icons.psychology_rounded,
      accent: AppColors.streak,
      scene: ScenePalette.indigo,
      availability: RealmAvailability.comingSoon,
      structure: RealmLearningStructure.domainBased,
      displayOrder: 5,
    ),
    LearningRealm(
      id: RealmId.cyberSecurity,
      title: 'Cyber Security',
      tagline: 'Defend. Detect. Prevail.',
      description:
          'Security fundamentals and defense — arriving as a future realm.',
      icon: Icons.security_rounded,
      accent: AppColors.warning,
      scene: ScenePalette.slate,
      availability: RealmAvailability.comingSoon,
      structure: RealmLearningStructure.domainBased,
      displayOrder: 6,
    ),
  ];

  /// The only navigable realm. Resolves into the existing world catalog.
  static LearningRealm get computerScience =>
      all.firstWhere((r) => r.id == RealmId.computerScience);

  /// Realms beyond the active set, shown as locked placeholders.
  /// Dashboard teaser copy derives from here — never hard-coded.
  static int get comingSoonCount =>
      all.where((r) => r.isComingSoon).length;

  static LearningRealm? byId(RealmId id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }
}
