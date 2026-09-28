import '../../../core/models/content_models.dart';
import '../../../core/models/quiz_models.dart';

/// Maps learning content (Quiz/Lesson/Topic) into game-ready payloads.
/// No hard-coded large question sets; uses backend-provided content.
abstract final class GameContentMapper {
  /// Pairs for Memory Match derived from lesson or quiz.
  /// Returns list of (term, definition) pairs.
  static List<({String term, String definition})> memoryPairs({
    Quiz? quiz,
    Lesson? lesson,
    Topic? topic,
    int maxPairs = 6,
  }) {
    // Prefer lesson content if available and non-empty.
    if (lesson != null && lesson.content.trim().isNotEmpty) {
      final pairs = _fromLesson(lesson, maxPairs);
      if (pairs.length >= 2) return pairs;
    }
    // P1-3: Prefer topic description (authoritative) over quiz fallback.
    // Quiz fallback previously fabricated definition from options[0], which is not
    // guaranteed to be the correct answer. Topic path is authoritative and deterministic.
    if (topic != null) {
      final topicPairs = _fromTopic(topic, maxPairs);
      if (topicPairs.length >= 2) return topicPairs;
    }
    if (quiz != null && quiz.questions.isNotEmpty) {
      return _fromQuiz(quiz, maxPairs);
    }
    if (topic != null) {
      return _fromTopic(topic, maxPairs);
    }
    return [];
  }

  static List<({String term, String definition})> _fromLesson(Lesson lesson, int max) {
    // Split lesson.content into sentences, use title fragments as terms.
    final sentences = lesson.content
        .split(RegExp(r'[\n\.]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 12)
        .toList();
    final summarySentences = lesson.summary
        .split(RegExp(r'[\.!\n]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 10)
        .toList();
    final all = [...sentences, ...summarySentences];
    final result = <({String term, String definition})>[];
    for (var i = 0; i < all.length && result.length < max; i++) {
      final def = all[i];
      if (def.length < 8) continue;
      // Term = first 2-3 words or lesson title variant
      final words = def.split(RegExp(r'\s+'));
      final term = words.take(3).join(' ');
      final clippedTerm = term.length > 30 ? term.substring(0, 30) : term;
      result.add((term: clippedTerm, definition: def.length > 90 ? '${def.substring(0, 87)}...' : def));
    }
    // If still not enough, add title-based pair
    if (result.isEmpty && lesson.title.isNotEmpty) {
      result.add((term: lesson.title, definition: lesson.summary.isNotEmpty ? lesson.summary : lesson.content.substring(0, lesson.content.length.clamp(0, 90))));
    }
    return result;
  }

  static List<({String term, String definition})> _fromQuiz(Quiz quiz, int max) {
    final result = <({String term, String definition})>[];
    for (var i = 0; i < quiz.questions.length && result.length < max; i++) {
      final q = quiz.questions[i];
      final term = q.questionText.length > 60 ? '${q.questionText.substring(0, 57)}...' : q.questionText;
      // P1-3 FIX: Do NOT use options[0] as definition. Options order is not authoritative
      // and correctAnswer is intentionally not exposed in QUIZ-001 (only after submission).
      // Using options.first would fabricate educational meaning and could be wrong if
      // options are shuffled or correct answer is not first (seed currently has correct first
      // by coincidence, but contract does not guarantee it). Use a deterministic, non-fabricated
      // placeholder derived from questionText/difficulty. Topic fallback is preferred over this
      // quiz fallback; this path is now last resort and must remain trustworthy.
      final def = 'Review focus • ${q.difficulty}';
      final definition = def.length > 70 ? '${def.substring(0, 67)}...' : def;
      result.add((term: term, definition: definition));
    }
    return result;
  }

  static List<({String term, String definition})> _fromTopic(Topic topic, int max) {
    // Use topic name + description to fabricate minimal pairs deterministically.
    final descSentences = topic.description
        .split(RegExp(r'[\.\n]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 8)
        .toList();
    final result = <({String term, String definition})>[];
    if (descSentences.isNotEmpty) {
      for (var i = 0; i < descSentences.length && result.length < max; i++) {
        result.add((term: '${topic.name} ${i + 1}', definition: descSentences[i]));
      }
    } else {
      for (var i = 0; i < max && i < 3; i++) {
        result.add((term: '${topic.name} Concept ${i + 1}', definition: 'Key concept of ${topic.name}'));
      }
    }
    return result;
  }

  /// Items for Drag & Drop: each item belongs to a zone.
  /// Generates zones and items from quiz/lesson.
  static ({List<String> zones, List<DragItem> items}) dragDropPayload({
    Quiz? quiz,
    Lesson? lesson,
    Topic? topic,
  }) {
    if (quiz != null && quiz.questions.length >= 3) {
      // Zones = difficulty buckets, items = question texts
      const zones = ['EASY', 'MEDIUM', 'HARD'];
      final items = <DragItem>[];
      for (final q in quiz.questions) {
        items.add(DragItem(id: q.id, label: q.questionText.length > 50 ? '${q.questionText.substring(0, 47)}...' : q.questionText, correctZone: q.difficulty.toUpperCase()));
      }
      return (zones: zones, items: items);
    }
    if (lesson != null && lesson.content.trim().isNotEmpty) {
      // Zones = Steps 1..N for ordering challenge
      final steps = lesson.content
          .split(RegExp(r'[\n]+'))
          .map((s) => s.trim())
          .where((s) => s.length > 10)
          .take(5)
          .toList();
      if (steps.length >= 3) {
        final zones = List.generate(steps.length, (i) => 'Step ${i + 1}');
        final items = List.generate(steps.length, (i) => DragItem(id: 'step_$i', label: steps[i].length > 50 ? '${steps[i].substring(0, 47)}...' : steps[i], correctZone: zones[i]));
        // Shuffle items for challenge (deterministic shuffle by reversing)
        return (zones: zones, items: items.reversed.toList());
      }
    }
    // Fallback: topic-based classification
    final zones = ['Concept', 'Definition', 'Example'];
    final items = <DragItem>[
      DragItem(id: '1', label: topic?.name ?? 'Concept A', correctZone: 'Concept'),
      DragItem(id: '2', label: topic?.description.isNotEmpty == true ? (topic!.description.length > 50 ? topic.description.substring(0, 47) + '...' : topic.description) : 'Definition', correctZone: 'Definition'),
      DragItem(id: '3', label: 'Example of ${topic?.name ?? 'topic'}', correctZone: 'Example'),
    ];
    return (zones: zones, items: items);
  }
}

class DragItem {
  const DragItem({required this.id, required this.label, required this.correctZone});
  final String id;
  final String label;
  final String correctZone;
}
