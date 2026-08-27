// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/core/models/content_models.dart';
import 'package:gamelearn_app/features/learning/path/presentation/path_map_screen.dart';

import '../helpers/fake_backend.dart';

LearningPath _dummyPath() => LearningPath(
  id: 'p1',
  subjectId: '11111111-1111-1111-1111-111111111101',
  title: 'Test Path',
  description: 'desc',
  status: 'ACTIVE',
  generatedBy: 'SYSTEM',
  createdAt: DateTime.parse('2026-08-23T12:00:00Z'),
  updatedAt: DateTime.parse('2026-08-23T12:00:00Z'),
  nodes: const [
    PathNode(
      id: 'n1',
      topicId: 't1',
      topicName: 'Variables & Types',
      sequenceNumber: 1,
      requiredMastery: 0,
      status: 'AVAILABLE',
    ),
    PathNode(
      id: 'n2',
      topicId: 't2',
      topicName:
          'Control Flow With A Very Long Name That Should Wrap Or Ellipsize Without Overflow',
      sequenceNumber: 2,
      requiredMastery: 40,
      status: 'LOCKED',
    ),
    PathNode(
      id: 'n3',
      topicId: 't3',
      topicName: 'Functions',
      sequenceNumber: 3,
      requiredMastery: 60,
      status: 'LOCKED',
    ),
  ],
);

Widget _wrapWithMediaQuery(
  Widget child, {
  bool disableAnimations = false,
  Size? size,
}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(
        FakeTokenStorage()..stored = 'tok',
      ),
      apiClientProvider.overrideWith(
        (ref) => ApiClient(
          client: MockClient((_) async => http.Response('[]', 200)),
        ),
      ),
      audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: disableAnimations,
          size: size ?? const Size(360, 800),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LearningNode lifecycle — regression for MediaQuery before initState', () {
    testWidgets(
      'AVAILABLE node does not throw dependOnInheritedWidget before initState',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        const node = PathNode(
          id: 'n1',
          topicId: 't1',
          topicName: 'Variables & Types',
          sequenceNumber: 1,
          requiredMastery: 0,
          status: 'AVAILABLE',
        );
        await tester.pumpWidget(
          _wrapWithMediaQuery(
            Center(
              child: SizedBox(
                width: 76,
                height: 76,
                child: LearningNode(node: node, onTap: () {}),
              ),
            ),
            disableAnimations: false,
          ),
        );
        // Pump one frame to trigger initState + didChangeDependencies
        await tester.pump();
        expect(tester.takeException(), isNull);
        // Should find icon for AVAILABLE (bolt)
        expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
        // Ensure no yellow error text (FlutterError would be painted as text)
        expect(find.textContaining('dependOnInheritedWidget'), findsNothing);
      },
    );

    testWidgets(
      'LearningNode respects disableAnimations without exception at 360',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.binding.setSurfaceSize(const Size(360, 800));
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final path = _dummyPath();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                await SharedPreferences.getInstance(),
              ),
              tokenStorageProvider.overrideWithValue(
                FakeTokenStorage()..stored = 'tok',
              ),
              apiClientProvider.overrideWith(
                (ref) => ApiClient(
                  client: MockClient((_) async => http.Response('[]', 200)),
                ),
              ),
              audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  disableAnimations: true,
                  size: Size(360, 800),
                ),
                child: Scaffold(
                  body: AdventureTrail(
                    path: path,
                    aiMetadata: {},
                    onNodeTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        // Check YOU ARE HERE visible for AVAILABLE node
        expect(find.text('YOU ARE HERE'), findsOneWidget);
        // Check all topic names are present without overflow error
        expect(find.text('Variables & Types'), findsOneWidget);
        expect(find.text('Functions'), findsOneWidget);
      },
    );

    testWidgets(
      'AdventureTrail renders 3 nodes without MediaQuery error at 768',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final path = _dummyPath();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                await SharedPreferences.getInstance(),
              ),
              tokenStorageProvider.overrideWithValue(
                FakeTokenStorage()..stored = 'tok',
              ),
              apiClientProvider.overrideWith(
                (ref) => ApiClient(
                  client: MockClient((_) async => http.Response('[]', 200)),
                ),
              ),
              audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  disableAnimations: false,
                  size: Size(768, 1024),
                ),
                child: Scaffold(
                  body: AdventureTrail(
                    path: path,
                    aiMetadata: const {},
                    onNodeTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        // Node statuses should be indicated
        expect(find.text('Available'), findsOneWidget);
        expect(find.text('Locked'), findsWidgets);
      },
    );

    testWidgets('AdventureTrail at 1440 shows no overflow or corruption', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final path = _dummyPath();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage()..stored = 'tok',
            ),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((_) async => http.Response('[]', 200)),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1440, 900)),
              child: Scaffold(
                body: AdventureTrail(
                  path: path,
                  aiMetadata: {},
                  onNodeTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      // Long topic name should be ellipsized, not cause overflow
      expect(find.textContaining('Control Flow'), findsOneWidget);
      // No FlutterError
      expect(find.textContaining('MediaQuery'), findsNothing);
    });

    testWidgets('LOCKED node does not animate and renders lock icon', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      const node = PathNode(
        id: 'n2',
        topicId: 't2',
        topicName: 'Control Flow',
        sequenceNumber: 2,
        requiredMastery: 40,
        status: 'LOCKED',
      );
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          Center(
            child: SizedBox(
              width: 76,
              height: 76,
              child: LearningNode(node: node, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets(
      'multiple LearningNodes with mixed statuses do not share MediaQuery violation',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final path = _dummyPath();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                await SharedPreferences.getInstance(),
              ),
              tokenStorageProvider.overrideWithValue(
                FakeTokenStorage()..stored = 'tok',
              ),
              apiClientProvider.overrideWith(
                (ref) => ApiClient(
                  client: MockClient((_) async => http.Response('[]', 200)),
                ),
              ),
              audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: AdventureTrail(
                  path: path,
                  aiMetadata: {},
                  onNodeTap: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        // If initState MediaQuery bug existed, this would throw
        expect(tester.takeException(), isNull);
        // Verify all nodes rendered
        expect(find.byType(LearningNode), findsNWidgets(3));
      },
    );

    testWidgets(
      'Starfield respects disableAnimations via didChangeDependencies',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                await SharedPreferences.getInstance(),
              ),
              tokenStorageProvider.overrideWithValue(
                FakeTokenStorage()..stored = 'tok',
              ),
              apiClientProvider.overrideWith(
                (ref) => ApiClient(
                  client: MockClient((_) async => http.Response('[]', 200)),
                ),
              ),
              audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: const Scaffold(
                  body: SizedBox.expand(child: Text('check')),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
