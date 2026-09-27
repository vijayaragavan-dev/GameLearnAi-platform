// RAG-FE-4 — AI-generated document practice: setup, generation,
// question, evaluation, explanation, sources, result, review.
// Fixtures are LOCAL UI FIXTURES ONLY (test files, never production
// paths, never backend data, never official quiz content).
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
import 'package:gamelearn_app/features/ai_study_lab/domain/study_practice.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_tutor.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/ai_study_lab_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/document_practice_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/document_workspace_screen.dart';

/// Clearly marked LOCAL UI fixtures (test-only, never backend data,
/// never official quiz content).
const _fixtureDoc = StudyDocument(
  id: 'doc-practice-1',
  title: 'Data Structures',
  fileType: DocumentFileType.pdf,
  status: DocumentStatus.ready,
  topicCount: 4,
);

const _q1 = GeneratedPracticeQuestion(
  id: 'pq-1',
  questionText: 'What is a tree?',
  options: [
    'A hierarchical structure',
    'A flat list',
    'A loop',
    'A graph cycle',
  ],
  difficulty: 'Easy',
  explanation: 'Trees organize data in parent-child hierarchies.',
  sources: [
    GroundedSource(
      documentId: 'doc-practice-1',
      documentTitle: 'Data Structures',
      page: 4,
      section: 'Introduction to Trees',
      snippet: 'Trees organize data hierarchically.',
    ),
  ],
);

const _q2 = GeneratedPracticeQuestion(
  id: 'pq-2',
  questionText: 'What is a node?',
  options: ['A single element', 'A full tree', 'An edge only', 'A cycle'],
  difficulty: 'Easy',
  explanation: 'Each element of a tree is called a node.',
);

const _q3 = GeneratedPracticeQuestion(
  id: 'pq-3',
  questionText: 'What is a leaf?',
  options: ['A node without children', 'The root', 'An edge', 'A branch'],
  difficulty: 'Medium',
);

const _fixtureSet = GeneratedPracticeSet(
  documentId: 'doc-practice-1',
  questions: [_q1, _q2, _q3],
);

/// TEST DOUBLE ONLY — deterministic scripted generation/evaluation.
/// Production MUST use EmptyStudyLabRepository (never sets/answers).
/// Never copy this pattern into production code.
class _PracticeStubRepository extends EmptyStudyLabRepository {
  _PracticeStubRepository({
    this.set = _fixtureSet,
    this.unavailableOnGenerate = false,
    this.failOnGenerate = false,
    this.emptySet = false,
    this.unavailableOnEvaluate = false,
    this.failOnEvaluate = false,
    this.gate,
  });

  final GeneratedPracticeSet? set;
  final bool unavailableOnGenerate;
  final bool failOnGenerate;
  final bool emptySet;
  final bool unavailableOnEvaluate;
  final bool failOnEvaluate;
  final Completer<void>? gate;
  int generateCount = 0;
  int evaluateCount = 0;

  static const _answers = {
    'pq-1': 'A hierarchical structure',
    'pq-2': 'A single element',
    'pq-3': 'A node without children',
  };

  @override
  Future<List<StudyDocument>> documents() async => [_fixtureDoc];

  @override
  Future<StudyDocument?> documentById(String id) async =>
      id == _fixtureDoc.id ? _fixtureDoc : null;

  @override
  Future<PracticeGenerationResult> generateDocumentPractice({
    required String documentId,
    required PracticeSetup setup,
  }) async {
    generateCount++;
    final g = gate;
    if (g != null) await g.future;
    if (unavailableOnGenerate) {
      return const PracticeUnavailable('AI practice is not connected yet.');
    }
    if (failOnGenerate) {
      return const PracticeGenerationFailure('Boom.');
    }
    if (emptySet) {
      return const PracticeEmpty('No practice questions were generated.');
    }
    return PracticeSetReady(set!);
  }

