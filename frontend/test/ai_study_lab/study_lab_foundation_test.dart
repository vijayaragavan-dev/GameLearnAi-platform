// RAG-FE-1 — AI Study Lab UI foundation: lab, workspace, cards,
// upload sheet, honest unavailable states, responsive + themes.
// Fixture documents below are LOCAL UI FIXTURES ONLY — clearly marked,
// never presented as backend data (the document service does not exist).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/ai_study_lab/data/study_lab_repository.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_document.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/ai_study_lab_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/document_tutor_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/document_workspace_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/widgets/upload_sheet.dart';

/// Clearly marked LOCAL UI fixtures (test-only, never backend data).
const _readyDoc = StudyDocument(
  id: 'doc-ready-1',
  title: 'Quantum Notes',
  fileType: DocumentFileType.pdf,
  status: DocumentStatus.ready,
  topicCount: 6,
  lastStudiedLabel: 'Studied 2h ago',
  progressFraction: 0.5,
);
const _processingDoc = StudyDocument(
  id: 'doc-processing-1',
  title: 'Thermo Draft',
  fileType: DocumentFileType.docx,
  status: DocumentStatus.processing,
);
const _failedDoc = StudyDocument(
  id: 'doc-failed-1',
  title: 'Broken Scan',
  fileType: DocumentFileType.pdf,
  status: DocumentStatus.failed,
  failureMessage: 'Could not read this file.',
);
const _unavailableDoc = StudyDocument(
  id: 'doc-unavailable-1',
  title: 'Old Archive',
  fileType: DocumentFileType.txt,
  status: DocumentStatus.unavailable,
);

class _FixtureLabRepository extends EmptyStudyLabRepository {
  _FixtureLabRepository(this.docs);

  final List<StudyDocument> docs;
  int fetchCount = 0;

  @override
  Future<List<StudyDocument>> documents() async {
    fetchCount++;
    return docs;
  }

  @override
  Future<StudyDocument?> documentById(String id) async {
    fetchCount++;
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }
}

class _FailingLabRepository extends EmptyStudyLabRepository {
  int fetchCount = 0;

  @override
  Future<List<StudyDocument>> documents() async {
    fetchCount++;
    // Async throw (like real transport failures): a synchronous throw
    // would escape setState instead of surfacing via FutureBuilder.
    await Future<void>.delayed(Duration.zero);
    throw Exception('service down');
  }

  @override
  Future<StudyDocument?> documentById(String id) async {
    fetchCount++;
    await Future<void>.delayed(Duration.zero);
    throw Exception('service down');
  }
}

GoRouter _router() => GoRouter(
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
    GoRoute(
      path: Routes.tutor,
      builder: (_, _) => const Text('NOVA'),
    ),
  ],
);

/// Audio/haptics CTA paths read SharedPreferences (bootstrap override in
/// production): mock it for every harness pump.
Future<ProviderScope> _scopedAppAsync(
  GoRouter router,
  StudyLabRepository? repo,
) async {
  SharedPreferences.setMockInitialValues(const {});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWith((ref) => prefs),
      if (repo != null) studyLabRepoProvider.overrideWith((ref) => repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpScopedApp(
  WidgetTester tester,
  GoRouter router, [
  StudyLabRepository? repo,
]) async {
  await tester.pumpWidget(await _scopedAppAsync(router, repo));
}

/// Workspace-capable router (lab + workspace + real tutor target).
GoRouter _workspaceRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
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
    GoRoute(
      path: '/ai-study-lab/document/:documentId/tutor',
      builder: (_, s) => DocumentTutorScreen(
        documentId: s.pathParameters['documentId']!,
      ),
    ),
    GoRoute(path: Routes.tutor, builder: (_, _) => const Text('NOVA')),
  ],
);

