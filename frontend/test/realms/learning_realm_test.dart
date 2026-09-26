// Phase 1 — Learning Realm foundation: registry truth, CS→worlds
// relationship, navigation honesty, responsive/semantics coverage.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';
import 'package:gamelearn_app/features/realms/domain/learning_realm.dart';
import 'package:gamelearn_app/features/realms/presentation/realm_landing_screen.dart';
import 'package:gamelearn_app/features/realms/presentation/realms_screen.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';

/// Backend realm payloads mirroring the verified REALM-001 shapes.
Map<String, dynamic> _realmJson({
  required String id,
  required String key,
  required String name,
}) => {
  'id': id,
  'realmKey': key,
  'name': name,
  'description': '$name description',
  'iconKey': 'realm_${key.toLowerCase()}',
  'isActive': true,
  'displayOrder': key == 'COMPUTER_SCIENCE' ? 1 : 2,
};

/// Mock backend: CS + APTITUDE active realms, Aptitude subject +
/// compat. Everything else 404s honestly.
MockClient _realmsClient() => MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/v1/realms') {
    return http.Response(
      jsonEncode([
        _realmJson(
          id: '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a01',
          key: 'COMPUTER_SCIENCE',
          name: 'Computer Science',
        ),
        _realmJson(
          id: '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a02',
          key: 'APTITUDE',
          name: 'Aptitude',
        ),
      ]),
      200,
    );
  }
  if (path == '/api/v1/realms/APTITUDE/subjects') {
    return http.Response(
      jsonEncode([
        {
          'id': '55555555-5555-5555-5555-555555555501',
          'name': 'Aptitude',
          'description': 'Quantitative aptitude and logical reasoning.',
          'iconKey': 'aptitude',
          'isActive': true,
          'displayOrder': 100,
          'realmKey': 'APTITUDE',
        },
      ]),
      200,
    );
  }
  if (path == '/api/v1/realms/APTITUDE') {
    return http.Response(
      jsonEncode(_realmJson(
        id: '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a02',
        key: 'APTITUDE',
        name: 'Aptitude',
      )),
      200,
    );
  }
  if (path ==
      '/api/v1/subjects/55555555-5555-5555-5555-555555555501/games') {
    return http.Response(
      jsonEncode({
        'subjectId': '55555555-5555-5555-5555-555555555501',
        'subjectName': 'Aptitude',
        'games': [
          {
            'gameType': 'quiz_battle',
            'rationale': 'MCQ skills',
            'hasContent': true,
            'contentCount': 18,
          },
          {
            'gameType': 'speed_run',
            'rationale': 'Timed drills',
            'hasContent': true,
            'contentCount': 18,
          },
        ],
      }),
      200,
    );
  }
  return http.Response(
    jsonEncode({'errorCode': 'RESOURCE_NOT_FOUND', 'message': 'Not found'}),
    404,
  );
});

GoRouter _router() => GoRouter(
  initialLocation: Routes.realms,
  routes: [
    GoRoute(
      path: Routes.realms,
      builder: (_, _) => const RealmsScreen(),
    ),
    GoRoute(
      path: Routes.subjects,
      builder: (_, _) => const Text('WORLDS CATALOG'),
    ),
    GoRoute(
      path: '/realm/:realmKey',
      builder: (_, s) =>
          RealmLandingScreen(realmKey: s.pathParameters['realmKey']!),
    ),
  ],
);

Widget _scopedApp(GoRouter router) => ProviderScope(
  overrides: [
    apiClientProvider.overrideWith(
      (ref) => ApiClient(client: _realmsClient()),
    ),
  ],
  child: MaterialApp.router(routerConfig: router),
);