  @override
  Future<PracticeEvaluationResult> evaluatePracticeAnswer({
    required String documentId,
    required String questionId,
    required String selectedAnswer,
  }) async {
    evaluateCount++;
    if (unavailableOnEvaluate) {
      return const PracticeEvaluationUnavailable(
        "Practice evaluation isn't connected yet.",
      );
    }
    if (failOnEvaluate) {
      return const PracticeEvaluationFailure('Boom.');
    }
    final correct = _answers[questionId];
    final ok = selectedAnswer == correct;
    // No evaluation-carried explanation: the UI must fall back to the
    // question's own explanation (null-safe path under test).
    return PracticeEvaluated(
      PracticeEvaluation(isCorrect: ok, correctAnswer: correct),
    );
  }
}

Future<ProviderScope> _scopedPractice(
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

GoRouter _practiceRouter(String docId) => GoRouter(
  initialLocation: Routes.aiStudyPractice(docId),
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
      path: '/ai-study-lab/document/:documentId/practice',
      builder: (_, s) => DocumentPracticeScreen(
        documentId: s.pathParameters['documentId']!,
      ),
    ),
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

/// Drive a full 3-question run: Q1 correct, Q2 wrong, Q3 correct.
Future<void> _answerAll(WidgetTester tester) async {
  const picks = [
    'A hierarchical structure',
    'An edge only',
    'A node without children',
  ];
  for (var q = 0; q < 3; q++) {
    await tester.ensureVisible(find.text(picks[q]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(picks[q]));
    await tester.pump();
    await tester.tap(find.text('SUBMIT ANSWER'));
    await _pump(tester);
    if (q < 2) {
      await tester.ensureVisible(find.text('NEXT QUESTION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('NEXT QUESTION'));
      await _pump(tester);
    }
  }
  // Last question shows SEE RESULT instead of NEXT QUESTION.
  await tester.ensureVisible(find.text('SEE RESULT'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('SEE RESULT'));
  await _pump(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('routes', () {
    test('practice route helpers', () {
      expect(
        Routes.aiStudyPractice('doc-9'),
        '/ai-study-lab/document/doc-9/practice',
      );
    });

    testWidgets('workspace Practice card navigates to practice',
        (tester) async {
      final repo = _PracticeStubRepository();
      await _setSize(tester, 390, 844);
      // Start on the workspace, then navigate via the Practice card.
      final workspaceRouter = GoRouter(
        initialLocation: Routes.aiStudyDocument('doc-practice-1'),
        routes: [
          GoRoute(
            path: '/ai-study-lab/document/:documentId',
            builder: (_, s) => DocumentWorkspaceScreen(
              documentId: s.pathParameters['documentId']!,
            ),
          ),
          GoRoute(
            path: '/ai-study-lab/document/:documentId/practice',
            builder: (_, s) => DocumentPracticeScreen(
              documentId: s.pathParameters['documentId']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(await _scopedPractice(workspaceRouter, repo));
      await _pump(tester);

      await tester.ensureVisible(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Practice', skipOffstage: false).first);
      await _pump(tester);
      expect(find.text('AI PRACTICE'), findsWidgets);
      expect(find.text('GENERATE PRACTICE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invalid document shows unavailable with back action',
        (tester) async {
      final repo = _PracticeStubRepository();
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(_practiceRouter('doc-nope'), repo),
      );
      await _pump(tester);

      expect(find.text('Document unavailable'), findsOneWidget);
      await tester.tap(find.text('BACK TO STUDY LAB'));
      await _pump(tester);
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('setup', () {
    testWidgets('shows document context and preference controls',
        (tester) async {
      final repo = _PracticeStubRepository();
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(_practiceRouter('doc-practice-1'), repo),
      );
      await _pump(tester);

      expect(find.text('AI GENERATED'), findsOneWidget);
      expect(
        find.textContaining('Based on: Data Structures', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Generate practice from this document'), findsOneWidget);
      for (final label in ['5', '10', '15', 'Easy', 'Medium', 'Hard']) {
        expect(find.text(label, skipOffstage: false), findsWidgets);
      }
      expect(find.text('GENERATE PRACTICE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('count and difficulty selection updates', (tester) async {
      final repo = _PracticeStubRepository();
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(_practiceRouter('doc-practice-1'), repo),
      );
      await _pump(tester);

      await tester.tap(find.text('10'));
      await tester.pump();
      await tester.tap(find.text('Hard'));
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('^10 questions, selected')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Hard difficulty, selected')),
        findsOneWidget,
      );
      expect(repo.generateCount, 0);
      expect(tester.takeException(), isNull);
    });
    testWidgets('unavailable generation shows retry and back',
        (tester) async {
      // Production default (EmptyStudyLabRepository) path uses the same
      // unavailable UI; the stub mirrors it deterministically here.
      // NOTE: exactly one pumpWidget per test — re-pumping same-typed
      // roots updates state in place instead of replacing it.
      final unavailable =
          _PracticeStubRepository(unavailableOnGenerate: true);
      final router = _practiceRouter('doc-practice-1');
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(router, unavailable),
      );
      await _pump(tester);
      await tester.tap(find.text('GENERATE PRACTICE'));
      await _pump(tester);
      expect(find.text('AI practice isn’t ready yet'), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(find.text('BACK TO WORKSPACE'), findsOneWidget);
      await tester.tap(find.text('BACK TO WORKSPACE'));
      await _pump(tester);
      expect(find.text('LEARN WITH THIS DOCUMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('generation failure renders honestly', (tester) async {
      final failing = _PracticeStubRepository(failOnGenerate: true);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(_practiceRouter('doc-practice-1'), failing),
      );
      await _pump(tester);
      await tester.tap(find.text('GENERATE PRACTICE'));
      await _pump(tester);
      expect(find.text("We couldn't generate practice."), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty generated set renders honestly', (tester) async {
      final empty = _PracticeStubRepository(emptySet: true);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(_practiceRouter('doc-practice-1'), empty),
      );
      await _pump(tester);
      await tester.tap(find.text('GENERATE PRACTICE'));
      await _pump(tester);
      expect(
        find.text('No practice questions were generated.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('generation', () {
    testWidgets('generating indicator shows while pending', (tester) async {
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      final repo = _PracticeStubRepository(gate: gate);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(_practiceRouter('doc-practice-1'), repo),
      );
      await _pump(tester);
      await tester.tap(find.text('GENERATE PRACTICE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Building your practice set…'), findsOneWidget);
      gate.complete();
      await _pump(tester);
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('question and evaluation', () {
    Future<void> pumpReady(WidgetTester tester, _PracticeStubRepository repo,
        [String docId = 'doc-practice-1']) async {
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(_practiceRouter(docId), repo),
      );
      await _pump(tester);
      await tester.tap(find.text('GENERATE PRACTICE'));
      await _pump(tester);
    }

    testWidgets('question renders with options and progress', (tester) async {
      await pumpReady(tester, _PracticeStubRepository());
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(find.text('What is a tree?'), findsOneWidget);
      for (final option in [
        'A hierarchical structure',
        'A flat list',
        'A loop',
        'A graph cycle',
      ]) {
        expect(find.text(option, skipOffstage: false), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('submit disabled before selection', (tester) async {
      final repo = _PracticeStubRepository();
      await pumpReady(tester, repo);
      await tester.tap(find.text('SUBMIT ANSWER'));
      await tester.pump();
      expect(repo.evaluateCount, 0);
      expect(
        find.bySemanticsLabel(RegExp('^Correct answer')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('selection then submit shows correct feedback', (tester) async {
      final repo = _PracticeStubRepository();
      await pumpReady(tester, repo);
      // Correctness must not be revealed before submission.
      expect(
        find.bySemanticsLabel(RegExp('^Correct answer')),
        findsNothing,
      );

      await tester.tap(find.text('A hierarchical structure'));
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          RegExp('^Option A: A hierarchical structure, selected'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('SUBMIT ANSWER'));
      await _pump(tester);

      expect(
        find.bySemanticsLabel(RegExp('^Correct answer')),
        findsOneWidget,
      );
      expect(find.text('Correct — nicely done.'), findsOneWidget);
      expect(find.text('Trees organize data in parent-child hierarchies.'),
        findsOneWidget);
      expect(find.text('Page 4'), findsOneWidget);
      expect(repo.evaluateCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('incorrect feedback marks the pick', (tester) async {
      final repo = _PracticeStubRepository();
      await pumpReady(tester, repo);
      await tester.tap(find.text('A flat list'));
      await tester.pump();
      await tester.tap(find.text('SUBMIT ANSWER'));
      await _pump(tester);

      expect(
        find.bySemanticsLabel(RegExp('^Incorrect answer')),
        findsOneWidget,
      );
      expect(find.text('Not quite — see why below.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('evaluation unavailable keeps selection honestly',
        (tester) async {
      final repo = _PracticeStubRepository(unavailableOnEvaluate: true);
      await pumpReady(tester, repo);
      await tester.tap(find.text('A hierarchical structure'));
      await tester.pump();
      await tester.tap(find.text('SUBMIT ANSWER'));
      await _pump(tester);

      expect(
        find.text("Practice evaluation isn't connected yet."),
        findsOneWidget,
      );
      // No verdict rendered, selection preserved for retry.
      expect(
        find.bySemanticsLabel(RegExp('^Correct answer')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Incorrect answer')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('navigation and result', () {
    Future<void> pumpRun(WidgetTester tester, _PracticeStubRepository repo,
        [String docId = 'doc-practice-1']) async {
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedPractice(_practiceRouter(docId), repo),
      );
      await _pump(tester);
      await tester.tap(find.text('GENERATE PRACTICE'));
      await _pump(tester);
    }

    testWidgets('next, final, result counts, no XP', (tester) async {
      final repo = _PracticeStubRepository();
      await pumpRun(tester, repo);
      await _answerAll(tester);

      expect(find.text('Practice Complete'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Answered 3')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Correct 2')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Accuracy 67%')),
        findsOneWidget,
      );
      expect(find.textContaining('XP', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('review shows your vs correct answers', (tester) async {
      final repo = _PracticeStubRepository();
      await pumpRun(tester, repo);
      await _answerAll(tester);

      await tester.ensureVisible(find.text('REVIEW ANSWERS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('REVIEW ANSWERS'));
      await _pump(tester);

      expect(
        find.text('Q1. What is a tree?', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Your answer', skipOffstage: false), findsWidgets);
      expect(find.text('Correct answer', skipOffstage: false), findsWidgets);
      expect(find.text('HIDE REVIEW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('practice again resets to setup', (tester) async {
      final repo = _PracticeStubRepository();
      await pumpRun(tester, repo);
      await _answerAll(tester);

      await tester.ensureVisible(find.text('PRACTICE AGAIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('PRACTICE AGAIN'));
      await _pump(tester);

      expect(find.text('GENERATE PRACTICE'), findsOneWidget);
      expect(find.text('Practice Complete'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('back to workspace navigates', (tester) async {
      final repo = _PracticeStubRepository();
      await pumpRun(tester, repo);
      await _answerAll(tester);

      await tester.ensureVisible(find.text('BACK TO WORKSPACE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('BACK TO WORKSPACE'));
      await _pump(tester);

      expect(find.text('LEARN WITH THIS DOCUMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive + themes', () {
    Future<void> pumpPractice(
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
              (ref) => _PracticeStubRepository(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: _practiceRouter('doc-practice-1'),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
          ),
        ),
      );
      await _pump(tester);
    }

    testWidgets('320px dark renders without overflow', (tester) async {
      await pumpPractice(tester, 320, 844, ThemeMode.dark);
      expect(find.text('AI PRACTICE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390px light renders without overflow', (tester) async {
      await pumpPractice(tester, 390, 844, ThemeMode.light);
      expect(find.text('AI PRACTICE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768px renders without overflow', (tester) async {
      await pumpPractice(tester, 768, 1024, ThemeMode.dark);
      expect(find.text('AI PRACTICE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440px renders without overflow', (tester) async {
      await pumpPractice(tester, 1440, 900, ThemeMode.light);
      expect(find.text('AI PRACTICE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
