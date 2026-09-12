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

  // ── 11-world expansion identities (canonical catalogue mirrors) ───────────
  // These extend — never replace — the 5 legacy identities above.

  static const SubjectVisualIdentity _algorithms = SubjectVisualIdentity(
    iconKey: 'algorithms',
    displayName: 'Algorithms',
    accent: Color(0xFFA78BFA), // violet-400
    atmosphereColor: Color(0xFF7C3AED),
    gradient: AppGradients.worldAlgorithms,
    icon: Icons.functions_rounded,
    motif: 'flow_chart',
  );

  static const SubjectVisualIdentity _oop = SubjectVisualIdentity(
    iconKey: 'oop',
    displayName: 'Object-Oriented Programming',
    accent: AppColors.secondary,
    atmosphereColor: AppColors.secondaryDeep,
    gradient: AppGradients.worldOOP,
    icon: Icons.class_rounded,
    motif: 'object_graph',
  );

  static const SubjectVisualIdentity _aiMl = SubjectVisualIdentity(
    iconKey: 'ai_ml',
    displayName: 'Artificial Intelligence & Machine Learning',
    accent: Color(0xFFF472B6), // pink-400
    atmosphereColor: Color(0xFFBE185D),
    gradient: AppGradients.worldAIML,
    icon: Icons.psychology_rounded,
    motif: 'neural_net',
  );

  static const SubjectVisualIdentity _dataScience = SubjectVisualIdentity(
    iconKey: 'data_science',
    displayName: 'Data Science',
    accent: Color(0xFF2DD4BF), // teal-400
    atmosphereColor: Color(0xFF0F766E),
    gradient: AppGradients.worldDataScience,
    icon: Icons.analytics_rounded,
    motif: 'data_canvas',
  );

  static const SubjectVisualIdentity _web = SubjectVisualIdentity(
    iconKey: 'web_technologies',
    displayName: 'Web Technologies',
    accent: Color(0xFF60A5FA), // blue-400
    atmosphereColor: Color(0xFF1D4ED8),
    gradient: AppGradients.worldWeb,
    icon: Icons.language_rounded,
    motif: 'browser_grid',
  );

  static const SubjectVisualIdentity _oose = SubjectVisualIdentity(
    iconKey: 'oose',
    displayName: 'Object-Oriented Software Engineering',
    accent: AppColors.warning,
    atmosphereColor: Color(0xFF92400E),
    gradient: AppGradients.worldOOSE,
    icon: Icons.architecture_rounded,
    motif: 'blueprint_stack',
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

  // Alternate spellings for 11-world backend variance (exact-match first).
  static const SubjectVisualIdentity _dsShort = SubjectVisualIdentity(
    iconKey: 'ds',
    displayName: 'Data Structures',
    accent: Color(0xFF34D399),
    atmosphereColor: Color(0xFF059669),
    gradient: AppGradients.worldDataStructures,
    icon: Icons.account_tree_rounded,
    motif: 'tree_graph',
  );

  static const SubjectVisualIdentity _dsSubject = SubjectVisualIdentity(
    iconKey: 'subject_ds',
    displayName: 'Data Structures',
    accent: Color(0xFF34D399),
    atmosphereColor: Color(0xFF059669),
    gradient: AppGradients.worldDataStructures,
    icon: Icons.account_tree_rounded,
    motif: 'tree_graph',
  );

  static const SubjectVisualIdentity _sqlAlt = SubjectVisualIdentity(
    iconKey: 'sql',
    displayName: 'Database Systems',
    accent: Color(0xFFFB923C),
    atmosphereColor: Color(0xFFEA580C),
    gradient: AppGradients.worldDatabase,
    icon: Icons.storage_rounded,
    motif: 'data_vault',
  );

  static const SubjectVisualIdentity _dataScienceAlt = SubjectVisualIdentity(
    iconKey: 'datascience',
    displayName: 'Data Science',
    accent: Color(0xFF2DD4BF),
    atmosphereColor: Color(0xFF0F766E),
    gradient: AppGradients.worldDataScience,
    icon: Icons.analytics_rounded,
    motif: 'data_canvas',
  );

  static const SubjectVisualIdentity _webAlt = SubjectVisualIdentity(
    iconKey: 'subject_web',
    displayName: 'Web Technologies',
    accent: Color(0xFF60A5FA),
    atmosphereColor: Color(0xFF1D4ED8),
    gradient: AppGradients.worldWeb,
    icon: Icons.language_rounded,
    motif: 'browser_grid',
  );

  static const SubjectVisualIdentity _javaAlt = SubjectVisualIdentity(
    iconKey: 'java',
    displayName: 'Object-Oriented Programming',
    accent: AppColors.secondary,
    atmosphereColor: AppColors.secondaryDeep,
    gradient: AppGradients.worldOOP,
    icon: Icons.class_rounded,
    motif: 'object_graph',
  );

  static const SubjectVisualIdentity _ooseAlt = SubjectVisualIdentity(    iconKey: 'software_engineering',
    displayName: 'Object-Oriented Software Engineering',
    accent: AppColors.warning,
    atmosphereColor: Color(0xFF92400E),
    gradient: AppGradients.worldOOSE,
    icon: Icons.architecture_rounded,
    motif: 'blueprint_stack',
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
    _sqlAlt,
    _os,
    _osAlt,
    _dataStructures,
    _dsaAlt,
    _dsShort,
    _dsSubject,
    _algorithms,
    _oop,
    _javaAlt,
    _aiMl,
    _dataScience,
    _dataScienceAlt,
    _web,
    _webAlt,
    _oose,
    _ooseAlt,
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
  /// Covers all 11 canonical worlds; unknown names yield [fallback].
  static SubjectVisualIdentity fromName(String name) {
    final lower = name.toLowerCase();
    // Specific multi-word worlds first (order matters).
    if (lower.contains('software engineering') ||
        (lower.contains('object') && lower.contains('software'))) {
      return _oose;
    }
    if (lower.contains('web technolog') ||
        (lower.contains('web') &&
            (lower.contains('technolog') ||
                lower.contains('develop') ||
                lower.contains('html')))) {
      return _web;
    }
    if (lower.contains('data science')) return _dataScience;
    if (lower.contains('artificial intelligence') ||
        lower.contains('machine learning') ||
        lower.contains('ai & ml') ||
        lower.contains('ai/ml')) {
      return _aiMl;
    }
    if (lower.contains('object-oriented') ||
        lower.contains('object oriented') ||
        (lower.contains(' oop'))) {
      return _oop;
    }
    if (lower.contains('algorithm')) return _algorithms;
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

  /// All known subject identities (primary variants only — 11 worlds).
  static List<SubjectVisualIdentity> get known => [
    _programming,
    _dataStructures,
    _algorithms,
    _dbms,
    _networks,
    _os,
    _oop,
    _aiMl,
    _dataScience,
    _web,
    _oose,
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
