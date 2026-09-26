import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../domain/learning_realm.dart';

/// Backend realm DTO (REALM-001). The backend owns identity and
/// availability; the frontend owns presentation. Field-for-field with
/// `RealmResponse`; unknown JSON is ignored defensively.
class BackendRealm {
  const BackendRealm({
    required this.id,
    required this.realmKey,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.isActive,
    required this.displayOrder,
  });

  final String id;
  final String realmKey;
  final String name;
  final String description;
  final String iconKey;
  final bool isActive;
  final int displayOrder;

  factory BackendRealm.fromJson(Map<String, dynamic> json) => BackendRealm(
    id: (json['id'] as String?) ?? '',
    realmKey: (json['realmKey'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    iconKey: (json['iconKey'] as String?) ?? '',
    isActive: json['isActive'] as bool? ?? true,
    displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
  );
}

/// Backend realm merged with frontend presentation metadata.
///
/// Resolution is key-driven: a backend realm whose key matches a
/// [RealmId] inherits that realm's icon/accent/scene/structure.
/// Unknown keys receive a neutral generic treatment (never invented
/// content, never a crash). Frontend-only coming-soon entries that
/// the backend does not list stay as static placeholders.
class ResolvedRealm {
  const ResolvedRealm({
    required this.backend,
    required this.visual,
    required this.icon,
    required this.accent,
    required this.scene,
    required this.structure,
  });

  final BackendRealm backend;
  final LearningRealm? visual;
  final IconData icon;
  final Color accent;
  final ScenePalette scene;
  final RealmLearningStructure structure;

  /// Backend is authoritative for existence; frontend catalog only
  /// supplies presentation. Unknown keys fall back to generic visuals.
  factory ResolvedRealm.resolve(BackendRealm backend) {
    final id = RealmId.fromKey(backend.realmKey);
    final visual = id == null ? null : LearningRealmCatalog.byId(id);
    if (visual != null) {
      return ResolvedRealm(
        backend: backend,
        visual: visual,
        icon: visual.icon,
        accent: visual.accent,
        scene: visual.scene,
        structure: visual.structure,
      );
    }
    return ResolvedRealm(
      backend: backend,
      visual: null,
      icon: Icons.public_rounded,
      accent: AppColors.primary,
      scene: ScenePalette.abyss,
      structure: RealmLearningStructure.domainBased,
    );
  }

  bool get isWorldBased =>
      backend.isActive && structure == RealmLearningStructure.worldBased;
}