Future<void> _setSize(WidgetTester tester, double w, double h) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Fixed-duration pumps: NovaCompanion breathes on a repeat loop, so
/// pumpAndSettle never settles (established repo convention).
Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('routes', () {
    test('AI Study Lab route helpers', () {
      expect(Routes.aiStudyLab, '/ai-study-lab');
      expect(
        Routes.aiStudyDocument('doc-1'),
        '/ai-study-lab/document/doc-1',
      );
      // Shell tabs untouched by this feature.
      expect(Routes.home, '/home');
      expect(Routes.subjects, '/subjects');
      expect(Routes.progress, '/progress');
      expect(Routes.profile, '/profile');
    });
  });

  group('AI Study Lab screen', () {
    testWidgets('renders hero, actions, and premium empty state',
        (tester) async {
      await _setSize(tester, 390, 844);
      // Production binding: honestly empty library, no overrides.
      await _pumpScopedApp(tester, _router());
      await _pump(tester);

      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(find.text('Turn your documents', skipOffstage: false),
        findsNothing);
      expect(
        find.textContaining(
          'Turn your documents into an interactive',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      for (final label in ['Upload', 'Ask Nova', 'Practice', 'Continue']) {
        expect(find.text(label, skipOffstage: false), findsOneWidget);
      }
      expect(find.text('Your Study Lab is empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Upload opens the upload sheet', (tester) async {
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(tester, _router());
      await _pump(tester);

      await tester.tap(find.text('Your Study Lab is empty'));
      await tester.ensureVisible(find.text('UPLOAD DOCUMENT').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('UPLOAD DOCUMENT').first);
      await _pump(tester);
      expect(find.text('Upload your study material'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('locked quick action shows honest dialog, no navigation',
        (tester) async {
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(tester, _router());
      await _pump(tester);

      await tester.tap(find.text('Practice'));
      await _pump(tester);
      expect(find.text('Practice — Coming next'), findsOneWidget);
      // Still on the lab — nothing fake was opened.
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(find.text('NOVA'), findsNothing);
      await tester.tap(find.text('NOT NOW'));
      await _pump(tester);
      expect(find.text('Practice — Coming next'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading state renders, then empty', (tester) async {
      final gate = Completer<List<StudyDocument>>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete(const <StudyDocument>[]);
      });
      final repo = _LoadingLabRepository(gate.future);
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(tester, _router(), repo);
      await tester.pump();
      expect(find.text('Preparing your study lab...'), findsOneWidget);
      gate.complete(const <StudyDocument>[]);
      await _pump(tester);
      expect(find.text('Your Study Lab is empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error state renders with retry', (tester) async {
      final repo = _FailingLabRepository();
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(tester, _router(), repo);
      await _pump(tester);

      expect(find.text('Your Study Lab is empty'), findsNothing);
      await tester.tap(find.text('TRY AGAIN'));
      await _pump(tester);
      expect(repo.fetchCount, greaterThanOrEqualTo(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fixture documents render with honest states', (tester) async {
      final repo = _FixtureLabRepository(const [
        _readyDoc,
        _processingDoc,
        _failedDoc,
        _unavailableDoc,
      ]);
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(tester, _router(), repo);
      await _pump(tester);

      expect(find.text('Quantum Notes', skipOffstage: false), findsOneWidget);
      expect(find.text('Thermo Draft', skipOffstage: false), findsOneWidget);
      expect(find.text('Broken Scan', skipOffstage: false), findsOneWidget);
      expect(find.text('Old Archive', skipOffstage: false), findsOneWidget);
      expect(find.text('READY', skipOffstage: false), findsOneWidget);
      expect(find.text('PROCESSING', skipOffstage: false), findsOneWidget);
      expect(find.text('FAILED', skipOffstage: false), findsOneWidget);
      expect(find.text('UNAVAILABLE', skipOffstage: false), findsOneWidget);
      expect(find.text('6 topics', skipOffstage: false), findsOneWidget);
      expect(find.text('No topics yet', skipOffstage: false), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a card opens its workspace by id', (tester) async {
      final repo = _FixtureLabRepository(const [_readyDoc]);
      final router = _router();
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(tester, router, repo);
      await _pump(tester);

      await tester.ensureVisible(find.text('Quantum Notes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Quantum Notes'));
      await _pump(tester);
      expect(
        find.text('LEARN WITH THIS DOCUMENT', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Ask Nova about this document'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Document workspace', () {
    testWidgets('renders header, overview, Nova entry, four actions',
        (tester) async {
      final repo = _FixtureLabRepository(const [_readyDoc]);
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(
        tester,
        _workspaceRouter(Routes.aiStudyDocument('doc-ready-1')),
        repo,
      );
      await _pump(tester);

      expect(find.text('Quantum Notes', skipOffstage: false), findsWidgets);
      expect(find.text('READY', skipOffstage: false), findsOneWidget);
      expect(find.text('6 topics', skipOffstage: false), findsOneWidget);
      for (final label in ['Study', 'Ask Nova', 'Practice', 'Play']) {
        expect(find.text(label, skipOffstage: false), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('locked practice explains honestly; Ask Nova opens tutor',
        (tester) async {
      final repo = _FixtureLabRepository(const [_readyDoc]);
      final router = _workspaceRouter(
        Routes.aiStudyDocument('doc-ready-1'),
      );
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(tester, router, repo);
      await _pump(tester);

      await tester.ensureVisible(
        find.text('No practice generated yet').first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('No practice generated yet').first);
      await _pump(tester);
      expect(
        find.textContaining('Nothing is faked', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('NOVA'), findsNothing);
      await tester.tap(find.text('GOT IT'));
      await _pump(tester);

      // Ask Nova card navigates to the document-grounded tutor.
      await tester.ensureVisible(
        find.text('Ask Nova', skipOffstage: false).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Ask Nova', skipOffstage: false).last);
      await _pump(tester);
      expect(find.text('NOVA TUTOR'), findsWidgets);
      expect(
        find.text('Studying: Quantum Notes', skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('processing and failed states render honestly',
        (tester) async {
      final repo = _FixtureLabRepository(const [_processingDoc, _failedDoc]);
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(
        tester,
        _workspaceRouter(Routes.aiStudyDocument('doc-processing-1')),
        repo,
      );
      await _pump(tester);

      expect(find.text('PROCESSING', skipOffstage: false), findsOneWidget);
      expect(
        find.textContaining('Indexing your document', skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown document renders unavailable, back navigates',
        (tester) async {
      final repo = _FixtureLabRepository(const [_readyDoc]);
      final router = _workspaceRouter(Routes.aiStudyDocument('doc-nope'));
      await _setSize(tester, 390, 844);
      await _pumpScopedApp(tester, router, repo);
      await _pump(tester);

      expect(find.text('Document unavailable'), findsOneWidget);
      await tester.tap(find.text('BACK TO STUDY LAB'));
      await _pump(tester);
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('upload sheet', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      SelectedStudyFile? preview,
    ) async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) => prefs),
          ],
          child: MaterialApp(
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
                      child: UploadSheet(initialPreview: preview),
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
      await _pump(tester);
    }

    testWidgets('renders types, honest stop, disabled upload', (tester) async {
      await _setSize(tester, 390, 844);
      await pumpSheet(tester, null);

      expect(find.text('Upload your study material'), findsWidgets);
      expect(find.text('PDF', skipOffstage: false), findsWidgets);
      expect(find.text('More formats coming'), findsOneWidget);
      expect(
        find.textContaining('stay on this device', skipOffstage: false),
        findsNothing,
      );
      expect(find.text('CANCEL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancel dismisses the sheet', (tester) async {
      await _setSize(tester, 390, 844);
      await pumpSheet(tester, null);

      await tester.tap(find.text('CANCEL'));
      await _pump(tester);
      expect(find.text('Upload your study material'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selected preview renders and removes', (tester) async {
      await _setSize(tester, 390, 844);
      await pumpSheet(
        tester,
        const SelectedStudyFile(
          name: 'algebra-notes.pdf',
          fileType: DocumentFileType.pdf,
        ),
      );

      expect(find.text('algebra-notes.pdf'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove selected document'));
      await _pump(tester);
      expect(find.text('algebra-notes.pdf'), findsNothing);
      // Sheet stays open for choosing again — nothing uploaded.
      expect(find.text('Upload your study material'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive + themes', () {
    Future<void> pumpLab(
      WidgetTester tester,
      double w,
      double h,
      ThemeMode mode,
    ) async {
      tester.view.physicalSize = Size(w, h);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: _router(),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
          ),
        ),
      );
      await _pump(tester);
    }

    testWidgets('390px dark renders without overflow', (tester) async {
      await pumpLab(tester, 390, 844, ThemeMode.dark);
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px light renders without overflow', (tester) async {
      await pumpLab(tester, 320, 844, ThemeMode.light);
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(find.text('Your Study Lab is empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768px renders without overflow', (tester) async {
      await pumpLab(tester, 768, 1024, ThemeMode.dark);
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440px renders without overflow', (tester) async {
      await pumpLab(tester, 1440, 900, ThemeMode.light);
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('360/430/1024/1280 widths render without overflow',
        (tester) async {
      for (final size in const [
        Size(360, 740),
        Size(430, 932),
        Size(1024, 768),
        Size(1280, 800),
      ]) {
        await pumpLab(tester, size.width, size.height, ThemeMode.dark);
        expect(find.text('AI STUDY LAB'), findsWidgets);
        expect(find.text('Your Study Lab is empty'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}

class _LoadingLabRepository extends EmptyStudyLabRepository {
  _LoadingLabRepository(this.future);

  final Future<List<StudyDocument>> future;

  @override
  Future<List<StudyDocument>> documents() => future;
}
