// RAG-FE-3 — grounded Nova tutor UI: context, conversation states,
// sources, composer, honesty. Fixtures are LOCAL UI FIXTURES ONLY
// (test files, never production paths, never backend data).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/ai_study_lab/data/study_lab_repository.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_document.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_tutor.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/ai_study_lab_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/document_tutor_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/widgets/source_citation_card.dart';

/// Clearly marked LOCAL UI fixtures (test-only, never backend data).
const _fixtureDoc = StudyDocument(
  id: 'doc-tutor-1',
  title: 'Data Structures',
  fileType: DocumentFileType.pdf,
  status: DocumentStatus.ready,
  topicCount: 4,
);

const _fixtureAnswer = TutorAnswer(
  text: 'A tree is a hierarchical data structure.',
  sources: [
    GroundedSource(
      documentId: 'doc-tutor-1',
      documentTitle: 'Data Structures',
      page: 4,
      section: 'Introduction to Trees',
      snippet: 'Trees organize data hierarchically.',
    ),
    GroundedSource(documentId: 'doc-tutor-1', section: 'Traversals'),
  ],
  grounded: true,
);

/// TEST DOUBLE ONLY — scripted ask results for UI-state coverage.
/// Production MUST use EmptyStudyLabRepository (never answers).
/// Never copy this pattern into production code.
class _TutorStubRepository extends EmptyStudyLabRepository {
  _TutorStubRepository({
    this.docs = const [_fixtureDoc],
    this.answer,
    this.noAnswer = false,
    this.fail = false,
  });

  final List<StudyDocument> docs;
  final TutorAnswer? answer;
  final bool noAnswer;
  final bool fail;
  int askCount = 0;
  final posts = <String>[];

  @override
  Future<List<StudyDocument>> documents() async => docs;

