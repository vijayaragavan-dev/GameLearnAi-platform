import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/models/content_models.dart';
import 'package:gamelearn_app/core/models/quiz_models.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';

/// Cross-world content isolation matrix (Phase 5).
///
/// WORLD ARENA != GLOBAL ARENA — enforced in the selection layer, not labels.
void main() {
  const dbmsSubject = '11111111-1111-1111-1111-111111111101';
  const osSubject = '11111111-1111-1111-1111-111111111102';
  const cnSubject = '11111111-1111-1111-1111-111111111103';

  GameContentRequest world(
    WorldId id, {
    String subjectId = dbmsSubject,
    String? subjectName,
    String? topicId,
  }) =>
      GameContentRequest.world(
        worldId: id,
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicId,
      );

  group('requested world matrix — static labels', () {
    test('DBMS accepts DBMS, rejects OS and CN', () {
      final req = world(WorldId.dbms, subjectName: 'DBMS');
      final items = ['DBMS', 'Operating Systems', 'Computer Networks'];
      final selected = WorldContentGate.selectStatic(
        items: items,
        topicLabelOf: (s) => s,
        request: req,
      );
      expect(selected, ['DBMS']);
    });

    test('CN accepts CN, rejects DBMS', () {
      final req = world(
        WorldId.computerNetworks,
        subjectId: cnSubject,
        subjectName: 'Computer Networks',
      );
      final selected = WorldContentGate.selectStatic(
        items: ['Computer Networks', 'DBMS', 'Mathematics'],
        topicLabelOf: (s) => s,
        request: req,
      );
      expect(selected, ['Computer Networks']);
    });

    test('OS accepts OS, rejects OOP', () {
      final req = world(
        WorldId.operatingSystems,
        subjectId: osSubject,
        subjectName: 'Operating Systems',
      );
      final selected = WorldContentGate.selectStatic(
        items: ['Operating Systems', 'Object-Oriented Programming', 'DBMS'],
        topicLabelOf: (s) => s,
        request: req,
      );
      expect(selected, ['Operating Systems']);
    });

    test('OOP accepts OOP, rejects Data Structures', () {
      final req = world(
        WorldId.oop,
        subjectId: 'oop-subject',
        subjectName: 'Object-Oriented Programming',
      );
      final selected = WorldContentGate.selectStatic(
        items: ['Object-Oriented Programming', 'Data Structures'],
        topicLabelOf: (s) => s,
        request: req,
      );
      expect(selected, ['Object-Oriented Programming']);
    });

    test('each static world isolates its own label set', () {
      const labels = [
        'Programming',
        'Data Structures',
        'Algorithms',
        'DBMS',
        'Operating Systems',
        'Computer Networks',
      ];
      const expectations = {
        WorldId.programming: ['Programming'],
        WorldId.dataStructures: ['Data Structures'],
        WorldId.algorithms: ['Algorithms'],
        WorldId.dbms: ['DBMS'],
        WorldId.operatingSystems: ['Operating Systems'],
        WorldId.computerNetworks: ['Computer Networks'],
      };
      expectations.forEach((id, expected) {
        final req = world(id, subjectName: 'x');
        expect(
          WorldContentGate.selectStatic(
            items: labels,
            topicLabelOf: (s) => s,
            request: req,
          ),
          expected,
          reason: '$id',
        );
      });
    });

    test('selection is deterministic and order-preserving', () {
      final req = world(WorldId.dbms, subjectName: 'DBMS');
      List<String> run() => WorldContentGate.selectStatic(
            items: const ['DBMS', 'DBMS', 'OS', 'DBMS'],
            topicLabelOf: (s) => s == 'OS' ? 'Operating Systems' : s,
            request: req,
          );
      expect(run(), run());
      expect(run(), ['DBMS', 'DBMS', 'DBMS']);
    });
  });

  group('global arena — mixed content allowed', () {
    test('global request keeps every eligible item', () {
      final req = GameContentRequest.global();
      final items = [
        'DBMS',
        'Operating Systems',
        'Computer Networks',
        'Mathematics',
        'Science',
      ];
      expect(
        WorldContentGate.selectStatic(
          items: items,
          topicLabelOf: (s) => s,
          request: req,
        ),
        items,
      );
    });

    test('unmapped labels (Mathematics/Science) are global-only', () {
      final req = world(WorldId.dbms, subjectName: 'DBMS');
      expect(
        WorldContentGate.selectStatic(
          items: const ['Mathematics', 'Science'],
          topicLabelOf: (s) => s,
          request: req,
        ),
        isEmpty,
      );
      expect(WorldContentGate.worldOfStaticLabel('Mathematics'), isNull);
    });

    test('bank defaults classify existing domain content honestly', () {
      // Debug Arena items carry sub-topic labels; the bank default attributes
      // the existing programming-domain bank without inventing content.
      expect(
        WorldContentGate.worldOfStaticLabel(
          'Loops',
          gameType: GameType.debugArena,
        ),
        WorldId.programming,
      );
      expect(
        WorldContentGate.worldOfStaticLabel(
          'DNS',
          gameType: GameType.connectivityLab,
        ),
        WorldId.computerNetworks,
      );
    });
  });

  group('topic scope — subject + topic must both match', () {
    Topic topic(String id, String subjectId) => Topic(
          id: id,
          subjectId: subjectId,
          subjectName: 'DBMS',
          name: 'SQL',
          description: '',
          difficulty: 'EASY',
          displayOrder: 1,
        );

    test('matching subject+topic accepted', () {
      final req = world(WorldId.dbms, topicId: 't-1');
      expect(
        WorldContentGate.acceptBackendTopic(
          topic: topic('t-1', dbmsSubject),
          request: req,
        ),
        isTrue,
      );
    });

    test('DBMS transaction topic rejects unrelated DBMS topic id', () {
      final req = world(WorldId.dbms, topicId: 'txn-topic');
      expect(
        WorldContentGate.acceptBackendTopic(
          topic: topic('indexing-topic', dbmsSubject),
          request: req,
        ),
        isFalse,
      );
    });

    test('another-world topic rejected even with matching topic id shape', () {
      final req = world(WorldId.dbms, topicId: 't-1');
      expect(
        WorldContentGate.acceptBackendTopic(
          topic: topic('t-1', osSubject),
          request: req,
        ),
        isFalse,
      );
    });

    test('global scope accepts any backend topic', () {
      final req = GameContentRequest.global();
      expect(
        WorldContentGate.acceptBackendTopic(
          topic: topic('t-9', osSubject),
          request: req,
        ),
        isTrue,
      );
    });

    test('rejection message is honest (no fake fallback)', () {
      final req = world(WorldId.dbms, subjectName: 'DBMS', topicId: 't-1');
      final message = WorldContentGate.rejectionMessage(
        topic: topic('t-2', osSubject),
        request: req,
      );
      expect(message, isNotNull);
      expect(message, contains('DBMS'));
      expect(
        WorldContentGate.rejectionMessage(
          topic: topic('t-1', dbmsSubject),
          request: req,
        ),
        isNull,
      );
    });
  });

  group('backend quiz validation', () {
    Quiz quiz(String topicId) => Quiz(
          id: 'q-1',
          topicId: topicId,
          title: 'Q',
          description: '',
          difficulty: 'MEDIUM',
          timeLimitSeconds: null,
          questionCount: 0,
          questions: const [],
        );

    test('quiz for requested topic accepted, other rejected', () {
      final req = world(WorldId.dbms, topicId: 't-1');
      expect(
        WorldContentGate.acceptBackendQuiz(quiz: quiz('t-1'), request: req),
        isTrue,
      );
      expect(
        WorldContentGate.acceptBackendQuiz(quiz: quiz('t-2'), request: req),
        isFalse,
      );
    });
  });

  group('unknown / missing content', () {
    test('empty bank stays empty (honest EmptyState upstream)', () {
      final req = world(WorldId.oop, subjectName: 'OOP');
      expect(
        WorldContentGate.selectStatic(
          items: const <String>[],
          topicLabelOf: (s) => s,
          request: req,
        ),
        isEmpty,
      );
    });

    test('unresolvable subject degrades to global (never isolates wrong)', () {
      final req = GameContentRequest.fromRoute(
        subjectId: 'unknown-uuid',
        subjectName: 'Mystery Subject',
        topicId: 't-1',
      );
      expect(req.scope, GameContentScope.global);
      expect(
        WorldContentGate.selectStatic(
          items: const ['DBMS'],
          topicLabelOf: (s) => s,
          request: req,
        ),
        ['DBMS'],
      );
    });
  });

  group('all 14 games receive world context without behavior change', () {
    test('GameConfig carries subject/topic per game type', () {
      for (final def in GameDefinition.all) {
        final config = GameConfig(
          topicId: 't-1',
          topicName: 'SQL',
          subjectId: dbmsSubject,
          subjectName: 'DBMS',
          type: def.type,
          difficulty: GameDifficulty.medium,
        );
        expect(config.subjectId, dbmsSubject);
        expect(config.topicId, 't-1');
        expect(GameDefinition.of(def.type).displayName, def.displayName);
      }
      expect(GameDefinition.all.length, 14);
    });

    test('request derivation keeps world context per game entry', () {
      for (final def in GameDefinition.all) {
        final req = GameContentRequest.fromRoute(
          subjectId: dbmsSubject,
          subjectName: 'Database Management Systems',
          topicId: 't-1',
        );
        // World scope derived for every game entry point alike.
        expect(req.scope, GameContentScope.world, reason: '${def.type}');
        expect(req.worldId, WorldId.dbms, reason: '${def.type}');
      }
    });
  });
}
