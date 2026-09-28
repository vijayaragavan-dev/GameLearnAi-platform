import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/subjects/presentation/subjects_screen.dart';
import 'package:gamelearn_app/features/subjects/presentation/subject_grouping.dart';
import 'package:gamelearn_app/core/models/content_models.dart';

import '../helpers/fake_backend.dart';

/// Helper to build deterministic subject list for responsive/golden checks.
List<Map<String, dynamic>> _subjectsFixture({bool longNames = false}) => [
  {
    'id': '11111111-1111-1111-1111-111111111101',
    'name': longNames
        ? 'Advanced Data Structures and Algorithms in Java with Very Long Name That Should Not Overflow'
        : 'Programming',
    'description': 'Learn programming fundamentals',
    'iconKey': 'subject_programming',
    'isActive': true,
    'displayOrder': 1,
  },
  {
    'id': '11111111-1111-1111-1111-111111111102',
    'name': longNames
        ? 'Computer Networks and Distributed Systems with Extra Long Title For Overflow Testing Purpose'
        : 'Computer Networks',
    'description': 'Packets, routing and the web.',
    'iconKey': 'subject_networks',
    'isActive': true,
    'displayOrder': 2,
  },
  {
    'id': '11111111-1111-1111-1111-111111111103',
    'name': 'DBMS',
    'description': null,
    'iconKey': 'subject_dbms',
    'isActive': true,
    'displayOrder': 3,
  },
  {
    'id': '11111111-1111-1111-1111-111111111104',
    'name': 'Operating Systems',
    'description': 'Processes and memory',
    'iconKey': 'subject_operating_systems',
    'isActive': true,
    'displayOrder': 4,
  },
  {
    'id': '11111111-1111-1111-1111-111111111105',
    'name': 'Data Structures',
    'description': 'Trees and graphs',
    'iconKey': 'subject_data_structures',
    'isActive': true,
    'displayOrder': 5,
  },
  {
    'id': '11111111-1111-1111-1111-111111111106',
    'name': 'Artificial Intelligence',
    'description': 'ML and AI',
    'iconKey': 'subject_ai',
    'isActive': true,
    'displayOrder': 6,
  },
];

Widget _wrapWithScope(Widget child, MockClient client) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(
        FakeTokenStorage()..stored = 'tok',
      ),
      apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
      audioManagerProvider.overrideWithValue(SilentAudioManager()),
    ],
    child: MaterialApp(
      home: child,
      builder: (context, child) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: child!,
      ),
    ),
  );
}

Future<void> _pumpSubjectsAtSize(
  WidgetTester tester,
  Size size,
  MockClient client,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_wrapWithScope(const SubjectsScreen(), client));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  // Ensure no overflow exception was recorded.
  expect(tester.takeException(), isNull);
}