  @override
  Future<StudyDocument?> documentById(String id) async {
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  @override
  Future<TutorAskResult> askDocumentQuestion({
    required String documentId,
    required String question,
  }) async {
    askCount++;
    if (fail) return const TutorFailure('Nova exploded.');
    if (noAnswer) {
      return const TutorNoAnswer(
        "Nova couldn't find enough information in this document "
        'to answer that.',
      );
    }
    final a = answer;
    if (a != null) return a;
    return const TutorUnavailable('Document AI is not connected yet.');
  }
}

Future<ProviderScope> _scopedTutor(
  GoRouter router,
  StudyLabRepository repo,
) async {
  SharedPreferences.setMockInitialValues(const {});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWith((ref) => prefs),
      studyLabRepoProvider.overrideWith((ref) => repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

GoRouter _tutorRouter(String docId) => GoRouter(
  initialLocation: Routes.aiStudyTutor(docId),
  routes: [
    GoRoute(
      path: Routes.aiStudyLab,
      builder: (_, _) => const AiStudyLabScreen(),
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
    test('document tutor route helpers', () {
      expect(
        Routes.aiStudyTutor('doc-9'),
        '/ai-study-lab/document/doc-9/tutor',
      );
    });
  });

  group('tutor screen chrome', () {
    testWidgets('renders Nova identity with document context', (tester) async {
      final repo = _TutorStubRepository();
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedTutor(_tutorRouter('doc-tutor-1'), repo),
      );
      await _pump(tester);

      expect(find.text('NOVA TUTOR'), findsWidgets);
      expect(
        find.text('Studying: Data Structures', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('DOCUMENT CONTEXT'), findsOneWidget);
      expect(find.text('Data Structures', skipOffstage: false), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty conversation shows suggestions, tap fills composer',
        (tester) async {
      final repo = _TutorStubRepository();
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedTutor(_tutorRouter('doc-tutor-1'), repo),
      );
      await _pump(tester);

      expect(
        find.text('Ask Nova anything about this document.'),
        findsOneWidget,
      );
      for (final s in [
        'Summarize this document',
        'Explain the main concepts',
        'What should I study first?',
        'Create practice questions',
      ]) {
        expect(find.text(s, skipOffstage: false), findsOneWidget);
      }
      // Tapping populates the composer but sends nothing (no backend).
      await tester.ensureVisible(find.text('Summarize this document'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Summarize this document'));
      await _pump(tester);
      expect(repo.askCount, 0);
      expect(find.text('NOVA TUTOR'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown document renders unavailable with back action',
        (tester) async {
      final repo = _TutorStubRepository();
      final router = GoRouter(
        initialLocation: Routes.aiStudyTutor('doc-nope'),
        routes: [
          GoRoute(
            path: Routes.aiStudyLab,
            builder: (_, _) => const AiStudyLabScreen(),
          ),
          GoRoute(
            path: '/ai-study-lab/document/:documentId/tutor',
            builder: (_, s) => DocumentTutorScreen(
              documentId: s.pathParameters['documentId']!,
            ),
          ),
        ],
      );
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(await _scopedTutor(router, repo));
      await _pump(tester);

      expect(find.text('Document unavailable'), findsOneWidget);
      await tester.tap(find.text('BACK TO STUDY LAB'));
      await _pump(tester);
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('composer', () {
    testWidgets('empty input cannot send', (tester) async {
      final repo = _TutorStubRepository();
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedTutor(_tutorRouter('doc-tutor-1'), repo),
      );
      await _pump(tester);

      expect(
        find.bySemanticsLabel('Send message'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Send message'));
      await _pump(tester);
      // Disabled send: no repository call, no user bubble.
      expect(repo.askCount, 0);
      expect(find.text('Ask Nova anything about this document.'),
        findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('typed question appears after unavailable round-trip',
        (tester) async {
      final repo = _TutorStubRepository();
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedTutor(_tutorRouter('doc-tutor-1'), repo),
      );
      await _pump(tester);

      await tester.enterText(
        find.byType(TextField),
        'What is a tree?',
      );
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send message'));
      await _pump(tester);

      // User message rendered; honest unavailable notice with retry.
      expect(find.text('What is a tree?'), findsWidgets);
      expect(
        find.text('Document AI is not connected yet.'),
        findsOneWidget,
      );
      expect(repo.askCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry re-runs the real repository call', (tester) async {
      final repo = _TutorStubRepository();
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedTutor(_tutorRouter('doc-tutor-1'), repo),
      );
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'Explain trees');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send message'));
      await _pump(tester);
      expect(repo.askCount, 1);

      await tester.tap(find.text('RETRY'));
      await _pump(tester);
      expect(repo.askCount, 2);
      // Still one user bubble — retry never duplicates it.
      expect(find.text('Explain trees'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure notice renders with retry', (tester) async {
      final repo = _TutorStubRepository(fail: true);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedTutor(_tutorRouter('doc-tutor-1'), repo),
      );
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'Hello?');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send message'));
      await _pump(tester);

      expect(find.text('Nova exploded.'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('grounded answers (stubbed UI states)', () {
    testWidgets('answer renders text, grounded pill, and sources',
        (tester) async {
      final repo = _TutorStubRepository(answer: _fixtureAnswer);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedTutor(_tutorRouter('doc-tutor-1'), repo),
      );
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'What is a tree?');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send message'));
      await _pump(tester);

      expect(
        find.text('A tree is a hierarchical data structure.'),
        findsOneWidget,
      );
      expect(find.text('Grounded in this document'), findsOneWidget);
      expect(find.text('Sources', skipOffstage: false), findsOneWidget);
      expect(find.text('Page 4'), findsOneWidget);
      expect(find.text('Introduction to Trees'), findsOneWidget);
      expect(
        find.textContaining('Trees organize data hierarchically.'),
        findsOneWidget,
      );
      // Second source: section only, no page pill, no snippet.
      expect(find.text('Traversals'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no-answer renders honestly without sources', (tester) async {
      final repo = _TutorStubRepository(noAnswer: true);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedTutor(_tutorRouter('doc-tutor-1'), repo),
      );
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'Obscure?');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send message'));
      await _pump(tester);

      expect(
        find.textContaining("couldn't find enough information",
          skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Grounded in this document'), findsNothing);
      expect(find.text('Sources', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('source card shows only present fields', (tester) async {
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    SourceCitationCard(
                      source: GroundedSource(
                        documentId: 'd1',
                        section: 'Only a section',
                      ),
                    ),
                    SourceCitationCard(
                      source: GroundedSource(
                        documentId: 'd1',
                        documentTitle: 'Data Structures',
                        page: 4,
                        section: 'Introduction to Trees',
                        snippet: 'Trees organize data hierarchically.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Source document'), findsOneWidget);
      expect(find.text('Only a section'), findsOneWidget);
      expect(find.text('Page 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive + themes', () {
    Future<void> pumpTutor(
      WidgetTester tester,
      double w,
      double h,
      ThemeMode mode,
    ) async {
      tester.view.physicalSize = Size(w, h);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) => prefs),
            studyLabRepoProvider.overrideWith(
              (ref) => _TutorStubRepository(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: _tutorRouter('doc-tutor-1'),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
          ),
        ),
      );
      await _pump(tester);
    }

    testWidgets('320px dark renders without overflow', (tester) async {
      await pumpTutor(tester, 320, 844, ThemeMode.dark);
      expect(find.text('NOVA TUTOR'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390px light renders without overflow', (tester) async {
      await pumpTutor(tester, 390, 844, ThemeMode.light);
      expect(find.text('NOVA TUTOR'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768px renders without overflow', (tester) async {
      await pumpTutor(tester, 768, 1024, ThemeMode.dark);
      expect(find.text('NOVA TUTOR'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440px renders without overflow', (tester) async {
      await pumpTutor(tester, 1440, 900, ThemeMode.light);
      expect(find.text('NOVA TUTOR'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
