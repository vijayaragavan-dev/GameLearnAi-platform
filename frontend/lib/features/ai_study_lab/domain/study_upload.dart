import 'study_document.dart';

/// A locally picked file awaiting upload.
///
/// Presentation-layer value only: name + byte size as reported by the
/// platform picker, plus the bytes themselves once the real upload
/// contract is connected. Local filesystem paths are deliberately NOT
/// captured — they must never reach the UI.
class PickedStudyFile {
  const PickedStudyFile({required this.name, required this.sizeBytes, this.bytes});

  final String name;

  /// Byte size as reported by the picker; null when the platform
  /// did not report one (display shows no size, never a guess).
  final int? sizeBytes;

  /// File bytes for upload. Null for fixture/test-only selections
  /// (which never reach the repository upload path).
  final List<int>? bytes;

  DocumentFileType get inferredType {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return DocumentFileType.pdf;
    if (lower.endsWith('.docx')) return DocumentFileType.docx;
    if (lower.endsWith('.txt')) return DocumentFileType.txt;
    return DocumentFileType.unknown;
  }
}

/// Pure frontend validation outcome. No backend limits are invented:
/// only type/readability rules the product itself defines.
class FileValidation {
  const FileValidation._(this.valid, this.errorMessage);

  const FileValidation.valid() : this._(true, null);
  const FileValidation.invalid(String message) : this._(false, message);

  final bool valid;

  /// User-facing message (already honest copy, no technical details).
  final String? errorMessage;
}

/// Validates a picked file WITHOUT inventing backend requirements.
///
/// Rules (product-owned only):
/// - empty selection → invalid (empty)
/// - non-PDF extension → invalid ("PDF files are currently supported.")
/// - zero/negative reported size → invalid (unreadable)
/// - no maximum size: no backend limit exists, so none is claimed.
FileValidation validatePickedFile({required String name, int? sizeBytes}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const FileValidation.invalid("This file can't be uploaded.");
  }
  if (!trimmed.toLowerCase().endsWith('.pdf')) {
    return const FileValidation.invalid('PDF files are currently supported.');
  }
  if (sizeBytes != null && sizeBytes <= 0) {
    return const FileValidation.invalid(
      "We couldn't read this file. Please choose another PDF.",
    );
  }
  return const FileValidation.valid();
}

/// Human-readable byte size for selected-file preview. Null/negative
/// input yields null (caller renders no size, never a guess).
String? formatStudyFileSize(int? sizeBytes) {
  if (sizeBytes == null || sizeBytes < 0) return null;
  if (sizeBytes < 1024) return '$sizeBytes B';
  final kb = sizeBytes / 1024;
  if (kb < 1024) {
    final text = kb >= 100
        ? kb.toStringAsFixed(0)
        : kb.toStringAsFixed(1);
    return '$text KB';
  }
  final mb = kb / 1024;
  final text = mb >= 100 ? mb.toStringAsFixed(0) : mb.toStringAsFixed(1);
  return '$text MB';
}

/// Explicit upload outcome (RAG-FE-2 backend boundary).
///
/// The repository returns one of these instead of throwing for expected
/// service states, so the sheet maps deterministically to UI. Only a
/// REAL backend-backed implementation may ever return [UploadSuccess];
/// placeholder/test doubles must use [UploadUnavailable]/[UploadFailure].
sealed class UploadResult {
  const UploadResult();
}

/// Real upload accepted the document. Carries the authoritative
/// [StudyDocument] to open — never synthesized client-side.
class UploadSuccess extends UploadResult {
  const UploadSuccess(this.document);

  final StudyDocument document;
}

/// No upload service connected (current RAG-FE-1/2 reality).
class UploadUnavailable extends UploadResult {
  const UploadUnavailable(this.message);

  final String message;
}

/// Upload attempted but failed (transport/validation/server-side).
class UploadFailure extends UploadResult {
  const UploadFailure(this.message);

  final String message;
}
