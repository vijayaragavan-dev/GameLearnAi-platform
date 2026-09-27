// RAG-FE-5 — RAG content → game engine integration: adapter units,
// capability matrix, selection navigation, official-content isolation.
// Fixtures are LOCAL UI FIXTURES ONLY (test files, never production
// paths, never backend data, never official quiz content).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/models/quiz_models.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/ai_study_lab/data/study_lab_repository.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/rag_game_adapter.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/rag_game_capability.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_document.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_practice.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/ai_study_lab_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/document_workspace_screen.dart';
import 'package:gamelearn_app/features/ai_study_lab/presentation/rag_game_selection_screen.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';

/// Clearly marked LOCAL UI fixtures (test-only, never backend data,
/// never official quiz content).
const _fixtureDoc = StudyDocument(
  id: 'doc-game-1',
  title: 'Data Structures',
  fileType: DocumentFileType.pdf,
  status: DocumentStatus.ready,
  topicCount: 4,
);

const _testRagQuestion = GeneratedPracticeQuestion(
  id: 'rq-1',
  questionText: 'What is a tree?',
  options: ['A hierarchical structure', 'A flat list', 'A loop'],
  difficulty: 'Easy',
  explanation: 'Trees organize data in parent-child hierarchies.',
);

GeneratedPracticeQuestion _q(
  String id,
  String text,
  List<String> options, {
  String? difficulty = 'Medium',
}) => GeneratedPracticeQuestion(
  id: id,
  questionText: text,
  options: options,
  difficulty: difficulty,
);

class _FixtureLabRepository extends EmptyStudyLabRepository {
  _FixtureLabRepository(this.docs);

  final List<StudyDocument> docs;

  @override
  Future<List<StudyDocument>> documents() async => docs;

  @override
  Future<StudyDocument?> documentById(String id) async {
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }
}

