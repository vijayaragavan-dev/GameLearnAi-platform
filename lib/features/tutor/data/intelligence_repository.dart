import '../../../../core/models/dashboard_models.dart';
import '../../../../core/models/tutor_models.dart';
import '../../../../core/network/api_client.dart';

/// DASH-001 and AI-001.
class IntelligenceRepository {
  IntelligenceRepository(this._client);

  final ApiClient _client;

  Future<Dashboard> dashboard() async =>
      Dashboard.fromJson(await _client.getJson('/api/v1/dashboard'));

  /// AI-001. Throws RateLimitedException on 429 and
  /// AiUnavailableException on 503 per the approved failure policy.
  /// Server budget is deadline 15s + one approved retry (~35s worst case),
  /// so the client allows up to 60s before its own timeout fires.
  Future<TutorResponse> askTutor(TutorRequest request) async =>
      TutorResponse.fromJson(
        await _client.postJson(
          '/api/v1/ai/tutor',
          request.toJson(),
          timeout: const Duration(seconds: 60),
        ),
      );
}
