import 'model_ids.dart';

/// SUBJ-001 element.
class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.isActive,
    required this.displayOrder,
  });

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final bool isActive;
  final int displayOrder;

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: uuidOf(json['id'], 'Subject.id'),
    name: (json['name'] as String?) ?? '',
    description: json['description'] as String? ?? '',
    iconKey: json['iconKey'] as String? ?? '',
    isActive: json['isActive'] as bool? ?? true,
    displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
  );
}

/// TOPIC-001 response.
class Topic {
  const Topic({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.displayOrder,
  });

  final String id;
  final String subjectId;
  final String subjectName;
  final String name;
  final String description;
  final String difficulty; // EASY | MEDIUM | HARD
  final int displayOrder;

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: uuidOf(json['id'], 'Topic.id'),
    subjectId: uuidOf(json['subjectId'], 'Topic.subjectId'),
    subjectName: json['subjectName'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? 'EASY',
    displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
  );
}

/// LESSON-001 response.
class Lesson {
  const Lesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.content,
    required this.summary,
    required this.difficulty,
    required this.sourceType,
  });

  final String id;
  final String topicId;
  final String title;
  final String content;
  final String summary;
  final String difficulty;
  final String sourceType;

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: uuidOf(json['id'], 'Lesson.id'),
    topicId: uuidOf(json['topicId'], 'Lesson.topicId'),
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? 'EASY',
    sourceType: json['sourceType'] as String? ?? '',
  );
}

/// PATH-001 / PATH-002 node. Status is ALWAYS backend-provided:
/// LOCKED | AVAILABLE | IN_PROGRESS | COMPLETED.
class PathNode {
  const PathNode({
    required this.id,
    required this.topicId,
    required this.topicName,
    required this.sequenceNumber,
    required this.requiredMastery,
    required this.status,
  });

  final String id;
  final String topicId;
  final String topicName;
  final int sequenceNumber;
  final double requiredMastery;
  final String status;

  factory PathNode.fromJson(Map<String, dynamic> json) => PathNode(
    id: uuidOf(json['id'], 'PathNode.id'),
    topicId: uuidOf(json['topicId'], 'PathNode.topicId'),
    topicName: json['topicName'] as String? ?? '',
    sequenceNumber: (json['sequenceNumber'] as num?)?.toInt() ?? 0,
    requiredMastery: (json['requiredMastery'] as num?)?.toDouble() ?? 0,
    status: json['status'] as String? ?? 'LOCKED',
  );
}

/// PATH-001 list entry.
class LearningPath {
  const LearningPath({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.status,
    required this.generatedBy,
    required this.nodes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String subjectId;
  final String title;
  final String description;
  final String status;
  final String generatedBy;
  final List<PathNode> nodes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static List<PathNode> _nodes(List<dynamic>? raw) =>
      raw?.whereType<Map<String, dynamic>>().map(PathNode.fromJson).toList() ??
      <PathNode>[];

  /// Accepts both LearningPathResponse and GeneratedLearningPathResponse
  /// shapes (the generated variant carries optional timestamps + aiMetadata).
  factory LearningPath.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toUtc() : null;
    return LearningPath(
      id: uuidOf(json['id'], 'LearningPath.id'),
      subjectId: uuidOf(json['subjectId'], 'LearningPath.subjectId'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      generatedBy: json['generatedBy'] as String? ?? 'SYSTEM',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      nodes: _nodes(json['nodes'] as List<dynamic>?),
    );
  }

  /// Optional cosmetic AI metadata (PATH-002 section 5.4) - never persisted,
  /// never fabricated. Keyed by sequenceNumber.
  Map<int, ({String objective, String rationale})> aiMetadataFrom(
    Object? aiMetadata,
  ) => _parseAiMetadata(aiMetadata);

  static Map<int, ({String objective, String rationale})> _parseAiMetadata(
    Object? aiMetadata,
  ) {
    if (aiMetadata is! Map<String, dynamic>) return const {};
    final nodes = aiMetadata['nodes'];
    if (nodes is! List) return const {};
    final map = <int, ({String objective, String rationale})>{};
    for (final item in nodes.whereType<Map<String, dynamic>>()) {
      final seq = (item['sequenceNumber'] as num?)?.toInt();
      final objective = item['objective'];
      final rationale = item['rationale'];
      if (seq == null || objective is! String || rationale is! String) continue;
      map[seq] = (objective: objective, rationale: rationale);
    }
    return map;
  }
}