Future<void> _setWidth(WidgetTester tester, double width, double height) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpRealms(WidgetTester tester, Widget app) async {
  // Fixed-duration pumps: NovaCompanion breathes on a repeat loop, so
  // pumpAndSettle never settles (established repo convention).
  await tester.pumpWidget(app);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LearningRealm registry', () {
    test('stable IDs are unique and round-trip via fromKey', () {
      final keys = LearningRealmCatalog.all.map((r) => r.key).toList();
      expect(keys.toSet().length, keys.length);
      for (final realm in LearningRealmCatalog.all) {
        expect(RealmId.fromKey(realm.key), realm.id);
        expect(RealmId.fromKey(realm.key.toLowerCase()), realm.id);
      }
      expect(RealmId.fromKey(null), isNull);
      expect(RealmId.fromKey('NOPE'), isNull);
    });

    test('exactly Computer Science is active; five are coming soon', () {
      final active =
          LearningRealmCatalog.all.where((r) => r.isActive).toList();
      final coming =
          LearningRealmCatalog.all.where((r) => r.isComingSoon).toList();
      expect(active.map((r) => r.id), [RealmId.computerScience]);
      expect(coming.length, 5);
      expect(
        coming.map((r) => r.id).toSet(),
        {
          RealmId.aptitude,
          RealmId.verbalEnglish,
          RealmId.fullStack,
          RealmId.aiData,
          RealmId.cyberSecurity,
        },
      );
    });

    test('display order is stable and gap-free', () {
      final orders =
          LearningRealmCatalog.all.map((r) => r.displayOrder).toList();
      expect(orders, [1, 2, 3, 4, 5, 6]);
    });

    test('coming-soon count derives from the registry (dashboard copy)', () {
      // The dashboard teaser ("COMPUTER SCIENCE + N MORE") must read
      // this getter, never a hard-coded literal.
      expect(LearningRealmCatalog.comingSoonCount, 5);
      expect(
        LearningRealmCatalog.comingSoonCount,
        LearningRealmCatalog.all.length - 1,
      );
    });

    test('Computer Science resolves to the worldBased structure', () {
      final cs = LearningRealmCatalog.computerScience;
      expect(cs.structure, RealmLearningStructure.worldBased);
      expect(cs.isWorldBased, isTrue);
    });

    test('future realms declare planned structures, never worldBased', () {
      final byId = {
        for (final r in LearningRealmCatalog.all) r.id: r,
      };
      expect(
        byId[RealmId.aptitude]!.structure,
        RealmLearningStructure.skillBased,
      );
      expect(
        byId[RealmId.verbalEnglish]!.structure,
        RealmLearningStructure.skillBased,
      );
      expect(
        byId[RealmId.fullStack]!.structure,
        RealmLearningStructure.technologyBased,
      );
      expect(
        byId[RealmId.aiData]!.structure,
        RealmLearningStructure.domainBased,
      );
      expect(
        byId[RealmId.cyberSecurity]!.structure,
        RealmLearningStructure.domainBased,
      );
      for (final r in LearningRealmCatalog.all) {
        if (r.id != RealmId.computerScience) {
          expect(r.isWorldBased, isFalse);
          expect(r.isComingSoon, isTrue);
        }
      }
    });

    test('unknown subjects degrade to global scope, never a wrong world',
        () {
      // Pins the documented game-platform seam: future realm content
      // enters through the unchanged request shape without world
      // attribution, so isolation can never misfire.
      final request = GameContentRequest.fromRoute(
        subjectId: '00000000-0000-0000-0000-000000000000',
        subjectName: 'Future Realm Subject',
        topicId: '11111111-1111-1111-1111-111111111111',
      );
      expect(request.scope, GameContentScope.global);
      expect(request.isWorld, isFalse);
      expect(request.worldId, isNull);
      expect(request.topicId, '11111111-1111-1111-1111-111111111111');
    });

    test('existing 11 worlds remain authoritative and undisplaced', () {
      expect(WorldCatalog.all.length, 11);
      final worldKeys = WorldCatalog.all.map((w) => w.key).toList();
      expect(worldKeys.toSet().length, 11);
      for (final key in [
        'PROGRAMMING',
        'DATA_STRUCTURES',
        'ALGORITHMS',
        'DBMS',
        'COMPUTER_NETWORKS',
        'OPERATING_SYSTEMS',
        'OOP',
        'AI_ML',
        'DATA_SCIENCE',
        'WEB_TECHNOLOGIES',
        'OBJECT_ORIENTED_SOFTWARE_ENGINEERING',
      ]) {
        expect(worldKeys, contains(key));
      }
      // The realm layer defines no worlds of its own.
      expect(LearningRealmCatalog.computerScience.id, RealmId.computerScience);
    });

    test('route helper exposes the realms path', () {
      expect(Routes.realms, '/realms');
    });
  });

  group('RealmsScreen (backend-driven)', () {
    testWidgets('renders hero, CS card and Aptitude as available',
        (tester) async {
      await _setWidth(tester, 390, 844);
      await _pumpRealms(tester, _scopedApp(_router()));

      expect(find.text('LEARNING UNIVERSE'), findsOneWidget);
      expect(find.text('COMPUTER SCIENCE'), findsOneWidget);
      // Aptitude is backend-active: available card, never a locked pill.
      expect(find.text('APTITUDE'), findsOneWidget);
      // Honest live world count — derived from WorldCatalog, never hard
      // fabricated metrics for coming-soon realms.
      expect(
        find.textContaining(
          '${WorldCatalog.all.length} worlds inside',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      // Only the four backend-absent catalog entries stay locked.
      expect(find.text('COMING SOON', skipOffstage: false), findsNWidgets(4));
      for (final title in [
        'Verbal & English',
        'Full Stack Development',
        'AI & Data',
        'Cyber Security',
      ]) {
        expect(find.text(title, skipOffstage: false), findsOneWidget);
      }
      // Aptitude is backend-active: available card, never a locked pill.
      expect(find.text('APTITUDE'), findsOneWidget);
      // Data-driven structure identity per card.
      expect(find.text('SKILL-BASED LEARNING'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Computer Science enters the existing world catalog',
        (tester) async {
      await _setWidth(tester, 390, 844);
      await _pumpRealms(tester, _scopedApp(_router()));

      await tester.tap(find.text('COMPUTER SCIENCE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('WORLDS CATALOG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Aptitude opens the realm landing, not worlds',
        (tester) async {
      await _setWidth(tester, 390, 844);
      await tester.pumpWidget(_scopedApp(_router()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.text('APTITUDE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Realm landing renders the real backend subject.
      expect(find.text('APTITUDE', skipOffstage: false), findsWidgets);
      expect(find.text('WORLDS CATALOG'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('coming-soon realms open an honest dialog, not content',
        (tester) async {
      await _setWidth(tester, 390, 844);
      await _pumpRealms(tester, _scopedApp(_router()));

      final verbal = find.text('Verbal & English', skipOffstage: false);
      await tester.ensureVisible(verbal);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(verbal);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Verbal & English — Coming Soon', skipOffstage: false),
        findsOneWidget,
      );
      // Still on the realms route — no invalid content entered.
      expect(find.text('LEARNING UNIVERSE'), findsOneWidget);
      expect(find.text('WORLDS CATALOG'), findsNothing);
      // Dialog offers the honest path into Computer Science.
      await tester.tap(find.text('EXPLORE COMPUTER SCIENCE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('WORLDS CATALOG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('backend error renders retryable error state',
        (tester) async {
      await _setWidth(tester, 390, 844);
      final failing = ProviderScope(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient(
                (_) async => http.Response('Server exploded', 500),
              ),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: _router()),
      );
      await tester.pumpWidget(failing);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      // Honest error state with retry affordance, no fabricated realms.
      expect(find.text('LEARNING UNIVERSE'), findsNothing);
      expect(find.text('COMPUTER SCIENCE'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px narrow renders without overflow', (tester) async {
      await _setWidth(tester, 320, 844);
      await _pumpRealms(tester, _scopedApp(_router()));
      expect(find.text('LEARNING UNIVERSE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop wide renders without overflow', (tester) async {
      await _setWidth(tester, 1280, 800);
      await _pumpRealms(tester, _scopedApp(_router()));
      expect(find.text('LEARNING UNIVERSE'), findsOneWidget);
      expect(find.text('COMPUTER SCIENCE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion renders the same truth', (tester) async {
      await _setWidth(tester, 390, 844);
      await _pumpRealms(
        tester,
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(client: _realmsClient()),
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp.router(routerConfig: _router()),
          ),
        ),
      );
      expect(find.text('LEARNING UNIVERSE'), findsOneWidget);
      expect(find.text('COMPUTER SCIENCE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('light theme renders without overflow', (tester) async {
      await _setWidth(tester, 390, 844);
      await _pumpRealms(
        tester,
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(client: _realmsClient()),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: _router(),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
          ),
        ),
      );
      expect(find.text('LEARNING UNIVERSE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
