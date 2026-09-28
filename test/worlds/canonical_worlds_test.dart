import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/models/content_models.dart';
import 'package:gamelearn_app/core/theme/subject_visual_identity.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';
import 'package:gamelearn_app/features/subjects/domain/world_syllabus.dart';

void main() {
  group('WorldId — stable canonical identity', () {
    test('exactly 11 canonical worlds exist', () {
      expect(WorldId.values.length, 11);
      expect(WorldCatalog.all.length, 11);
    });

    test('stable keys match the required canonical set', () {
      expect(
        WorldId.values.map((w) => w.key).toSet(),
        {
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
        },
      );
    });

    test('keys are unique and ids are unique', () {
      final keys = WorldId.values.map((w) => w.key).toList();
      expect(keys.toSet().length, keys.length);
      final defs = WorldCatalog.all;
      expect(defs.map((d) => d.id).toSet().length, defs.length);
      expect(defs.map((d) => d.displayName).toSet().length, defs.length);
    });

    test('display names never serve as ids (lookup by key, not name)', () {
      // byKey resolves stable keys; display-name resolution is a separate
      // presentation helper — proving the two paths are distinct.
      expect(WorldCatalog.byKey('ALGORITHMS')?.id, WorldId.algorithms);
      expect(WorldCatalog.byKey('algorithms')?.id, WorldId.algorithms);
      expect(WorldCatalog.byKey('  dbms  ')?.id, WorldId.dbms);
      expect(
        WorldCatalog.byKey('OBJECT_ORIENTED_SOFTWARE_ENGINEERING')?.id,
        WorldId.oose,
      );
    });

    test('invalid world lookup returns null (never throws)', () {
      expect(WorldCatalog.byKey(null), isNull);
      expect(WorldCatalog.byKey(''), isNull);
      expect(WorldCatalog.byKey('QUANTUM_BIOLOGY'), isNull);
      expect(WorldCatalog.byId(null), isNull);
      expect(WorldId.fromKey('nope'), isNull);
    });

    test('catalog ordering is deterministic', () {
      final first = WorldCatalog.ordered().map((w) => w.id).toList();
      final second = WorldCatalog.ordered().map((w) => w.id).toList();
      expect(first, second);
      expect(first.first, WorldId.programming);
      expect(first.last, WorldId.oose);
      final orders = WorldCatalog.ordered().map((w) => w.displayOrder).toList();
      expect(orders, orderedEquals([...orders]..sort()));
    });
  });

  group('WorldCatalog — backend compatibility (existing 5 worlds)', () {
    Subject subject({required String name, required String iconKey}) =>
        Subject(
          id: '00000000-0000-0000-0000-000000000000',
          name: name,
          description: '',
          iconKey: iconKey,
          isActive: true,
          displayOrder: 0,
        );

    test('legacy iconKeys resolve to canonical worlds', () {
      expect(
        WorldCatalog.resolveSubject(
          subject(name: 'Programming', iconKey: 'code'),
        )?.id,
        WorldId.programming,
      );
      expect(
        WorldCatalog.resolveSubject(
          subject(name: 'Programming', iconKey: 'subject_programming'),
        )?.id,
        WorldId.programming,
      );
      expect(
        WorldCatalog.resolveSubject(
          subject(name: 'Data Structures', iconKey: 'data_structures'),
        )?.id,
        WorldId.dataStructures,
      );
      expect(
        WorldCatalog.resolveSubject(
          subject(name: 'Database Systems', iconKey: 'database'),
        )?.id,
        WorldId.dbms,
      );
      expect(
        WorldCatalog.resolveSubject(
          subject(name: 'Computer Networks', iconKey: 'network'),
        )?.id,
        WorldId.computerNetworks,
      );
      expect(
        WorldCatalog.resolveSubject(
          subject(name: 'Operating Systems', iconKey: 'os'),
        )?.id,
        WorldId.operatingSystems,
      );
    });

    test('legacy five set is preserved for compatibility assertions', () {
      expect(WorldCatalog.legacyFive.length, 5);
      expect(
        WorldCatalog.legacyFive,
        {
          WorldId.programming,
          WorldId.dataStructures,
          WorldId.dbms,
          WorldId.computerNetworks,
          WorldId.operatingSystems,
        },
      );
    });

    test('unknown backend subject resolves to null (generic fallback)', () {
      expect(
        WorldCatalog.resolveSubject(
          subject(name: 'Mystery Subject', iconKey: 'unknown_xyz'),
        ),
        isNull,
      );
    });

    test('visual registry covers all 11 worlds (no fallback for known)', () {
      expect(SubjectVisualRegistry.known.length, 11);
      for (final world in WorldCatalog.all) {
        for (final alias in world.iconKeys) {
          expect(
            SubjectVisualRegistry.fromIconKey(alias),
            isNot(SubjectVisualRegistry.fallback),
            reason: 'iconKey $alias should resolve',
          );
        }
        expect(
          SubjectVisualRegistry.fromName(world.displayName),
          isNot(SubjectVisualRegistry.fallback),
          reason: '${world.displayName} should resolve by name',
        );
      }
    });
  });

  group('WorldSyllabus — hierarchy + determinism', () {
    test('seven static worlds are populated with expected topic counts', () {
      expect(WorldSyllabusCatalog.of(WorldId.algorithms).topicCount, 13);
      expect(WorldSyllabusCatalog.of(WorldId.dbms).topicCount, 16);
      expect(WorldSyllabusCatalog.of(WorldId.dataScience).topicCount, 12);
      expect(WorldSyllabusCatalog.of(WorldId.operatingSystems).topicCount, 15);
      expect(WorldSyllabusCatalog.of(WorldId.oop).topicCount, 17);
      expect(WorldSyllabusCatalog.of(WorldId.dataStructures).topicCount, 20);
      expect(WorldSyllabusCatalog.of(WorldId.computerNetworks).topicCount, 38);
    });

    test('units are ordered and topics are ordered within units', () {
      for (final worldId in WorldSyllabusCatalog.staticWorlds) {
        final syllabus = WorldSyllabusCatalog.of(worldId);
        final units = syllabus.orderedUnits();
        expect(units.length, greaterThan(1));
        for (var i = 0; i < units.length; i++) {
          expect(units[i].unitNumber, i + 1);
          expect(units[i].worldId, worldId);
          final orders = units[i].topics.map((t) => t.order).toList();
          expect(orders, orderedEquals([...orders]..sort()));
        }
        // Global order across units is strictly increasing.
        final allOrders = [
          for (final u in units) ...u.topics.map((t) => t.order),
        ];
        expect(allOrders, orderedEquals([...allOrders]..sort()));
        expect(allOrders.toSet().length, allOrders.length);
      }
    });

    test('topic ids are namespaced per world (isolation by construction)', () {
      final seen = <String, WorldId>{};
      for (final worldId in WorldSyllabusCatalog.staticWorlds) {
        for (final unit in WorldSyllabusCatalog.of(worldId).orderedUnits()) {
          for (final topic in unit.topics) {
            expect(
              seen.containsKey(topic.id),
              isFalse,
              reason: 'duplicate topic id ${topic.id}',
            );
            seen[topic.id] = worldId;
          }
        }
      }
    });

    test('recommended next topic is the deterministic first topic', () {
      final syllabus = WorldSyllabusCatalog.of(WorldId.algorithms);
      expect(
        syllabus.recommendedNextTopicId,
        syllabus.orderedUnits().first.topics.first.id,
      );
      expect(syllabus.topicById('algorithms_t1')?.title, 'Fundamentals of Algorithm');
    });

    test('pending worlds are truthful: empty, unavailable, no fabrication', () {
      for (final id in [WorldId.aiMl, WorldId.webTechnologies, WorldId.oose]) {
        final syllabus = WorldSyllabusCatalog.of(id);
        expect(syllabus.isPending, isTrue, reason: '$id');
        expect(syllabus.units, isEmpty);
        expect(syllabus.isAvailable, isFalse);
        expect(syllabus.recommendedNextTopicId, isNull);
        expect(WorldCatalog.byId(id)?.availability, WorldAvailability.comingSoon);
      }
    });

    test('programming is backend-driven (no static fabrication)', () {
      final syllabus = WorldSyllabusCatalog.of(WorldId.programming);
      expect(syllabus.source, SyllabusSource.backend);
      expect(syllabus.units, isEmpty);
      expect(
        WorldCatalog.byId(WorldId.programming)?.availability,
        WorldAvailability.backendDriven,
      );
    });
  });

  group('Content isolation metadata', () {
    test('subject scope isolates; global arena allows mixed content', () {
      final dbms = WorldCatalog.byKey('DBMS')!;
      final networks = WorldCatalog.byKey('COMPUTER_NETWORKS')!;
      expect(
        WorldCatalog.topicBelongsToWorld(
          world: dbms,
          topicSubjectName: 'Database Management Systems',
        ),
        isTrue,
      );
      expect(
        WorldCatalog.topicBelongsToWorld(
          world: dbms,
          topicSubjectName: 'Computer Networks',
        ),
        isFalse,
      );
      // Global arena bypasses isolation explicitly.
      expect(
        WorldCatalog.topicBelongsToWorld(
          world: dbms,
          topicSubjectName: 'Computer Networks',
          scope: WorldScope.globalArena,
        ),
        isTrue,
      );
      expect(networks.scope, WorldScope.subjectIsolated);
      expect(dbms.scope, WorldScope.subjectIsolated);
    });

    test('syllabus containsTopic isolates by world', () {
      final ds = WorldSyllabusCatalog.of(WorldId.dataStructures);
      final own = ds.orderedUnits().first.topics.first.id;
      final other = WorldSyllabusCatalog.of(WorldId.algorithms)
          .orderedUnits()
          .first
          .topics
          .first
          .id;
      expect(ds.containsTopic(own), isTrue);
      expect(ds.containsTopic(other), isFalse);
      expect(ds.containsTopic(other, scope: WorldScope.globalArena), isTrue);
    });
  });
}
