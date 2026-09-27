import '../domain/study_document.dart';
import '../domain/study_practice.dart';
import '../domain/study_tutor.dart';
import '../domain/study_upload.dart';

/// Document-library data seam for the AI Study Lab (RAG-FE-1).
///
/// The MlRag backend/API contract does not exist yet, so this interface
/// declares ONLY what the UI needs and makes NO assumption about REST
/// paths, DTO shapes, or service behavior. A future MlRag-backed
/// implementation will implement this interface and map the real
/// contract onto [StudyDocument]; no screen code changes are required
/// for that step beyond the provider binding.
///
/// Rules for every implementation:
/// - NEVER return fabricated documents: an empty list means "no
///   documents yet" and renders the premium empty state.
/// - NEVER invent topic counts, progress, or recency: leave the
///   corresponding [StudyDocument] fields null and the UI renders
///   honest placeholders.
/// - Failures surface as exceptions handled by the existing app-wide
///   error patterns (never raw errors to the learner).
abstract class StudyLabRepository {
  /// The learner's document library. Empty when nothing was uploaded yet.
  Future<List<StudyDocument>> documents();

  /// Resolve one document by its stable [id], or null when unknown.
  /// Default implementation maps over [documents] by id — never by title.
  Future<StudyDocument?> documentById(String id) async {
    final docs = await documents();
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  /// Attempt an explicit document upload (RAG-FE-2 backend boundary).
  ///
  /// Returns [UploadUnavailable] when no upload service is connected,
  /// [UploadFailure] when the attempt genuinely failed, and
  /// [UploadSuccess] ONLY from a real backend-backed implementation
  /// carrying the authoritative document. Never throws for these
  /// expected service states; transport-level errors follow the
  /// existing app-wide exception patterns.
  Future<UploadResult> uploadDocument(PickedStudyFile file);

  /// Ask Nova about a document (RAG-FE-3 backend boundary).
  ///
  /// [question] is the learner's verbatim text (already trimmed and
  /// length-checked by the UI). Returns [TutorUnavailable] when no
  /// document-AI service is connected, [TutorNoAnswer] when retrieval
  /// genuinely found nothing, [TutorFailure] on genuine errors, and
  /// [TutorAnswer] ONLY from a real backend-backed implementation.
  /// Never throws for these expected service states; transport-level
  /// errors follow the existing app-wide exception patterns.
  Future<TutorAskResult> askDocumentQuestion({
    required String documentId,
    required String question,
  });

  /// Generate an AI practice set for a document (RAG-FE-4 boundary).
  ///
  /// [setup] carries frontend preferences only (count/difficulty);
  /// mapping to backend values happens in the real implementation.
  /// Returns [PracticeUnavailable] when no service is connected,
  /// [PracticeEmpty] when generation genuinely yields zero questions,
  /// [PracticeGenerationFailure] on genuine errors, and
  /// [PracticeSetReady] ONLY from a real backend-backed implementation.
  /// Never throws for these expected service states.
  Future<PracticeGenerationResult> generateDocumentPractice({
    required String documentId,
    required PracticeSetup setup,
  });

  /// Evaluate one submitted practice answer (RAG-FE-4 boundary).
  ///
  /// Returns [PracticeEvaluated] ONLY from a real backend-backed
  /// implementation, [PracticeEvaluationUnavailable] when no service
  /// is connected, [PracticeEvaluationFailure] on genuine errors.
  /// Learning evaluation only: never XP, mastery, streak, or game
  /// results — this system never touches gamification.
  Future<PracticeEvaluationResult> evaluatePracticeAnswer({
    required String documentId,
    required String questionId,
    required String selectedAnswer,
  });
}

/// RAG-FE-1 placeholder: no document service exists yet.
///
/// Reports an honestly empty library so the Study Lab renders its
/// premium empty state (never fixtures, never invented documents).
/// Replaced by the MlRag-backed implementation once the API contract
/// lands; the provider binding is the only change required.
class EmptyStudyLabRepository implements StudyLabRepository {
  const EmptyStudyLabRepository();

  @override
  Future<List<StudyDocument>> documents() async =>
      const <StudyDocument>[];

  @override
  Future<StudyDocument?> documentById(String id) async => null;

  /// No upload service exists: explicit unavailable result (never a
  /// fabricated success, never thrown). The sheet maps this to its
  /// honest unavailable state with Try Again / Cancel.
  @override
  Future<UploadResult> uploadDocument(PickedStudyFile file) async =>
      const UploadUnavailable('Document services are currently unavailable.');

  /// No document-AI service exists: explicit unavailable result (never
  /// a fabricated answer, never thrown). The tutor maps this to its
  /// honest unavailable notice with retry affordance.
  @override
  Future<TutorAskResult> askDocumentQuestion({
    required String documentId,
    required String question,
  }) async => const TutorUnavailable('Document AI is not connected yet.');

  /// No practice service exists: explicit unavailable result (never a
  /// fabricated set, never thrown). The setup screen maps this to its
  /// honest unavailable state with retry/back actions.
  @override
  Future<PracticeGenerationResult> generateDocumentPractice({
    required String documentId,
    required PracticeSetup setup,
  }) async => const PracticeUnavailable('AI practice is not connected yet.');

  /// No evaluation service exists: explicit unavailable result (never
  /// a fabricated verdict, never thrown). The question screen keeps
  /// the selection and explains honestly instead.
  @override
  Future<PracticeEvaluationResult> evaluatePracticeAnswer({
    required String documentId,
    required String questionId,
    required String selectedAnswer,
  }) async => const PracticeEvaluationUnavailable(
    "Practice evaluation isn't connected yet.",
  );
}