Future<ProviderScope> _scopedGames(
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

GoRouter _gamesRouter(String docId) => GoRouter(
  initialLocation: Routes.aiStudyPlay(docId),
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
      path: '/ai-study-lab/document/:documentId/play',
      builder: (_, s) => RagGameSelectionScreen(
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('capability matrix (audited, static)', () {
    test('covers all 14 engine games exactly once', () {
      expect(RagGameCapabilityRegistry.all, hasLength(14));
      final ids = RagGameCapabilityRegistry.all.map((c) => c.gameType).toSet();
      expect(ids, hasLength(14));
      expect(ids, GameType.values.toSet());
    });

    test('exactly Quiz Battle and Speed Run are shape-mappable', () {
      final mappable = RagGameCapabilityRegistry.mappable;
      expect(
        mappable.map((c) => c.gameType).toSet(),
        {GameType.quizBattle, GameType.speedRun},
      );
      for (final c in mappable) {
        expect(c.needs, RagContentNeed.question);
        expect(c.playable, isFalse);
        expect(c.reason, isNotEmpty);
      }
    });

    test('nothing is playable without backend RAG content', () {
      expect(RagGameCapabilityRegistry.playable, isEmpty);
    });

    test('custom games carry structural reasons', () {
      final debug = RagGameCapabilityRegistry.forGame(GameType.debugArena);
      expect(debug.needs, RagContentNeed.custom);
      expect(debug.playable, isFalse);
      expect(debug.specialRules, isNotNull);
      final connectivity =
          RagGameCapabilityRegistry.forGame(GameType.connectivityLab);
      expect(connectivity.specialRules, isNotNull);
      final snake =
          RagGameCapabilityRegistry.forGame(GameType.snakeAndLadder);
      expect(snake.specialRules, contains('starting level'));
      for (final c in RagGameCapabilityRegistry.all) {
        expect(c.reason, isNotEmpty);
      }
    });
  });

  group('quiz adapter (fail-closed, pure)', () {
    test('valid questions map verbatim with provenance', () {
      final before = _q('rq-1', 'What is a tree?', const ['A', 'B']);
      final bundle = RagQuizAdapter.toQuizBundle(
        documentId: 'doc-game-1',
        documentTitle: 'Data Structures',
        questions: [
          before,
          _q('rq-2', 'What is a node?', const ['C', 'D'], difficulty: 'hard'),
        ],
      );
      expect(bundle.documentId, 'doc-game-1');
      expect(bundle.documentTitle, 'Data Structures');
      expect(bundle.total, 2);
      expect(bundle.questions[0], isA<QuizQuestion>());
      expect(bundle.questions[0].questionText, 'What is a tree?');
      expect(bundle.questions[0].options, ['A', 'B']);
      expect(bundle.questions[0].difficulty, 'MEDIUM');
      // Backend order preserved, never shuffled.
      expect(bundle.questions[1].id, 'rq-2');
      expect(bundle.questions[1].difficulty, 'HARD');
      // Official model carries no answers by construction.
      expect(bundle.questions[0].options, isNot(contains('answer-key')));
    });

    test('invalid items are skipped, empty input rejected', () {
      // All invalid: empty id, blank text, single option, bad difficulty.
      expect(
        () => RagQuizAdapter.toQuizBundle(
          documentId: 'd',
          documentTitle: 't',
          questions: [
            _q('', 'Text?', const ['A', 'B']),
            _q('x', '   ', const ['A', 'B']),
            _q('y', 'Text?', const ['Only']),
            _q('z', 'Text?', const ['A', 'B'], difficulty: 'EXTREME'),
          ],
        ),
        throwsA(isA<RagIncompatible>()),
      );
      expect(
        () => RagQuizAdapter.toQuizBundle(
          documentId: 'd',
          documentTitle: 't',
          questions: const [],
        ),
        throwsA(isA<RagIncompatible>()),
      );
    });

    test('partially invalid input keeps valid items in order', () {
      final bundle = RagQuizAdapter.toQuizBundle(
        documentId: 'd',
        documentTitle: 't',
        questions: [
          _q('bad', '   ', const ['A', 'B']),
          _q('rq-1', 'What is a tree?', const ['A', 'B']),
        ],
      );
      expect(bundle.total, 1);
      expect(bundle.questions.single.id, 'rq-1');
    });

    test('inputs are never mutated', () {
      final q = _q('rq-1', '  What is a tree?  ', const [' A ', 'B']);
      RagQuizAdapter.toQuizBundle(
        documentId: 'd',
        documentTitle: 't',
        questions: [q],
      );
      expect(q.questionText, '  What is a tree?  ');
      expect(q.options, [' A ', 'B']);
    });
  });

  group('routes', () {
    test('play route helpers', () {
      expect(
        Routes.aiStudyPlay('doc-9'),
        '/ai-study-lab/document/doc-9/play',
      );
    });
  });

  group('game selection screen', () {
    testWidgets('workspace Play card navigates to game selection',
        (tester) async {
      final repo = _FixtureLabRepository(const [_fixtureDoc]);
      final router = GoRouter(
        initialLocation: Routes.aiStudyDocument('doc-game-1'),
        routes: [
          GoRoute(
            path: '/ai-study-lab/document/:documentId',
            builder: (_, s) => DocumentWorkspaceScreen(
              documentId: s.pathParameters['documentId']!,
            ),
          ),
          GoRoute(
            path: '/ai-study-lab/document/:documentId/play',
            builder: (_, s) => RagGameSelectionScreen(
              documentId: s.pathParameters['documentId']!,
            ),
          ),
        ],
      );
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(await _scopedGames(router, repo));
      await _pump(tester);

      await tester.ensureVisible(find.text('Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Play', skipOffstage: false).first);
      await _pump(tester);
      expect(find.text('PLAY WITH DOCUMENT'), findsOneWidget);
      expect(find.text('Play with Data Structures'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all 14 games with honest pills', (tester) async {
      final repo = _FixtureLabRepository(const [_fixtureDoc]);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedGames(_gamesRouter('doc-game-1'), repo),
      );
      await _pump(tester);

      expect(find.text('PLAY WITH DOCUMENT'), findsOneWidget);
      expect(find.text('Play with Data Structures'), findsOneWidget);
      for (final name in [
        'Quiz Battle',
        'Speed Run',
        'Memory Match',
        'Debug Arena',
        'Snake & Ladder',
      ]) {
        expect(find.text(name, skipOffstage: false), findsOneWidget);
      }
      // 2 mappable (coming later) + 12 structural (not available).
      expect(find.text('COMING LATER', skipOffstage: false), findsNWidgets(2));
      expect(
        find.text('NOT AVAILABLE', skipOffstage: false),
        findsNWidgets(12),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('mappable game explains backend dependency', (tester) async {
      final repo = _FixtureLabRepository(const [_fixtureDoc]);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedGames(_gamesRouter('doc-game-1'), repo),
      );
      await _pump(tester);

      await tester.ensureVisible(find.text('Quiz Battle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Quiz Battle'));
      await _pump(tester);
      expect(find.text('Quiz Battle — Coming later'), findsOneWidget);
      expect(
        find.textContaining('server grading', skipOffstage: false),
        findsOneWidget,
      );
      // Still on selection — nothing launched.
      expect(find.text('PLAY WITH DOCUMENT'), findsWidgets);
      await tester.tap(find.text('GOT IT'));
      await _pump(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom game explains structural reason', (tester) async {
      final repo = _FixtureLabRepository(const [_fixtureDoc]);
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(
        await _scopedGames(_gamesRouter('doc-game-1'), repo),
      );
      await _pump(tester);

      await tester.ensureVisible(find.text('Debug Arena'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Debug Arena'));
      await _pump(tester);
      expect(find.text('Debug Arena unavailable'), findsOneWidget);
      expect(
        find.textContaining('Programming-only', skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown document renders unavailable with back action',
        (tester) async {
      final repo = _FixtureLabRepository(const [_fixtureDoc]);
      final router = GoRouter(
        initialLocation: Routes.aiStudyPlay('doc-nope'),
        routes: [
          GoRoute(
            path: Routes.aiStudyLab,
            builder: (_, _) => const AiStudyLabScreen(),
          ),
          GoRoute(
            path: '/ai-study-lab/document/:documentId/play',
            builder: (_, s) => RagGameSelectionScreen(
              documentId: s.pathParameters['documentId']!,
            ),
          ),
        ],
      );
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(await _scopedGames(router, repo));
      await _pump(tester);

      expect(find.text('Document unavailable'), findsOneWidget);
      await tester.tap(find.text('BACK TO STUDY LAB'));
      await _pump(tester);
      expect(find.text('AI STUDY LAB'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive + themes', () {
    Future<void> pumpSelection(
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
              (ref) => _FixtureLabRepository(const [_fixtureDoc]),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: _gamesRouter('doc-game-1'),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
          ),
        ),
      );
      await _pump(tester);
    }

    testWidgets('320px dark renders without overflow', (tester) async {
      await pumpSelection(tester, 320, 844, ThemeMode.dark);
      expect(find.text('PLAY WITH DOCUMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390px light renders without overflow', (tester) async {
      await pumpSelection(tester, 390, 844, ThemeMode.light);
      expect(find.text('PLAY WITH DOCUMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768px renders without overflow', (tester) async {
      await pumpSelection(tester, 768, 1024, ThemeMode.dark);
      expect(find.text('PLAY WITH DOCUMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440px renders without overflow', (tester) async {
      await pumpSelection(tester, 1440, 900, ThemeMode.light);
      expect(find.text('PLAY WITH DOCUMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
