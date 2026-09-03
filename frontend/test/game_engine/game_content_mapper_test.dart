import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/models/content_models.dart';
import 'package:gamelearn_app/core/models/quiz_models.dart';
import 'package:gamelearn_app/features/game_engine/utils/game_content_mapper.dart';

void main() {
  group('GameContentMapper', () {
    final topic = Topic(id: '11111111-1111-1111-1111-111111111101', subjectId: '22222222-2222-2222-2222-222222222202', subjectName: 'Programming', name: 'Variables', description: 'Learn variables and types in programming. Master data storage concepts. Practice declarations daily.', difficulty: 'EASY', displayOrder: 1);
    final lesson = Lesson(id: '33333333-3333-3333-3333-333333333303', topicId: topic.id, title: 'Variables Lesson', content: 'Variables store data.\nTypes define the kind of data.\nDeclarations create variables.\nInitialization assigns initial value.', summary: 'Understanding variables', difficulty: 'EASY', sourceType: 'CURATED');
    final quiz = Quiz(id: '44444444-4444-4444-4444-444444444404', topicId: topic.id, title: 'Variables Quiz', description: '', difficulty: 'EASY', timeLimitSeconds: 30, questionCount: 3, questions: [
      const QuizQuestion(id: 'q1', questionText: 'What is a variable?', options: ['Storage for data', 'A function', 'A loop'], difficulty: 'EASY'),
      const QuizQuestion(id: 'q2', questionText: 'Which type holds text?', options: ['String', 'Integer', 'Boolean'], difficulty: 'MEDIUM'),
      const QuizQuestion(id: 'q3', questionText: 'What keyword declares constant?', options: ['const', 'let', 'var'], difficulty: 'HARD'),
    ]);

    test('memoryPairs from lesson prefers lesson content', () {
      final pairs = GameContentMapper.memoryPairs(lesson: lesson, quiz: quiz, topic: topic, maxPairs: 3);
      expect(pairs.length, greaterThanOrEqualTo(2));
      expect(pairs.first.term, isNotEmpty);
      expect(pairs.first.definition, isNotEmpty);
    });

    test('memoryPairs fallback to quiz when lesson empty and topic null', () {
      final emptyLesson = Lesson(id: lesson.id, topicId: lesson.topicId, title: lesson.title, content: '', summary: '', difficulty: 'EASY', sourceType: 'CURATED');
      final pairs = GameContentMapper.memoryPairs(lesson: emptyLesson, quiz: quiz, topic: null, maxPairs: 2);
      expect(pairs.length, 2);
      expect(pairs[0].term, contains('What is a variable'));
    });

    test('memoryPairs prefers topic over quiz when lesson empty and topic rich', () {
      final emptyLesson = Lesson(id: lesson.id, topicId: lesson.topicId, title: lesson.title, content: '', summary: '', difficulty: 'EASY', sourceType: 'CURATED');
      final pairs = GameContentMapper.memoryPairs(lesson: emptyLesson, quiz: quiz, topic: topic, maxPairs: 2);
      expect(pairs.length, 2);
      // With P1-3 fix, topic (authoritative) is preferred over quiz fallback, so term comes from topic description, not quiz
      expect(pairs[0].term, contains('Variables'));
    });

    test('P1-3: memoryPairs does NOT derive definition from options[0]', () {
      final emptyLesson = Lesson(id: lesson.id, topicId: lesson.topicId, title: lesson.title, content: '', summary: '', difficulty: 'EASY', sourceType: 'CURATED');
      // Use a topic with minimal description so fallback to quiz is forced (less than 2 sentences)
      final minimalTopic = Topic(id: topic.id, subjectId: topic.subjectId, subjectName: topic.subjectName, name: topic.name, description: 'Short', difficulty: topic.difficulty, displayOrder: topic.displayOrder);
      final quizWithOptions = Quiz(id: quiz.id, topicId: minimalTopic.id, title: quiz.title, description: quiz.description, difficulty: quiz.difficulty, timeLimitSeconds: quiz.timeLimitSeconds, questionCount: quiz.questionCount, questions: [
        const QuizQuestion(id: 'q1', questionText: 'What is a variable?', options: ['Storage for data', 'A function', 'A loop'], difficulty: 'EASY'),
      ]);
      final pairs = GameContentMapper.memoryPairs(lesson: emptyLesson, quiz: quizWithOptions, topic: minimalTopic, maxPairs: 1);
      expect(pairs.length, 1);
      // Definition must NOT be the first option (previous buggy behavior)
      expect(pairs.first.definition, isNot('Storage for data'));
      expect(pairs.first.definition, isNot(contains('Storage for data')));
      // Should be deterministic non-fabricated placeholder
      expect(pairs.first.definition, contains('Review focus'));
    });

    test('P1-3: reordered options preserve same correct behavior (definition not tied to order)', () {
      final emptyLesson = Lesson(id: lesson.id, topicId: lesson.topicId, title: lesson.title, content: '', summary: '', difficulty: 'EASY', sourceType: 'CURATED');
      final minimalTopic = Topic(id: topic.id, subjectId: topic.subjectId, subjectName: topic.subjectName, name: topic.name, description: 'Short', difficulty: topic.difficulty, displayOrder: topic.displayOrder);
      final quizA = Quiz(id: quiz.id, topicId: minimalTopic.id, title: quiz.title, description: quiz.description, difficulty: quiz.difficulty, timeLimitSeconds: quiz.timeLimitSeconds, questionCount: 1, questions: [
        const QuizQuestion(id: 'q1', questionText: 'What is a variable?', options: ['Storage for data', 'A function', 'A loop'], difficulty: 'EASY'),
      ]);
      final quizB = Quiz(id: quiz.id, topicId: minimalTopic.id, title: quiz.title, description: quiz.description, difficulty: quiz.difficulty, timeLimitSeconds: quiz.timeLimitSeconds, questionCount: 1, questions: [
        const QuizQuestion(id: 'q1', questionText: 'What is a variable?', options: ['A loop', 'Storage for data', 'A function'], difficulty: 'EASY'),
      ]);
      final pairsA = GameContentMapper.memoryPairs(lesson: emptyLesson, quiz: quizA, topic: minimalTopic, maxPairs: 1);
      final pairsB = GameContentMapper.memoryPairs(lesson: emptyLesson, quiz: quizB, topic: minimalTopic, maxPairs: 1);
      expect(pairsA.first.definition, equals(pairsB.first.definition));
      expect(pairsA.first.term, equals(pairsB.first.term));
    });

    test('P1-3: lesson content remains authoritative when available', () {
      final pairs = GameContentMapper.memoryPairs(lesson: lesson, quiz: quiz, topic: topic, maxPairs: 2);
      // When lesson is present, pairs derive from lesson sentences, not quiz options
      expect(pairs.first.term, isNot(contains('What is a variable')));
    });

    test('memoryPairs fallback to topic when no lesson/quiz', () {
      final pairs = GameContentMapper.memoryPairs(topic: topic, maxPairs: 2);
      expect(pairs.length, 2);
    });

    test('dragDropPayload from quiz uses difficulty zones', () {
      final payload = GameContentMapper.dragDropPayload(quiz: quiz, topic: topic);
      expect(payload.zones, containsAll(['EASY', 'MEDIUM', 'HARD']));
      expect(payload.items.length, 3);
      expect(payload.items.first.correctZone, isIn(['EASY', 'MEDIUM', 'HARD']));
    });

    test('dragDropPayload from lesson creates step zones', () {
      final payload = GameContentMapper.dragDropPayload(lesson: lesson, topic: topic);
      // lesson case requires at least 3 steps; our lesson has 4, so zones are Step 1..4
      expect(payload.zones.any((z) => z.contains('Step')), true);
      expect(payload.items.length, payload.zones.length);
    });

    test('dragDropPayload fallback uses concept zones', () {
      final payload = GameContentMapper.dragDropPayload(topic: topic);
      expect(payload.zones, contains('Concept'));
      expect(payload.items.length, 3);
    });
  });
}
