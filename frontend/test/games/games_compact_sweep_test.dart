import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/features/games/boss_battle/presentation/boss_battle_screen.dart';
import 'package:gamelearn_app/features/games/concept_builder/presentation/concept_builder_screen.dart';
import 'package:gamelearn_app/features/games/connectivity_lab/presentation/connectivity_lab_screen.dart';
import 'package:gamelearn_app/features/games/debug_arena/presentation/debug_arena_screen.dart';
import 'package:gamelearn_app/features/games/drag_drop/presentation/drag_drop_screen.dart';
import 'package:gamelearn_app/features/games/memory_match/presentation/memory_match_screen.dart';
import 'package:gamelearn_app/features/games/mystery_case/presentation/mystery_case_screen.dart';
import 'package:gamelearn_app/features/games/puzzle_arena/presentation/puzzle_arena_screen.dart';
import 'package:gamelearn_app/features/games/quiz_battle/presentation/quiz_battle_screen.dart';
import 'package:gamelearn_app/features/games/sequence_master/presentation/sequence_master_screen.dart';
import 'package:gamelearn_app/features/games/snake_and_ladder/presentation/snake_and_ladder_screen.dart';
import 'package:gamelearn_app/features/games/speed_run/presentation/speed_run_screen.dart';
import 'package:gamelearn_app/features/games/target_challenge/presentation/target_challenge_screen.dart';
import 'package:gamelearn_app/features/games/unlock_code/presentation/unlock_code_screen.dart';

import '../helpers/fake_backend.dart';

