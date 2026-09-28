import '../../../../core/models/content_models.dart';
import '../../../../core/network/api_client.dart';

/// SUBJ-001, TOPIC-001, LESSON-001, PATH-001/002.
class ContentRepository {
  ContentRepository(this._client);

  final ApiClient _client;

  Future<List<Subject>> subjects() async {
    final list = await _client.getList('/api/v1/subjects');
    return list
        .whereType<Map<String, dynamic>>()
        .map(Subject.fromJson)
        .toList(growable: false);
  }

  Future<Topic> topic(String topicId) async =>
      Topic.fromJson(await _client.getJson('/api/v1/topics/$topicId'));

  Future<Lesson> lesson(String topicId) async =>
      Lesson.fromJson(await _client.getJson('/api/v1/topics/$topicId/lesson'));

  /// PATH-001. Empty list when no path exists yet - a valid state.
  Future<List<LearningPath>> pathsForSubject(String subjectId) async {
    final list = await _client.getList('/api/v1/learning-path/$subjectId');
    return list
        .whereType<Map<String, dynamic>>()
        .map(LearningPath.fromJson)
        .toList(growable: false);
  }

  /// First ACTIVE path for the subject, or null when none exists.
  Future<LearningPath?> activePathForSubject(String subjectId) async {
    final paths = await pathsForSubject(subjectId);
    for (final p in paths) {
      if (p.status == 'ACTIVE') return p;
    }
    return null;
  }

  /// PATH-002. Returns the persisted path plus optional cosmetic aiMetadata.
  /// Server budget is deadline 20s + one approved retry (~45s worst case),
  /// so the client allows up to 60s before its own timeout fires.
  Future<
    ({
      LearningPath path,
      Map<int, ({String objective, String rationale})> aiMetadata,
    })
  >
  generatePath({
    required String subjectId,
    bool regenerate = false,
    String? learningGoal,
  }) async {
    final json = await _client
        .postJson('/api/v1/learning-path/$subjectId/generate', {
          'regenerate': regenerate,
          if (learningGoal != null && learningGoal.trim().isNotEmpty)
            'learningGoal': learningGoal,
        }, timeout: const Duration(seconds: 60));
    return (
      path: LearningPath.fromJson(json),
      aiMetadata: const LearningPath(
        id: '',
        subjectId: '',
        title: '',
        description: '',
        status: '',
        generatedBy: '',
        nodes: [],
      ).aiMetadataFrom(json['aiMetadata']),
    );
  }
}
