// RAG-FE-2 — upload + processing experience: validation, picker flow,
// state machine honesty, card states. Fixtures are LOCAL UI FIXTURES
// ONLY (test files, never production paths, never backend data).
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/ai_study_lab/data/study_lab_repository.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_document.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_upload.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/ai_study_lab_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/document_workspace_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/widgets/document_processing_view.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/widgets/upload_sheet.dart';

/// Clearly marked LOCAL UI fixtures (test-only, never backend data).
const _readyDoc = StudyDocument(
  id: 'doc-ready-9',
  title: 'Relativity Notes',
  fileType: DocumentFileType.pdf,
  status: DocumentStatus.ready,
  topicCount: 3,
);
const _processingDoc = StudyDocument(
  id: 'doc-processing-9',
  title: 'Pending Draft',
  fileType: DocumentFileType.pdf,
  status: DocumentStatus.processing,
);
const _failedDoc = StudyDocument(
  id: 'doc-failed-9',
  title: 'Corrupt Scan',
  fileType: DocumentFileType.pdf,
  status: DocumentStatus.failed,
);

class _CountingLabRepository extends EmptyStudyLabRepository {
  _CountingLabRepository(this.docs);

  final List<StudyDocument> docs;
  int fetchCount = 0;

  @override
  Future<List<StudyDocument>> documents() async {
    fetchCount++;
    return docs;
  }

  @override
  Future<StudyDocument?> documentById(String id) async {
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }
}

/// TEST DOUBLE ONLY — exercises the success-handoff navigation with a
/// fixture document. Production MUST use EmptyStudyLabRepository (never
/// success) until the real MlRag implementation lands. Never copy this
/// pattern into production code.
class _HandoffTestRepository extends EmptyStudyLabRepository {
  @override
  Future<UploadResult> uploadDocument(PickedStudyFile file) async =>
      const UploadSuccess(_readyDoc);

  @override
  Future<StudyDocument?> documentById(String id) async =>
      id == _readyDoc.id ? _readyDoc : null;
}

final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile(this._name, this._size);

  final String _name;
  final int? _size;

  @override
  String get name => _name;

  @override
  String? get extension {
    final i = _name.lastIndexOf('.');
    return i < 0 ? null : _name.substring(i + 1);
  }

  @override
  Uri get uri => Uri.file(_name);

  @override
  XFile get xFile => XFile.fromData(Uint8List(0), name: _name);

  @override
  int? lengthSync() => _size;

  @override
  Future<int?> length() async => _size;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => const Stream.empty();
}

class _FakePicker extends FilePickerPlatform with MockPlatformInterfaceMixin {
  _FakePicker(this._respond);

  final Future<PlatformFile?> Function() _respond;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) =>
      _respond();
}

Future<void> _usePicker(Future<PlatformFile?> Function() respond) async {
  final previous = FilePickerPlatform.instance;
  FilePickerPlatform.instance = _FakePicker(respond);
  addTearDown(() => FilePickerPlatform.instance = previous);
}

