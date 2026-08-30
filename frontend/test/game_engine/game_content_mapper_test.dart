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

    test('memoryPairs fallback to quiz when lesson empty', () {
      final emptyLesson = Lesson(id: lesson.id, topicId: lesson.topicId, title: lesson.title, content: '', summary: '', difficulty: 'EASY', sourceType: 'CURATED');
      final pairs = GameContentMapper.memoryPairs(lesson: emptyLesson, quiz: quiz, topic: topic, maxPairs: 2);
      expect(pairs.length, 2);
      expect(pairs[0].term, contains('What is a variable'));
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
