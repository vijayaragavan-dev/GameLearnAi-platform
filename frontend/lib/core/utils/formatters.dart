/// Presentation-only formatting helpers. No business values are derived
/// here - every input is a backend-provided number/string.
abstract final class Formatters {
  /// 87.5 -> "88%" ; 100 -> "100%"
  static String percent(num value) => '${value.round()}%';

  /// 1250 -> "1,250"
  static String count(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buf.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// ISO date or timestamp -> "Aug 24" / "Aug 24, 2025".
  static String shortDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now().toUtc();
    final sameYear = date.year == now.year || date.isAfter(now);
    final base = '${_months[date.month - 1]} ${date.day}';
    return sameYear && date.year != now.year ? '$base, ${date.year}' : base;
  }

  /// "Good morning/afternoon/evening" by local hour.
  static String daypartGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String seconds(int? totalSeconds) {
    if (totalSeconds == null) return '';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}

/// Semantic presentation of backend enum strings (icon + label + color key).
/// Never reclassifies data - only maps known contract values.
abstract final class EnumPresentation {
  static (String label, String icon) pathNode(String status) =>
      switch (status) {
        'COMPLETED' => ('Completed', '\u2713'),
        'LOCKED' => ('Locked', '\u{1F512}'),
        'IN_PROGRESS' => ('In progress', '\u25B6'),
        'AVAILABLE' => ('Available', '\u26A1'),
        _ => (status, '\u2022'),
      };

  static (String label, String icon) masteryLevel(String level) =>
      switch (level) {
        'MASTERED' => ('Mastered', '\u{1F451}'),
        'PROFICIENT' => ('Proficient', '\u2B50'),
        'DEVELOPING' => ('Developing', '\u{1F4C8}'),
        'BEGINNER' => ('Beginner', '\u{1F331}'),
        _ => (level.isEmpty ? 'Unknown' : level, '\u2022'),
      };

  static (String label, String icon) activityType(String type) =>
      switch (type) {
        'CONTINUE_LESSON' => ('Continue lesson', '\u{1F4D6}'),
        'PRACTICE' => ('Practice', '\u{1F393}'),
        'REVIEW' => ('Review', '\u{1F501}'),
        'QUIZ' => ('Challenge', '\u2694\uFE0F'),
        'REMEDIATION' => ('Reinforce', '\u{1F6E0}\uFE0F'),
        'ADVANCE' => ('Advance', '\u{1F680}'),
        _ => (type.isEmpty ? 'Next step' : type, '\u2022'),
      };

  static (String label, String icon) trend(String trend) => switch (trend) {
    'IMPROVING' => ('Improving', '\u{1F4C8}'),
    'STABLE' => ('Stable', '\u2194\uFE0F'),
    'DECLINING' => ('Needs attention', '\u{1F53C}'),
    _ => ('New', '\u2728'),
  };
}