Future<ProviderScope> _scopedSheet(Widget child) async {
  SharedPreferences.setMockInitialValues(const {});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWith((ref) => prefs)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Future<void> _openSheet(WidgetTester tester, Widget sheetChild) async {
  await tester.pumpWidget(
    await _scopedSheet(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: sheetChild,
            ),
          ),
          child: const Text('OPEN'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _setSize(WidgetTester tester, double w, double h) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('validation (pure, product-owned rules only)', () {
    test('accepts PDF names, case-insensitive', () {
      expect(
        validatePickedFile(name: 'notes.pdf', sizeBytes: 2048).valid,
        isTrue,
      );
      expect(
        validatePickedFile(name: 'NOTES.PDF', sizeBytes: 10).valid,
        isTrue,
      );
    });

    test('rejects non-PDF without inventing limits', () {
      final docx = validatePickedFile(name: 'notes.docx', sizeBytes: 2048);
      expect(docx.valid, isFalse);
      expect(docx.errorMessage, 'PDF files are currently supported.');
      // Large PDFs are allowed: no backend limit exists, none is claimed.
      expect(
        validatePickedFile(name: 'huge.pdf', sizeBytes: 500 * 1024 * 1024)
            .valid,
        isTrue,
      );
    });

    test('rejects empty and unreadable selections', () {
      expect(
        validatePickedFile(name: '   ', sizeBytes: 10).valid,
        isFalse,
      );
      final zero = validatePickedFile(name: 'empty.pdf', sizeBytes: 0);
      expect(zero.valid, isFalse);
      expect(
        zero.errorMessage,
        "We couldn't read this file. Please choose another PDF.",
      );
    });

    test('size formatter never guesses', () {
      expect(formatStudyFileSize(512), '512 B');
      expect(formatStudyFileSize(2048), '2.0 KB');
      expect(formatStudyFileSize(5 * 1024 * 1024), '5.0 MB');
      expect(formatStudyFileSize(null), isNull);
    });
  });

  group('upload sheet flow', () {
    testWidgets('select success shows preview with size', (tester) async {
      await _usePicker(() async => _FakePlatformFile('notes.pdf', 2048));
      await _setSize(tester, 390, 844);
      await _openSheet(tester, const UploadSheet());
      expect(find.text('Upload your study material'), findsOneWidget);

      await tester.tap(find.text('SELECT PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('notes.pdf'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
      expect(find.text('UPLOAD DOCUMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('upload with no service shows unavailable, never success',
        (tester) async {
      await _usePicker(() async => _FakePlatformFile('notes.pdf', 2048));
      await _setSize(tester, 390, 844);
      await _openSheet(tester, const UploadSheet());
      await tester.tap(find.text('SELECT PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('UPLOAD DOCUMENT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Honest unavailable state — no fabricated document, no workspace.
      expect(find.text('Service unavailable'), findsOneWidget);
      expect(
        find.textContaining('currently unavailable', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('LEARN WITH THIS DOCUMENT'), findsNothing);
      // Retry stays honest too.
      await tester.tap(find.text('TRY AGAIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Service unavailable'), findsOneWidget);
      // Cancel dismisses cleanly.
      await tester.tap(find.text('CANCEL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Service unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('replace swaps the preview', (tester) async {
      var second = false;
      await _usePicker(() async {
        second = !second;
        return second
            ? _FakePlatformFile('second.pdf', 100)
            : _FakePlatformFile('first.pdf', 100);
      });
      await _setSize(tester, 390, 844);
      await _openSheet(tester, const UploadSheet());
      await tester.tap(find.text('SELECT PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('second.pdf'), findsOneWidget);

      await tester.tap(find.text('Replace'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('first.pdf'), findsOneWidget);
      expect(find.text('second.pdf'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-PDF is rejected inline, picker cancel stays idle',
        (tester) async {
      var mode = 'docx';
      await _usePicker(() async {
        if (mode == 'cancel') return null;
        return _FakePlatformFile('notes.$mode', 100);
      });
      await _setSize(tester, 390, 844);
      await _openSheet(tester, const UploadSheet());
      await tester.tap(find.text('SELECT PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('PDF files are currently supported.'),
        findsOneWidget,
      );
      expect(find.text('SELECT PDF'), findsOneWidget);

      mode = 'cancel';
      await tester.tap(find.text('SELECT PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SELECT PDF'), findsOneWidget);
      expect(
        find.text('PDF files are currently supported.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('picker failure shows readable error', (tester) async {
      await _usePicker(() async => throw Exception('picker exploded'));
      await _setSize(tester, 390, 844);
      await _openSheet(tester, const UploadSheet());
      await tester.tap(find.text('SELECT PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining("couldn't read this file", skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('success handoff closes sheet and opens workspace',
        (tester) async {
      await _usePicker(() async => _FakePlatformFile('notes.pdf', 100));
      await _setSize(tester, 390, 844);
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: '/sheet-host',
        routes: [
          GoRoute(
            path: '/sheet-host',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: const UploadSheet(),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
          GoRoute(
            path: '/ai-study-lab/document/:documentId',
            builder: (_, s) => DocumentWorkspaceScreen(
              documentId: s.pathParameters['documentId']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) => prefs),
            studyLabRepoProvider.overrideWith(
              (ref) => _HandoffTestRepository(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('SELECT PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('UPLOAD DOCUMENT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Sheet closed; workspace opened for the RETURNED document id.
      expect(find.text('Upload your study material'), findsNothing);
      expect(find.text('Relativity Notes', skipOffstage: false), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('document cards', () {
    Future<GoRouter> pumpLab(
      WidgetTester tester,
      _CountingLabRepository repo,
    ) async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: Routes.aiStudyLab,
        routes: [
          GoRoute(
            path: Routes.aiStudyLab,
            builder: (_, _) => const AiStudyLabScreen(),
          ),
          GoRoute(
            path: '/ai-study-lab/document/:documentId',
            builder: (_, s) => DocumentWorkspaceScreen(
              documentId: s.pathParameters['documentId']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) => prefs),
            studyLabRepoProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      return router;
    }

    testWidgets('processing card is not openable', (tester) async {
      final repo = _CountingLabRepository(const [_processingDoc, _readyDoc]);
      await _setSize(tester, 390, 844);
      final router = await pumpLab(tester, repo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      await tester.ensureVisible(find.text('Pending Draft'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Pending Draft'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Still on the lab: processing documents do not navigate.
      expect(router.state.uri.toString(), Routes.aiStudyLab);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed card retry reloads honestly', (tester) async {
      final repo = _CountingLabRepository(const [_failedDoc]);
      await _setSize(tester, 390, 844);
      await pumpLab(tester, repo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('FAILED', skipOffstage: false), findsOneWidget);
      final before = repo.fetchCount;
      await tester.ensureVisible(find.text('RETRY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('RETRY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Honest reload: one more repository read, same failure shown.
      expect(repo.fetchCount, before + 1);
      expect(find.text('FAILED', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('processing view + themes + widths', () {
    testWidgets('processing view renders without animation controllers',
        (tester) async {
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DocumentProcessingView()),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Preparing your document…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sheet preview at 320px light without overflow',
        (tester) async {
      await _usePicker(() async => _FakePlatformFile('very-long-file-name-that-truncates.pdf', 2048));
      await _setSize(tester, 320, 844);
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWith((ref) => prefs)],
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: const UploadSheet(),
                    ),
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('SELECT PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('very-long-file-name-that-truncates.pdf'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
