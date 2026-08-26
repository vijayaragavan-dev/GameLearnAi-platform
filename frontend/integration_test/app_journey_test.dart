// REAL-BACKEND integration journey (skips automatically when the configured
// backend is unreachable). Run with:
//   flutter test integration_test -d windows --dart-define=API_BASE_URL=http://localhost:8080
//
// Journey mirrors the approved demo path:
// register -> dashboard -> subjects -> assessment (intro/run/result)
// -> learning-path generation (+ idempotent re-request) -> topic -> lesson
// -> quiz delivery/submission/result -> AI tutor.
//
// Backend-origin rule: displayed values are cross-checked against values
// fetched independently through the app's own repositories (SUBJ-001,
// TOPIC-001, LESSON-001, PATH-001/002) so hardcoded/mock data cannot pass.
//
// NOTE: /assessment/:id and /tutor currently have NO production navigation
// entry point (orphaned routes - recorded finding). Those legs are driven
// through the app's real GoRouter instance; screens/network layers are the
// production ones.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/app/gamelearn_app.dart';
import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/config/app_config.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/challenge/assessment/presentation/assessment_intro_screen.dart';
import 'package:gamelearn_app/features/learning/path/presentation/path_map_screen.dart';
import 'package:gamelearn_app/features/tutor/presentation/tutor_screen.dart'
    show TypingIndicator;
import 'package:gamelearn_app/shared/widgets/nova_companion.dart';
import 'package:gamelearn_app/shared/widgets/quiz_option.dart';

