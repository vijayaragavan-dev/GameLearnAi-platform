import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_styles.dart';

/// Visual identity for a subject/world.
///
/// Subjects come from the backend as [Subject] objects with an [iconKey] field.
/// This mapping layer translates that key into a premium visual identity.
///
/// Safe: Always falls back to [SubjectVisualRegistry.fallback] for unknown keys.
/// Never breaks or throws — unmapped subjects get a neutral premium style.
class SubjectVisualIdentity {
  const SubjectVisualIdentity({
    required this.iconKey,
    required this.displayName,
    required this.accent,
    required this.atmosphereColor,
    required this.gradient,
    required this.icon,
    required this.motif,
  });

  /// The backend iconKey this identity maps to.
  final String iconKey;

  /// Human-readable display name for this world.
  final String displayName;

  /// Primary accent color — used for card borders, glow, progress.
  final Color accent;

  /// Atmospheric ambient color — used for background glow orbs.
  final Color atmosphereColor;

  /// Background gradient for subject/world cards.
  final LinearGradient gradient;

  /// Icon representing this subject.
  final IconData icon;

  /// Visual motif descriptor — for artwork and decoration slots.
  final String motif;

  /// Surface tint for cards in this subject's context.
  Color surfaceTint({bool dark = true}) =>
      accent.withValues(alpha: dark ? 0.08 : 0.04);

  /// Border color for subject cards.
  Color borderColor({bool dark = true}) =>
      accent.withValues(alpha: dark ? 0.32 : 0.18);

