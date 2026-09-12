import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/models/content_models.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';
import 'package:gamelearn_app/features/subjects/domain/world_context.dart';

Subject _subject(String id, String name, String iconKey) => Subject(
      id: id,
      name: name,
      description: '',
      iconKey: iconKey,
      isActive: true,
      displayOrder: 0,
    );

void main() {
  group('resolveWorldContext — pure resolution (never throws)', () {
    test('backend Subject resolves through WorldCatalog', () {
      final ctx = resolveWorldContext(
        subject: _subject(
          '11111111-1111-1111-1111-111111111101',
          'Database Management Systems',
          'dbms',
        ),
        topicId: 't-1',
        topicName: 'SQL',
      );
      expect(ctx.worldId, WorldId.dbms);
      expect(ctx.subjectId, '11111111-1111-1111-1111-111111111101');
      expect(ctx.topicId, 't-1');
      expect(ctx.isWorldScoped, isTrue);
      expect(ctx.scope, WorldScope.subjectIsolated);
      expect(ctx.definition?.displayName, 'Database Management Systems');
    });

    test('every canonical world resolves via display name', () {
      const names = {
        'Programming': WorldId.programming,
        'Data Structures': WorldId.dataStructures,
        'Algorithms': WorldId.algorithms,
        'Database Management Systems': WorldId.dbms,
        'Computer Networks': WorldId.computerNetworks,
        'Operating Systems': WorldId.operatingSystems,
        'Object-Oriented Programming': WorldId.oop,
        'Artificial Intelligence & Machine Learning': WorldId.aiMl,
        'Data Science': WorldId.dataScience,
        'Web Technologies': WorldId.webTechnologies,
        'Object-Oriented Software Engineering': WorldId.oose,
      };
      names.forEach((name, id) {
        final ctx = resolveWorldContext(
          subjectId: 'backend-uuid-for-$id',
          subjectName: name,
        );
        expect(ctx.worldId, id, reason: name);
        expect(ctx.isWorldScoped, isTrue, reason: name);
      });
    });

    test('unknown subject degrades to global (no crash, no wrong world)', () {
      final ctx = resolveWorldContext(
        subject: _subject('s-9', 'Mystery Subject', 'unknown_xyz'),
      );
      expect(ctx.worldId, isNull);
      expect(ctx.definition, isNull);
      expect(ctx.isWorldScoped, isFalse);
      expect(ctx.scope, WorldScope.globalArena);
      expect(ctx.subjectId, 's-9');
    });

    test('empty context is global', () {
      const ctx = WorldContext();
      expect(ctx.scope, WorldScope.globalArena);
      expect(ctx.isWorldScoped, isFalse);
    });

    test('WorldId never replaces backend ids (coexistence)', () {
      final ctx = resolveWorldContext(
        subject: _subject('uuid-subject', 'DBMS', 'dbms'),
        topicId: 'uuid-topic',
      );
      // Canonical key is stable; backend UUIDs are preserved untouched.
      expect(ctx.worldId?.key, 'DBMS');
      expect(ctx.subjectId, 'uuid-subject');
      expect(ctx.topicId, 'uuid-topic');
    });
  });

  group('world providers — scoped reload, no stale content', () {
    test('subject mapping resolves DBMS then OS distinctly', () {
      final dbms = {
        'id': '11111111-1111-1111-1111-111111111101',
        'name': 'Database Management Systems',
        'description': '',
        'iconKey': 'dbms',
        'isActive': true,
        'displayOrder': 1,
      };
      final os = {
        'id': '11111111-1111-1111-1111-111111111102',
        'name': 'Operating Systems',
        'description': '',
        'iconKey': 'os',
        'isActive': true,
        'displayOrder': 2,
      };
      // Pure mapping both provider paths rely on.
      expect(
        WorldCatalog.resolveSubject(Subject.fromJson(dbms))?.id,
        WorldId.dbms,
      );
      expect(
        WorldCatalog.resolveSubject(Subject.fromJson(os))?.id,
        WorldId.operatingSystems,
      );
    });

    test('WorldContextArgs equality switches scope correctly', () {
      const a = WorldContextArgs(subjectId: 's1', topicId: 't1');
      const b = WorldContextArgs(subjectId: 's2', topicId: 't1');
      const a2 = WorldContextArgs(subjectId: 's1', topicId: 't1');
      expect(a == b, isFalse);
      expect(a == a2, isTrue);
      // DBMS → OS → DBMS yields distinct contexts (no stale reuse).
      final dbms = resolveWorldContext(subjectId: 's1', subjectName: 'DBMS');
      final os = resolveWorldContext(
          subjectId: 's2', subjectName: 'Operating Systems');
      final back = resolveWorldContext(subjectId: 's1', subjectName: 'DBMS');
      expect(dbms.worldId, WorldId.dbms);
      expect(os.worldId, WorldId.operatingSystems);
      expect(back, dbms);
      expect(back == os, isFalse);
    });
  });

  group('routes preserve world routing ids', () {
    test('world route carries backend subjectId', () {
      // Route helpers are string-level; assert shape without a router.
      expect(
        WorldCatalog.byKey('DBMS')?.key,
        'DBMS',
      );
      final ctx = resolveWorldContext(
        subjectId: '11111111-1111-1111-1111-111111111101',
        subjectName: 'Computer Networks',
        topicId: '22222222-2222-2222-2222-222222222202',
      );
      expect(ctx.worldId, WorldId.computerNetworks);
      expect(ctx.subjectId, isNotEmpty);
      expect(ctx.topicId, isNotEmpty);
    });
  });
}