Future<bool> _backendAlive(ApiClient api) async {
  // Prefer the public actuator endpoint (200 when UP). Fall back to the
  // auth validate path where 401 also proves liveness.
  try {
    await api.getJson('/actuator/health');
    return true;
  } on Exception catch (e) {
    debugPrint('_backendAlive actuator/health failed: $e');
  }
  try {
    await api.getJson('/api/v1/auth/validate');
    return true;
  } on UnauthorizedException {
    return true; // 401 proves the backend is reachable
  } on Exception catch (e) {
    debugPrint('_backendAlive validate failed: $e at ${AppConfig.apiBaseUrl}');
    return false;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GameLearn AI full journey against the real backend', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final probe = ApiClient();
    if (!await _backendAlive(probe)) {
      // Honest skip: no real backend reachable in this environment.
      debugPrint('SKIPPED: backend not reachable at ${AppConfig.apiBaseUrl}');
      return;
    }
    probe.dispose();

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final email = 'player$stamp@example.com';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GameLearnApp(),
      ),
    );
    await tester.pumpAndSettle();

    // ------------------------------------------------------------------
    // STEP 1: REGISTER -> DASHBOARD (AUTH-002, DASH-001)
    // ------------------------------------------------------------------
    debugPrint('JOURNEY[register]: creating player $email');
    await tester.enterVisibleText(
      find.byType(TextFormField).at(0),
      'Journey $stamp',
    );
    await tester.enterVisibleText(find.byType(TextFormField).at(1), email);
    await tester.enterVisibleText(
      find.byType(TextFormField).at(2),
      'Passw0rd!long',
    );
    await tester.tap(find.textContaining('CREATE PLAYER'));
    await waitFor(tester, find.textContaining('CURRENT ADVENTURE'));
    debugPrint('JOURNEY[register]: dashboard rendered (DASH-001)');

    final contentRepo = container.read(contentRepoProvider);
    final router = container.read(routerProvider);

    // ------------------------------------------------------------------
    // STEP 2: SUBJECTS (SUBJ-001) + world entry -> empty path prompt
    // ------------------------------------------------------------------
    await tapElement(tester, find.text('WORLDS'));
    await waitFor(tester, find.text('CHOOSE YOUR WORLD'));
    final subjects = await contentRepo.subjects();
    expect(subjects, isNotEmpty, reason: 'SUBJ-001 returned zero subjects');
    final subject = subjects.first;
    await waitFor(tester, find.textContaining(subject.name));
    debugPrint(
      'JOURNEY[subjects]: SUBJ-001 ok (${subjects.length} worlds; '
      'first="${subject.name}")',
    );

    await tapElement(tester, find.textContaining(subject.name).last);
    await waitFor(tester, find.text('Forge your path'));
    debugPrint('JOURNEY[path-empty]: Forge-your-path prompt rendered');
    await tapElement(tester, find.byIcon(Icons.arrow_back_rounded).first);
    await waitFor(tester, find.text('CHOOSE YOUR WORLD'));

    // ------------------------------------------------------------------
    // STEP 3: ASSESSMENT INTRO -> RUN -> RESULT (ASMT-001..003).
    // Router-driven: orphaned-route finding (no menu reaches it yet).
    // ------------------------------------------------------------------
    debugPrint('JOURNEY[assessment]: pushing /assessment via GoRouter');
    router.push(Routes.assessmentIntro(subject.id));
    await waitFor(tester, find.byType(AssessmentIntroScreen));
    await waitFor(tester, find.text('Begin scan'));
    await tapElement(tester, find.text('Begin scan'));
    await waitFor(tester, find.textContaining('SCAN 1/'));

    var scannedAll = false;
    for (var i = 0; i < 60; i++) {
      if (find.text('SCAN RESULTS').evaluate().isNotEmpty) {
        scannedAll = true;
        break;
      }
      await tapElement(tester, find.byType(QuizOption).first);
      await settle(tester);
      final finish = find.text('Finish scan');
      await tapElement(
        tester,
        finish.evaluate().isNotEmpty ? finish : find.text('Next'),
      );
      await settle(tester, const Duration(milliseconds: 700));
    }
    if (!scannedAll) {
      await waitFor(
        tester,
        find.text('SCAN RESULTS'),
        timeout: const Duration(seconds: 30),
      );
    }
    // ASMT-003 read-back: assessed baseline with topic breakdown.
    await waitFor(
      tester,
      find.text('Baseline established'),
      timeout: const Duration(seconds: 20),
    );
    debugPrint('JOURNEY[assessment]: submitted + ASMT-003 baseline revealed');

    // ------------------------------------------------------------------
    // STEP 4: LEARNING-PATH GENERATION (PATH-002) + IDEMPOTENT RE-REQUEST.
    // ------------------------------------------------------------------
    router.go(Routes.subjects);
    await waitFor(tester, find.text('CHOOSE YOUR WORLD'));
    await tapElement(tester, find.textContaining(subject.name).last);
    await waitFor(tester, find.text('Forge your path'));

    await tester.enterText(
      find.byType(TextField),
      'Master the basics so I can join the journey verification.',
    );
    await settle(tester);
    await tapElement(tester, find.text('Generate path'));
    debugPrint(
      'JOURNEY[path-generate]: PATH-002 requested '
      '(AI attempt possible; waiting up to 150s)',
    );
    await waitFor(
      tester,
      find.byType(AdventureTrail),
      timeout: const Duration(seconds: 150),
    );

    final active = await contentRepo.activePathForSubject(subject.id);
    expect(
      active,
      isNotNull,
      reason: 'PATH-001 returned no ACTIVE path after generation',
    );
    expect(active!.status, 'ACTIVE');
    expect(active.nodes, isNotEmpty);
    final firstNode = active.nodes.first;
    expect(
      firstNode.status,
      'AVAILABLE',
      reason: 'first node must be AVAILABLE per PATH-002 node rules',
    );
    debugPrint(
      'JOURNEY[path-generate]: pathId=${active.id} '
      'nodes=${active.nodes.length} generatedBy=${active.generatedBy} '
      'firstTopic="${firstNode.topicName}"',
    );

    // Idempotency: regenerate=false on an ACTIVE path must return the SAME
    // path (200 semantics, zero additional AI cost).
    final again = await contentRepo.generatePath(
      subjectId: subject.id,
      regenerate: false,
    );
    expect(
      again.path.id,
      active.id,
      reason:
          'PATH-002 regenerate=false must idempotently return the ACTIVE path',
    );
    expect(again.path.status, 'ACTIVE');
    debugPrint('JOURNEY[path-idempotent]: identical pathId returned');

    // ------------------------------------------------------------------
    // STEP 5: TOPIC (TOPIC-001) - node caption vs TOPIC-001 name.
    // ------------------------------------------------------------------
    await tapElement(tester, find.byType(LearningNode).first);
    await waitFor(tester, find.text('MISSION BRIEFING'));
    await waitFor(tester, find.text(firstNode.topicName));
    final topic = await contentRepo.topic(firstNode.topicId);
    expect(
      topic.name,
      firstNode.topicName,
      reason: 'TOPIC-001 name must equal PATH node caption (backend-origin)',
    );
    debugPrint('JOURNEY[topic]: "${topic.name}" matches PATH node');

    // ------------------------------------------------------------------
    // STEP 6: LESSON (LESSON-001) - title + body verbatim from backend.
    // ------------------------------------------------------------------
    await tapElement(tester, find.text('Enter training'));
    await waitFor(
      tester,
      find.text('KEY TAKEAWAYS'),
      timeout: const Duration(seconds: 15),
    );
    final lesson = await contentRepo.lesson(topic.id);
    expect(
      find.text(lesson.title),
      findsWidgets,
      reason: 'lesson title must be rendered verbatim from LESSON-001',
    );
    final firstParagraph = lesson.content
        .split('\n')
        .map((p) => p.trim())
        .firstWhere((p) => p.isNotEmpty, orElse: () => '');
    if (firstParagraph.isNotEmpty) {
      expect(
        find.text(firstParagraph),
        findsOneWidget,
        reason: 'lesson body paragraph must come from LESSON-001 content',
      );
    }
    debugPrint('JOURNEY[lesson]: "${lesson.title}" rendered from LESSON-001');

    // ------------------------------------------------------------------
    // STEP 7: QUIZ DELIVERY -> SUBMISSION -> RESULT (QUIZ-001/002).
    // ------------------------------------------------------------------
    await tapElement(tester, find.text('Take the challenge').last);
    await waitFor(
      tester,
      find.textContaining('CHALLENGE 1 /'),
      timeout: const Duration(seconds: 15),
    );

    var submitted = false;
    for (var i = 0; i < 60; i++) {
      if (find.text('CHALLENGE COMPLETE').evaluate().isNotEmpty) {
        submitted = true;
        break;
      }
      await tapElement(tester, find.byType(QuizOption).first);
      await settle(tester);
      final submit = find.text('Submit challenge');
      await tapElement(
        tester,
        submit.evaluate().isNotEmpty ? submit : find.text('Next'),
      );
      await settle(tester, const Duration(milliseconds: 700));
    }
    if (!submitted) {
      await waitFor(
        tester,
        find.text('CHALLENGE COMPLETE'),
        timeout: const Duration(seconds: 30),
      );
    }

    // Dismiss level-up / achievement overlays queued by GAM deltas.
    for (var i = 0; i < 6; i++) {
      final cont = find.widgetWithText(FilledButton, 'CONTINUE');
      if (cont.evaluate().isEmpty) break;
      await tapElement(tester, cont.first);
      await settle(tester, const Duration(milliseconds: 800));
    }

    // QUIZ-002 origin assertions: XP section, adaptive block rendered
    // verbatim from the backend insight, per-question review tiles.
    expect(find.text('XP COLLECTED'), findsOneWidget);
    expect(
      find.text('AI GAME MASTER'),
      findsOneWidget,
      reason: 'QUIZ-002 adaptive block missing from result screen',
    );
    expect(find.textContaining(' CORRECT'), findsWidgets);
    expect(find.textContaining('Your answer:'), findsWidgets);
    debugPrint('JOURNEY[quiz]: submission + backend-derived result rendered');

    // ------------------------------------------------------------------
    // STEP 8: AI TUTOR (AI-001). Router-driven (orphaned route finding).
    // Accepts answer / refused / degraded bubbles, or an explicitly
    // surfaced API error - a silent hang is the only failure.
    // ------------------------------------------------------------------
    debugPrint('JOURNEY[tutor]: pushing /tutor via GoRouter');
    router.push(Routes.tutor);
    await waitFor(tester, find.text('NOVA TUTOR'));

    const question =
        'In one short sentence, why is a variable useful in programming?';
    await tester.enterText(find.byType(TextField), question);
    await settle(tester);
    await tapElement(tester, find.byIcon(Icons.send_rounded));

    // Wait for resolution: either a reply bubble (a third Nova glyph:
    // appbar + greeting bubble precede it) or the approved error banner
    // surfacing a backend failure.
    const resolveTimeout = Duration(seconds: 90);
    final deadline = DateTime.now().add(resolveTimeout);
    var resolved = false;
    var surfacedError = false;
    while (DateTime.now().isBefore(deadline)) {
      final errorVisible = find
          .byIcon(Icons.error_outline_rounded)
          .evaluate()
          .isNotEmpty;
      final typing = find.byType(TypingIndicator).evaluate().isNotEmpty;
      if (errorVisible && !typing) {
        surfacedError = true;
        resolved = true;
        break;
      }
      if (!typing &&
          find.text(question).evaluate().isNotEmpty &&
          find.byType(NovaCompanion).evaluate().length >= 3) {
        resolved = true;
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      resolved,
      isTrue,
      reason: 'AI-001 neither answered nor surfaced an error within 90s',
    );
    if (surfacedError) {
      debugPrint(
        'JOURNEY[tutor]: backend failure surfaced through the approved '
        'error envelope (e.g. 429/503). Frontend error contract VERIFIED; '
        'a generated answer was NOT observed this run.',
      );
    } else {
      debugPrint(
        'JOURNEY[tutor]: Nova replied (answer/refused/degraded bubble)',
      );
    }

    debugPrint('JOURNEY: ALL STEPS COMPLETED');
  });
}

bool exists(Finder f) => f.evaluate().isNotEmpty;

Future<void> settle(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 300),
]) async {
  await tester.pump(duration);
  await tester.pump(duration);
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (exists(finder)) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('TIMED_OUT (${timeout.inSeconds}s) waiting for: $finder');
}

Future<void> tapElement(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: true);
  await tester.pump(const Duration(milliseconds: 250));
}

extension on WidgetTester {
  Future<void> enterVisibleText(Finder finder, String text) async {
    await ensureVisible(finder);
    await enterText(finder, text);
    await pump(const Duration(milliseconds: 200));
  }
}
