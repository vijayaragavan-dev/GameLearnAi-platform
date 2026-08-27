import '../../../core/models/content_models.dart';

/// Presentation-only grouping for the Core CS catalog.
///
/// SUBJ-001 currently does NOT expose a `category` field. This resolver
/// provides a client-side decorative grouping so category chips can be
/// rendered without claiming backend authority. If a future Subject DTO adds
/// `category`, this file can be replaced to read that field directly without
/// changing SubjectsScreen architecture.
///
/// Rules:
/// - Purely presentational: return a label for grouping UI only.
/// - Never influences navigation, mastery, recommendations, difficulty,
///   path generation, assessment, or backend requests.
/// - Isolated in one file so migration to backend-authoritative category is
///   single-point.
abstract final class SubjectGrouping {
  static const String allLabel = 'All';

  /// Conceptual Core CS groups per blueprint §42. Display labels are user-facing.
  static const List<String> coreLabels = [
    'Programming',
    'Data Structures & Algorithms',
    'Databases',
    'Systems',
    'Networks',
    'AI & ML',
    'Web',
    'Security',
    'Theory',
    'Software Engineering',
    'Aptitude',
  ];

  /// Decorative heuristic: maps a Subject's name/description/iconKey to a core label.
  /// Heuristic is intentionally name-based, case-insensitive, and never behavioral.
  static String categoryOf(Subject subject) {
    final haystack = '${subject.name} ${subject.description} ${subject.iconKey}'
        .toLowerCase();

    // Order matters: more specific before generic.
    if (_containsAny(haystack, ['data structure', 'algorithm', 'dsa'])) {
      return 'Data Structures & Algorithms';
    }
    if (_containsAny(haystack, ['database', 'dbms', 'sql', 'storage'])) {
      return 'Databases';
    }
    if (_containsAny(haystack, ['network', 'lan', 'routing', 'packet'])) {
      return 'Networks';
    }
    if (_containsAny(haystack, [
      'operating system',
      ' operating',
      ' os ',
      'os_',
      'memory',
      'kernel',
    ])) {
      // Avoid matching "prose" substring; check word boundary-ish.
      if (haystack.contains('operating') || haystack.contains('memory')) {
        return 'Systems';
      }
    }
    // Systems catch-all after OS check
    if (_containsAny(haystack, [
      'architecture',
      'distributed',
      'systems',
      'embedded',
    ])) {
      return 'Systems';
    }
    if (_containsAny(haystack, [
      'ai ',
      'artificial',
      'machine learning',
      'ml',
      'deep learning',
      'data science',
      'data analytics',
    ])) {
      return 'AI & ML';
    }
    if (_containsAny(haystack, [
      'cyber',
      'security',
      'crypto',
      'network security',
      'application security',
    ])) {
      return 'Security';
    }
    if (_containsAny(haystack, [
      'web',
      'html',
      'css',
      'javascript',
      'backend',
      'frontend',
      'api ',
    ])) {
      return 'Web';
    }
    if (_containsAny(haystack, ['compiler', 'theory', 'computation', 'toc'])) {
      return 'Theory';
    }
    if (_containsAny(haystack, ['software', 'system design', 'sdlc'])) {
      return 'Software Engineering';
    }
    if (_containsAny(haystack, [
      'aptitude',
      'interview',
      'reasoning',
      'logical',
    ])) {
      return 'Aptitude';
    }
    // Programming is the broad fallback core group (covers C/C++/Java/Python/JS etc.)
    // Check last so more specific groups above win.
    if (_containsAny(haystack, [
      'programming',
      'java',
      'python',
      'c++',
      ' c ',
      'javascript',
      'terminal',
    ])) {
      return 'Programming';
    }
    // Final fallback: bucket as Programming if name hints at code, else Systems for unknown.
    if (haystack.contains('program') || haystack.contains('code')) {
      return 'Programming';
    }
    return 'Programming';
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }

  /// Returns chips to render: All + unique categories present in the list,
  /// ordered by coreLabels order (stable, not alphabetical) for predictable UX.
  static List<String> deriveChips(List<Subject> subjects) {
    if (subjects.isEmpty) return [allLabel];
    final present = <String>{};
    for (final s in subjects) {
      present.add(categoryOf(s));
    }
    final ordered = <String>[allLabel];
    for (final label in coreLabels) {
      if (present.contains(label)) ordered.add(label);
    }
    // Include any present that isn't in coreLabels (should not happen, but guard).
    for (final p in present) {
      if (!ordered.contains(p)) ordered.add(p);
    }
    return ordered;
  }

  /// Client-side filter: returns subjects whose decorative category matches label.
  /// "All" returns original list. Never triggers network.
  static List<Subject> filter(List<Subject> subjects, String selectedCategory) {
    if (selectedCategory == allLabel) return subjects;
    return subjects
        .where((s) => categoryOf(s) == selectedCategory)
        .toList(growable: false);
  }
}