/// F4 compact sweep: every game screen must render its gameplay UI without
/// overflow at 390px. Backend-driven screens get world-scoped Programming
/// fixtures; static-bank screens pump provider-only.
void main() {
  const subjectId = '11111111-1111-1111-1111-111111111101';
  const subjectName = 'Programming';
  const topicId = 't1';
  const topicName = 'Variables & Types';

  Map<String, dynamic> topicJson() => {
    'id': topicId,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'name': topicName,
    'description': 'Variables store values.',
    'difficulty': 'EASY',
    'displayOrder': 1,
  };

  Map<String, dynamic> conceptItem({
    required String id,
    required String name,
    required String definition,
    required String gameType,
  }) => {
    'kind': 'CONCEPT',
    'id': id,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'topicId': topicId,
    'topicName': name,
    'unitId': null,
    'gameType': gameType,
    'difficulty': 'EASY',
    'questionText': null,
    'options': [],
    'definition': definition,
  };

  Map<String, dynamic> structureItem({
    required String id,
    required String name,
    required String difficulty,
  }) => {
    'kind': 'STRUCTURE',
    'id': id,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'topicId': topicId,
    'topicName': name,
    'unitId': null,
    'gameType': 'drag_drop',
    'difficulty': difficulty,
    'questionText': null,
    'options': [],
    'definition': null,
  };

  Map<String, dynamic> subjectPayload(List<Map<String, dynamic>> items) => {
    'mode': 'SUBJECT',
    'subjectId': subjectId,
    'items': items,
  };

  Map<String, dynamic> handler(dynamic request) {
    final path = request.url.path as String;
    if (path.endsWith('/api/v1/game-content')) {
      final gameType = request.url.queryParameters['gameType'];
      if (gameType == 'memory_match') {
        return {
          'body': subjectPayload([
            conceptItem(
              id: 'c-1',
              name: 'Variables',
              definition: 'A variable names a storage location.',
              gameType: 'memory_match',
            ),
            conceptItem(
              id: 'c-2',
              name: 'Types',
              definition: 'A type defines the values an expression may take.',
              gameType: 'memory_match',
            ),
          ]),
        };
      }
      if (gameType == 'drag_drop') {
        // The adapter honestly requires >=2 zones and >=3 items; fewer
        // is a scope rejection, not playable content.
        return {
          'body': subjectPayload([
            structureItem(id: 's-1', name: 'Variables', difficulty: 'EASY'),
            structureItem(id: 's-2', name: 'Loops', difficulty: 'MEDIUM'),
            structureItem(id: 's-3', name: 'Recursion', difficulty: 'HARD'),
          ]),
        };
      }
      if (gameType == 'concept_builder') {
        return {
          'body': subjectPayload([
            conceptItem(
              id: 'c-1',
              name: 'Variables',
              definition:
                  'A variable names a storage location. Types constrain values.',
              gameType: 'concept_builder',
            ),
          ]),
        };
      }
    }
    if (path.endsWith('/api/v1/quiz/t1') || path.endsWith('/api/v1/quiz/t2')) {
      return {'body': Fixtures.quiz()};
    }
    if (path.endsWith('/api/v1/topics/$topicId')) {
      return {'body': topicJson()};
    }
    if (path.endsWith('/api/v1/gamification/summary')) {
      return {'body': Fixtures.gamificationSummary()};
    }
    if (path.endsWith('/api/v1/achievements')) {
      return {'body': Fixtures.achievements()};
    }
    return {
      'status': 404,
      'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
    };
  }

  Widget worldScreen(Widget screen) => screen;

  Future<void> pump390(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(home: fakeScope(child: screen, handler: handler)),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Games compact sweep (F4, 390px)', () {
    testWidgets('quiz battle question fits', (tester) async {
      await pump390(
        tester,
        worldScreen(
          const QuizBattleScreen(
            topicId: 't2',
            topicName: 'Control Flow',
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
      );
      expect(
        find.text('Which keyword declares a constant?'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('memory match board fits', (tester) async {
      await pump390(
        tester,
        worldScreen(
          const MemoryMatchScreen(
            topicId: topicId,
            topicName: topicName,
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
      );
      expect(find.text('TERM'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('drag & drop zones fit', (tester) async {
      await pump390(
        tester,
        worldScreen(
          const DragDropScreen(
            topicId: topicId,
            topicName: topicName,
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
      );
      expect(find.text('EASY'), findsWidgets);
      expect(find.text('Recursion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('speed run rush fits', (tester) async {
      await pump390(
        tester,
        worldScreen(
          const SpeedRunScreen(
            topicId: 't2',
            topicName: 'Control Flow',
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
      );
      expect(
        find.text('Which keyword declares a constant?'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('concept builder blocks fit', (tester) async {
      await pump390(
        tester,
        worldScreen(
          const ConceptBuilderScreen(
            topicId: topicId,
            topicName: topicName,
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
      );
      expect(find.text('Variables'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('debug arena programming board fits', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(
            home: DebugArenaScreen(
              topicId: topicId,
              topicName: topicName,
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
        ),
      );
      expect(find.text('SYSTEM ERROR DETECTED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('debug arena wrong world stays honestly empty', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(
            home: DebugArenaScreen(
              topicId: topicId,
              topicName: topicName,
              subjectId: 'other-subject',
              subjectName: 'Computer Networks',
            ),
          ),
        ),
      );
      // World-aware gate: the world-scoped empty surface, never foreign
      // challenges and never a crash.
      expect(find.text('BACK TO ARENA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unlock code vault fits', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(home: UnlockCodeScreen(topicId: topicId)),
        ),
      );
      expect(find.text('LOCKED VAULT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // NOTE: on compact phones the shared GameHud shows an icon-only
    // identity pill (the full wordmark needs ~80px the timer row cannot
    // spare), so gameplay markers below assert body content — never the
    // HUD pill text.
    testWidgets('sequence master board fits', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(home: SequenceMasterScreen(topicId: 'topic-1')),
        ),
      );
      expect(find.textContaining('SEQUENCE 1 / 4'), findsOneWidget);
      expect(
        find.text('AVAILABLE BLOCKS').evaluate().isNotEmpty ||
            find.text('CANDIDATE BLOCKS').evaluate().isNotEmpty,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('target challenge board fits', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(home: TargetChallengeScreen(topicId: 'topic-1')),
        ),
      );
      expect(find.text('TARGET'), findsWidgets);
      expect(find.text('AVAILABLE ACTIONS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mystery case briefing fits', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(home: MysteryCaseScreen(topicId: 'topic-1')),
        ),
      );
      expect(find.text('CASE BRIEFING'), findsOneWidget);
      expect(find.text('START INVESTIGATION'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('boss battle briefing and arena fit', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(home: BossBattleScreen(topicId: 'topic-1')),
        ),
      );
      expect(find.text('BOSS INTRODUCTION'), findsOneWidget);
      await tester.tap(find.text('ENTER ARENA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('BOSS HP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('puzzle arena board fits', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(home: PuzzleArenaScreen(topicId: 'topic-1')),
        ),
      );
      expect(find.text('PUZZLE BOARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('connectivity lab map fits', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(home: ConnectivityLabScreen(topicId: 'topic-1')),
        ),
      );
      expect(find.text('NETWORK MAP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('connectivity lab wrong world stays honestly empty',
        (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(
            home: ConnectivityLabScreen(
              topicId: topicId,
              subjectId: 'other-subject',
              subjectName: 'Programming',
            ),
          ),
        ),
      );
      // World-aware gate: the world-scoped empty surface, never foreign
      // missions and never a crash.
      expect(find.text('BACK TO ARENA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('snake & ladder board fits', (tester) async {
      await pump390(
        tester,
        const ProviderScope(
          child: MaterialApp(home: SnakeAndLadderScreen(topicId: 'topic-1')),
        ),
      );
      expect(find.text('SNAKE & LADDER BOARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
