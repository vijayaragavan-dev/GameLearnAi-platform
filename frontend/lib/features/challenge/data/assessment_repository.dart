import '../../../../core/models/assessment_models.dart';
import '../../../../core/network/api_client.dart';

/// ASMT-001..003. Stateless delivery; single-lineage baseline submit.
class AssessmentRepository {
  AssessmentRepository(this._client);

  final ApiClient _client;

  Future<AssessmentDelivery> fetch(String subjectId) async =>
      AssessmentDelivery.fromJson(
        await _client.getJson('/api/v1/assessment/$subjectId'),
      );

  /// 201 on success; ConflictException (409) when R-GUARD fires.
  Future<AssessmentSubmissionResult> submit(
    String subjectId,
    List<({String questionId, String selectedAnswer})> answers,
  ) async => AssessmentSubmissionResult.fromJson(
    await _client.postJson('/api/v1/assessment/$subjectId/submit', {
      'answers': [
        for (final a in answers)
          {'questionId': a.questionId, 'selectedAnswer': a.selectedAnswer},
      ],
    }),
  );

  Future<AssessmentOutcome> result(String subjectId) async =>
      AssessmentOutcome.fromJson(
        await _client.getJson('/api/v1/assessment/$subjectId/result'),
      );
}
