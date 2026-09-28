import 'model_ids.dart';

/// AI-001 request (client-side bounds mirror the approved contract:
/// question <=2000 chars, conversation <=8 messages of <=1000 chars).
class TutorRequest {
  const TutorRequest({
    required this.question,
    this.subjectId,
    this.topicId,
    this.conversation = const <TutorMessage>[],
  });

  final String question;
  final String? subjectId;
  final String? topicId;
  final List<TutorMessage> conversation;

  Map<String, dynamic> toJson() => {
    'question': question,
    if (subjectId != null) 'subjectId': subjectId,
    if (topicId != null) 'topicId': topicId,
    if (conversation.isNotEmpty)
      'conversation': conversation.map((m) => m.toJson()).toList(),
  };
}

class TutorMessage {
  const TutorMessage({required this.role, required this.content});

  /// role: LEARNER | TUTOR
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// AI-001 response. refused/degraded carry deterministic server templates.
class TutorResponse {
  const TutorResponse({
    required this.answer,
    required this.refused,
    required this.degraded,
    required this.context,
  });

  final String answer;
  final bool refused;
  final bool degraded;
  final TutorContext? context;

  factory TutorResponse.fromJson(Map<String, dynamic> json) => TutorResponse(
    answer: json['answer'] as String? ?? '',
    refused: json['refused'] as bool? ?? false,
    degraded: json['degraded'] as bool? ?? false,
    context: json['context'] is Map<String, dynamic>
        ? TutorContext.fromJson(json['context'] as Map<String, dynamic>)
        : null,
  );
}

class TutorContext {
  const TutorContext({
    this.subjectId,
    this.topicId,
    this.subjectName,
    this.topicName,
  });

  final String? subjectId;
  final String? topicId;
  final String? subjectName;
  final String? topicName;

  factory TutorContext.fromJson(Map<String, dynamic> json) => TutorContext(
    subjectId: uuidOrNull(json['subjectId']),
    topicId: uuidOrNull(json['topicId']),
    subjectName: json['subjectName'] as String?,
    topicName: json['topicName'] as String?,
  );
}