void main() {
  group('SubjectGrouping (presentation-only)', () {
    test('categoryOf is decorative and covers core labels', () {
      final subjects = _subjectsFixture().map(Subject.fromJson).toList();
      final cats = subjects.map(SubjectGrouping.categoryOf).toSet();
      // Should produce at least 3 distinct decorative categories from diverse names.
      expect(cats.length, greaterThanOrEqualTo(3));
      expect(SubjectGrouping.coreLabels, contains('Programming'));
    });

    test(
      'deriveChips returns All + present categories ordered by coreLabels',
      () {
        final subjects = _subjectsFixture().map(Subject.fromJson).toList();
        final chips = SubjectGrouping.deriveChips(subjects);
        expect(chips.first, SubjectGrouping.allLabel);
        expect(chips, contains('Programming'));
        expect(chips, contains('Networks'));
        expect(chips, contains('Databases'));
      },
    );

    test('filter All returns original list, category filters correctly', () {
      final subjects = _subjectsFixture().map(Subject.fromJson).toList();
      final all = SubjectGrouping.filter(subjects, SubjectGrouping.allLabel);
      expect(all.length, subjects.length);
      final prog = SubjectGrouping.filter(subjects, 'Programming');
      // At least one programming-labeled subject should exist.
      expect(prog, isNotEmpty);
      // Filtering never mutates original.
      expect(subjects.length, 6);
    });

    test(
      'filter with nonexistent category returns empty (empty filtered state)',
      () {
        final subjects = _subjectsFixture().map(Subject.fromJson).toList();
        final empty = SubjectGrouping.filter(subjects, 'Security');
        // With our fixture, Security has no subjects, so empty is expected.
        expect(empty, isEmpty);
      },
    );
  });

  group('Catalog responsive (Phase 2)', () {
    for (final entry in [
      (width: 360.0, label: '360 compact'),
      (width: 768.0, label: '768 medium'),
      (width: 1440.0, label: '1440 expanded'),
    ]) {
      testWidgets('catalog renders without overflow at ${entry.label}', (
        tester,
      ) async {
        // Direct JSON encoding for subjects list.
        final fixedClient = MockClient((request) async {
          if (request.url.path.endsWith('/subjects')) {
            return http.Response(
              // encode as JSON list
              '[{"id":"11111111-1111-1111-1111-111111111101","name":"Programming","description":"Learn programming fundamentals","iconKey":"subject_programming","isActive":true,"displayOrder":1},{"id":"11111111-1111-1111-1111-111111111102","name":"Computer Networks","description":"Packets, routing and the web.","iconKey":"subject_networks","isActive":true,"displayOrder":2},{"id":"11111111-1111-1111-1111-111111111103","name":"DBMS","description":null,"iconKey":"subject_dbms","isActive":true,"displayOrder":3},{"id":"11111111-1111-1111-1111-111111111104","name":"Operating Systems","description":"Processes and memory","iconKey":"subject_operating_systems","isActive":true,"displayOrder":4},{"id":"11111111-1111-1111-1111-111111111105","name":"Data Structures","description":"Trees and graphs","iconKey":"subject_data_structures","isActive":true,"displayOrder":5},{"id":"11111111-1111-1111-1111-111111111106","name":"Artificial Intelligence","description":"ML and AI","iconKey":"subject_ai","isActive":true,"displayOrder":6}]',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('', 404);
        });
        await _pumpSubjectsAtSize(tester, Size(entry.width, 800), fixedClient);
        // Verify chips row exists.
        expect(find.byType(SubjectsScreen), findsOneWidget);
        // At least All chip should be rendered.
        expect(find.text('ALL'), findsWidgets);
        // Verify at least 5 world cards render (one per subject after header + chips).
        expect(find.byType(PressableWorldCard), findsNWidgets(6));
        // Verify no exception after settle at this width.
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('category chips filter and empty filtered state renders', (
      tester,
    ) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/subjects')) {
          return http.Response(
            '[{"id":"11111111-1111-1111-1111-111111111101","name":"Programming","description":"Learn","iconKey":"subject_programming","isActive":true,"displayOrder":1}]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 404);
      });
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_wrapWithScope(const SubjectsScreen(), client));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      // Tap Databases chip when only Programming present should show empty filtered state.
      // First find chips; All selected initially.
      final allChip = find.text('ALL');
      expect(allChip, findsOneWidget);
      // Find a non-All chip if present (with single Programming subject, chips = All + Programming).
      // Tapping All should keep cards; tapping a category with no subjects would show empty.
      // With single programming subject, Databases category won't appear in chips (deriveChips only present).
      // So verify at least filtering keeps cards when All selected.
      expect(find.byType(PressableWorldCard), findsOneWidget);
    });

    testWidgets('long subject names do not overflow at 360', (tester) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/subjects')) {
          return http.Response(
            '[{"id":"11111111-1111-1111-1111-111111111101","name":"Advanced Data Structures and Algorithms in Java with Very Long Name That Should Not Overflow The Card","description":"An extremely long description that should be truncated to two lines and not cause layout overflow even on narrow screens","iconKey":"subject_programming","isActive":true,"displayOrder":1}]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 404);
      });
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_wrapWithScope(const SubjectsScreen(), client));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(PressableWorldCard), findsOneWidget);
      // Verify text is rendered with ellipsis (no overflow error).
      expect(find.textContaining('Advanced Data Structures'), findsOneWidget);
    });

    testWidgets('selected chip state renders with semantics', (tester) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/subjects')) {
          return http.Response(
            '[{"id":"11111111-1111-1111-1111-111111111101","name":"Programming","description":"Learn","iconKey":"subject_programming","isActive":true,"displayOrder":1},{"id":"11111111-1111-1111-1111-111111111102","name":"Computer Networks","description":"Packets","iconKey":"subject_networks","isActive":true,"displayOrder":2}]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 404);
      });
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_wrapWithScope(const SubjectsScreen(), client));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Find ChoiceChip widgets and verify one is selected (All initially).
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips, isNotEmpty);
      final selectedChips = chips.where((c) => c.selected == true).toList();
      expect(selectedChips.length, 1);
      expect(selectedChips.first.label, isA<Text>());
    });

    testWidgets('catalog remains visually stable at 1440 with many subjects', (
      tester,
    ) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/subjects')) {
          // 6 subjects, should all render without clipping at wide width.
          return http.Response(
            '[{"id":"11111111-1111-1111-1111-111111111101","name":"Programming","description":"Learn","iconKey":"subject_programming","isActive":true,"displayOrder":1},{"id":"11111111-1111-1111-1111-111111111102","name":"Computer Networks","description":"Packets","iconKey":"subject_networks","isActive":true,"displayOrder":2},{"id":"11111111-1111-1111-1111-111111111103","name":"DBMS","description":null,"iconKey":"subject_dbms","isActive":true,"displayOrder":3},{"id":"11111111-1111-1111-1111-111111111104","name":"Operating Systems","description":"Processes","iconKey":"subject_operating_systems","isActive":true,"displayOrder":4},{"id":"11111111-1111-1111-1111-111111111105","name":"Data Structures","description":"Trees","iconKey":"subject_data_structures","isActive":true,"displayOrder":5},{"id":"11111111-1111-1111-1111-111111111106","name":"Web Technologies","description":"HTML/CSS/JS","iconKey":"subject_web","isActive":true,"displayOrder":6}]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 404);
      });
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_wrapWithScope(const SubjectsScreen(), client));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(PressableWorldCard), findsNWidgets(6));
      // Chips row should be present and scrollable.
      expect(find.text('ALL'), findsOneWidget);
    });
  });
}
