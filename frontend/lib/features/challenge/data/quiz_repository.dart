import '../../../../core/models/quiz_models.dart';
import '../../../../core/network/api_client.dart';

/// QUIZ-001/002. The backend is the sole authority for score/correctness.
class QuizRepository {
  QuizRepository(this._client);

  final ApiClient _client;

  Future<Quiz> quizForTopic(String topicId) async =>
      Quiz.fromJson(await _client.getJson('/api/v1/quiz/$topicId'));

  Future<QuizResult> submit(
    String quizId,
    List<({String questionId, String selectedAnswer})> answers,
  ) async => QuizResult.fromJson(
    await _client.postJson('/api/v1/quiz/$quizId/submit', {
      'answers': [
        for (final a in answers)
          {'questionId': a.questionId, 'selectedAnswer': a.selectedAnswer},
      ],
    }),
  );
}
