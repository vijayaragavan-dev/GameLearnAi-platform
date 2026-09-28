import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/study_document.dart';
import '../domain/study_practice.dart';
import '../domain/study_tutor.dart';
import '../domain/study_upload.dart';
import 'study_lab_repository.dart';

/// MlRag-backed document library (integration phase).
///
/// Implements [StudyLabRepository] against the real document APIs:
/// `GET /api/v1/documents`, `POST /api/v1/documents` (multipart),
/// `POST /api/v1/documents/ask`. Ownership stays server-side
/// (authenticated principal); no user/owner ids are ever sent.
/// Practice generation/evaluation have no backend yet and stay
/// honestly unavailable.
class ApiStudyLabRepository implements StudyLabRepository {
  ApiStudyLabRepository(this._client);

  final ApiClient _client;

  static final RegExp _citationRe =
      RegExp(r'^doc:([^#\s]+):v(\d+)#p(\d+)c(\d+)$');

  @override
  Future<List<StudyDocument>> documents() async {
    final list = await _client.getList('/api/v1/documents');
    return list
        .whereType<Map<String, dynamic>>()
        .map(_documentFromJson)
        .toList(growable: false);
  }

  @override
  Future<StudyDocument?> documentById(String id) async {
    final docs = await documents();
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  @override
  Future<UploadResult> uploadDocument(PickedStudyFile file) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return const UploadFailure(
        "We couldn't read this file. Please choose another PDF.",
      );
    }
    try {
      final json = await _client.postMultipart(
        '/api/v1/documents',
        fileField: 'file',
        filename: file.name,
        contentType: 'application/pdf',
        bytes: bytes,
        timeout: const Duration(seconds: 60),
      );
      return UploadSuccess(_documentFromJson(json));
    } on UnauthorizedException {
      rethrow;
    } on ApiException catch (e) {
      return UploadFailure(_safeMessage(e));
    }
  }

  @override
  Future<TutorAskResult> askDocumentQuestion({
    required String documentId,
    required String question,
  }) async {
    try {
      final json = await _client.postJson(
        '/api/v1/documents/ask',
        {'question': question, 'documentId': documentId},
        timeout: const Duration(seconds: 60),
      );
      final answer = (json['answer'] as String?) ?? '';
      final grounded = json['grounded'] as bool? ?? false;
      final insufficient = json['insufficientEvidence'] as bool? ?? false;
      final citations = (json['citations'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (insufficient) {
        return TutorNoAnswer(
          answer.isNotEmpty
              ? answer
              : "Nova couldn't find enough information in this document "
                  'to answer that.',
        );
      }
      return TutorAnswer(
        text: answer,
        sources: [
          for (final c in citations) _sourceFromCitation(documentId, c),
        ],
        grounded: grounded,
      );
    } on UnauthorizedException {
      rethrow;
    } on NotFoundException {
      return const TutorFailure(
        'This document is not available. It may have been removed.',
      );
    } on AiUnavailableException {
      return const TutorUnavailable('Document AI is not connected yet.');
    } on ApiException catch (e) {
      return TutorFailure(_safeMessage(e));
    }
  }

  @override
  Future<PracticeGenerationResult> generateDocumentPractice({
    required String documentId,
    required PracticeSetup setup,
  }) async =>
      const PracticeUnavailable('AI practice is not connected yet.');

  @override
  Future<PracticeEvaluationResult> evaluatePracticeAnswer({
    required String documentId,
    required String questionId,
    required String selectedAnswer,
  }) async =>
      const PracticeEvaluationUnavailable(
        "Practice evaluation isn't connected yet.",
      );

  static StudyDocument _documentFromJson(Map<String, dynamic> json) {
    final status = _statusFromBackend(json['status'] as String?);
    final contentType = (json['contentType'] as String?) ?? '';
    final filename = (json['filename'] as String?) ?? 'Document';
    return StudyDocument(
      id: (json['id'] as String?) ?? '',
      title: filename,
      fileType: _fileTypeOf(filename, contentType),
      status: status,
    );
  }

  static DocumentStatus _statusFromBackend(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'INDEXED':
        return DocumentStatus.ready;
      case 'UPLOADED':
      case 'EXTRACTING':
      case 'CHUNKED':
        return DocumentStatus.processing;
      case 'FAILED':
        return DocumentStatus.failed;
      default:
        return DocumentStatus.unavailable;
    }
  }

  static DocumentFileType _fileTypeOf(String filename, String contentType) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf') || contentType.contains('pdf')) {
      return DocumentFileType.pdf;
    }
    return DocumentFileType.unknown;
  }

  /// Backend citation strings carry `doc:<id>:v<version>#p<page>c<chunk>`.
  /// The page renders when the shape matches; otherwise the raw backend
  /// string is shown verbatim as the reference (never parsed further,
  /// never invented).
  static GroundedSource _sourceFromCitation(String documentId, String raw) {
    final match = _citationRe.firstMatch(raw.trim());
    if (match != null) {
      final page = int.tryParse(match.group(3) ?? '');
      return GroundedSource(
        documentId: documentId,
        page: page,
      );
    }
    return GroundedSource(documentId: documentId, section: raw);
  }

  /// ApiException messages are user-safe by codebase convention.
  static String _safeMessage(ApiException e) =>
      e.message.isNotEmpty ? e.message : 'Something went wrong. Please try again.';
}