  /// Glow shadow for featured subject content.
  List<BoxShadow> glowShadow({bool dark = true}) => [
    BoxShadow(
      color: accent.withValues(alpha: dark ? 0.30 : 0.12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
}

/// Registry of subject visual identities, keyed by backend [Subject.iconKey].
///
/// Usage:
///   final identity = SubjectVisualRegistry.fromIconKey(subject.iconKey);
///   Container(decoration: BoxDecoration(gradient: identity.gradient, ...))
abstract final class SubjectVisualRegistry {
  // ── Defined subject identities ────────────────────────────────────────────

  static const SubjectVisualIdentity _programming = SubjectVisualIdentity(
    iconKey: 'code',
    displayName: 'Programming',
    accent: Color(0xFF818CF8), // indigo-400
    atmosphereColor: Color(0xFF4338CA),
    gradient: AppGradients.worldProgramming,
    icon: Icons.code_rounded,
    motif: 'code_matrix',
  );

  static const SubjectVisualIdentity _networks = SubjectVisualIdentity(
    iconKey: 'network',
    displayName: 'Computer Networks',
    accent: Color(0xFF38BDF8), // sky-400
    atmosphereColor: Color(0xFF0EA5E9),
    gradient: AppGradients.worldNetworks,
    icon: Icons.hub_rounded,
    motif: 'signal_grid',
  );

  static const SubjectVisualIdentity _dbms = SubjectVisualIdentity(
    iconKey: 'database',
    displayName: 'Database Systems',
    accent: Color(0xFFFB923C), // orange-400
    atmosphereColor: Color(0xFFEA580C),
    gradient: AppGradients.worldDatabase,
    icon: Icons.storage_rounded,
    motif: 'data_vault',
  );

  static const SubjectVisualIdentity _os = SubjectVisualIdentity(
    iconKey: 'os',
    displayName: 'Operating Systems',
    accent: Color(0xFF94A3B8), // slate-400
    atmosphereColor: Color(0xFF64748B),
    gradient: AppGradients.worldOS,
    icon: Icons.developer_board_rounded,
    motif: 'system_core',
  );

  static const SubjectVisualIdentity _dataStructures = SubjectVisualIdentity(
    iconKey: 'data_structures',
    displayName: 'Data Structures',
    accent: Color(0xFF34D399), // emerald-400
    atmosphereColor: Color(0xFF059669),
    gradient: AppGradients.worldDataStructures,
    icon: Icons.account_tree_rounded,
    motif: 'tree_graph',
  );

  // Alternate iconKey spellings (backend may vary)
  static const SubjectVisualIdentity _programmingAlt = SubjectVisualIdentity(
    iconKey: 'programming',
    displayName: 'Programming',
    accent: Color(0xFF818CF8),
    atmosphereColor: Color(0xFF4338CA),
    gradient: AppGradients.worldProgramming,
    icon: Icons.code_rounded,
    motif: 'code_matrix',
  );

  static const SubjectVisualIdentity _networksAlt = SubjectVisualIdentity(
    iconKey: 'computer_networks',
    displayName: 'Computer Networks',
    accent: Color(0xFF38BDF8),
    atmosphereColor: Color(0xFF0EA5E9),
    gradient: AppGradients.worldNetworks,
    icon: Icons.hub_rounded,
    motif: 'signal_grid',
  );

  static const SubjectVisualIdentity _dbmsAlt = SubjectVisualIdentity(
    iconKey: 'dbms',
    displayName: 'Database Systems',
    accent: Color(0xFFFB923C),
    atmosphereColor: Color(0xFFEA580C),
    gradient: AppGradients.worldDatabase,
    icon: Icons.storage_rounded,
    motif: 'data_vault',
  );

  static const SubjectVisualIdentity _osAlt = SubjectVisualIdentity(
    iconKey: 'operating_systems',
    displayName: 'Operating Systems',
    accent: Color(0xFF94A3B8),
    atmosphereColor: Color(0xFF64748B),
    gradient: AppGradients.worldOS,
    icon: Icons.developer_board_rounded,
    motif: 'system_core',
  );

  static const SubjectVisualIdentity _dsaAlt = SubjectVisualIdentity(
    iconKey: 'dsa',
    displayName: 'Data Structures & Algorithms',
    accent: Color(0xFF34D399),
    atmosphereColor: Color(0xFF059669),
    gradient: AppGradients.worldDataStructures,
    icon: Icons.account_tree_rounded,
    motif: 'tree_graph',
  );

  /// Fallback — neutral premium style for unmapped subjects.
  static const SubjectVisualIdentity fallback = SubjectVisualIdentity(
    iconKey: 'default',
    displayName: 'Learning World',
    accent: AppColors.primary,
    atmosphereColor: AppColors.primaryDeep,
    gradient: AppGradients.worldDefault,
    icon: Icons.school_rounded,
    motif: 'knowledge_sphere',
  );

  static const List<SubjectVisualIdentity> _all = [
    _programming,
    _programmingAlt,
    _networks,
    _networksAlt,
    _dbms,
    _dbmsAlt,
    _os,
    _osAlt,
    _dataStructures,
    _dsaAlt,
  ];

  /// Resolve visual identity from backend [Subject.iconKey].
  /// Always returns a valid identity — never throws.
  ///
  /// Matching is case-insensitive for resilience.
  static SubjectVisualIdentity fromIconKey(String iconKey) {
    final key = iconKey.toLowerCase().trim();
    try {
      return _all.firstWhere((i) => i.iconKey.toLowerCase() == key);
    } catch (_) {
      // Try partial match (backend may use longer compound keys)
      try {
        return _all.firstWhere(
          (i) => key.contains(i.iconKey.toLowerCase()) ||
              i.iconKey.toLowerCase().contains(key),
        );
      } catch (_) {
        return fallback;
      }
    }
  }

  /// Resolve visual identity from subject name string.
  static SubjectVisualIdentity fromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('program') || lower.contains('code')) {
      return _programming;
    }
    if (lower.contains('network')) return _networks;
    if (lower.contains('database') || lower.contains('dbms')) return _dbms;
    if (lower.contains('operat') || lower.contains(' os')) return _os;
    if (lower.contains('data struct') || lower.contains('dsa')) {
      return _dataStructures;
    }
    return fallback;
  }

  /// All known subject identities (primary variants only).
  static List<SubjectVisualIdentity> get known => [
    _programming,
    _networks,
    _dbms,
    _os,
    _dataStructures,
  ];
}

/// Icon widget that shows the correct subject icon with accent color.
/// Falls back gracefully for unknown subjects.
class SubjectIcon extends StatelessWidget {
  const SubjectIcon({
    super.key,
    required this.iconKey,
    this.size = 28,
    this.withBackground = true,
  });

  final String iconKey;
  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final identity = SubjectVisualRegistry.fromIconKey(iconKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = Icon(identity.icon, size: size * 0.55, color: identity.accent);

    if (!withBackground) return icon;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.cardHighlight(identity.accent),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: identity.accent.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
      alignment: Alignment.center,
      child: icon,
    );
  }
}
