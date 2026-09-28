import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/avatar/data/avatar_repository.dart';

class RecordingApiClient extends ApiClient {
  RecordingApiClient(this.responses);

  final Map<String, dynamic> responses;
  String? lastPath;
  String? lastPostPath;
  Object? lastPostBody;
  Map<String, String>? lastQuery;

  @override
  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query, Duration? timeout}) async {
    lastPath = path;
    lastQuery = query;
    final v = responses[path];
    if (v is ApiException) throw v;
    if (v is Map<String, dynamic>) return v;
    return <String, dynamic>{};
  }

  @override
  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    lastPath = path;
    lastQuery = query;
    final v = responses[path];
    if (v is ApiException) throw v;
    if (v is List) return v;
    return [];
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, Object? body, {bool expectBody = true, Duration? timeout}) async {
    lastPostPath = path;
    lastPostBody = body;
    final v = responses[path];
    if (v is ApiException) throw v;
    if (v is Map<String, dynamic>) return v;
    return <String, dynamic>{};
  }
}

void main() {
  group('AvatarRepository', () {
    test('F-API-04 avatar catalog endpoint correct', () async {
      final client = RecordingApiClient({
        '/api/v1/avatars': [
          {
            'id': '22222222-2222-2222-2222-222222222011',
            'code': 'common_lumen_coder',
            'displayName': 'Lumen Coder',
            'description': 'x',
            'assetKey': 'characters/lumen_coder',
            'rarity': 'COMMON',
            'creditCost': 1200,
            'isActive': true,
            'displayOrder': 10,
          }
        ]
      });
      final repo = AvatarRepository(client);
      final list = await repo.catalog();
      expect(client.lastPath, '/api/v1/avatars');
      expect(list.length, 1);
      expect(list.first.code, 'common_lumen_coder');
    });

    test('F-API-05 avatar collection endpoint correct', () async {
      final client = RecordingApiClient({
        '/api/v1/avatars/me': {
          'creditsAvailable': 1000,
          'equippedAvatarId': null,
          'items': [],
        }
      });
      final repo = AvatarRepository(client);
      final coll = await repo.collection();
      expect(client.lastPath, '/api/v1/avatars/me');
      expect(coll.creditsAvailable, 1000);
    });

    test('F-API-06 purchase endpoint correct', () async {
      final client = RecordingApiClient({
        '/api/v1/avatars/abc/purchase': {
          'creditsAvailable': 100,
          'items': [],
        }
      });
      final repo = AvatarRepository(client);
      await repo.purchase('abc');
      expect(client.lastPostPath, '/api/v1/avatars/abc/purchase');
    });

    test('F-API-07 claim endpoint correct', () async {
      final client = RecordingApiClient({
        '/api/v1/avatars/abc/claim': {
          'creditsAvailable': 100,
          'items': [],
        }
      });
      final repo = AvatarRepository(client);
      await repo.claim('abc');
      expect(client.lastPostPath, '/api/v1/avatars/abc/claim');
    });

    test('F-API-08 equip endpoint correct', () async {
      final client = RecordingApiClient({
        '/api/v1/profile/avatar': {
          'equippedAvatarId': 'abc',
          'avatar': {
            'id': 'abc',
            'code': 'c',
            'displayName': 'C',
            'description': 'x',
            'assetKey': 'characters/c',
            'rarity': 'COMMON',
            'isActive': true,
            'displayOrder': 0,
          }
        }
      });
      final repo = AvatarRepository(client);
      final res = await repo.equip('abc');
      expect(client.lastPostPath, '/api/v1/profile/avatar');
      expect(res.equippedAvatarId, 'abc');
    });

    test('F-API-09 unequip sends null avatarId', () async {
      final client = RecordingApiClient({
        '/api/v1/profile/avatar': {'equippedAvatarId': null, 'avatar': null}
      });
      final repo = AvatarRepository(client);
      await repo.unequip();
      expect(client.lastPostPath, '/api/v1/profile/avatar');
      expect((client.lastPostBody as Map)['avatarId'], isNull);
    });

    test('F-API-12 402 maps to insufficient credits', () async {
      final client = RecordingApiClient({
        '/api/v1/avatars/abc/purchase': const InsufficientCreditsException(),
      });
      final repo = AvatarRepository(client);
      expect(() => repo.purchase('abc'), throwsA(isA<InsufficientCreditsException>()));
    });

    test('F-API-13 403 maps correctly', () async {
      final client = RecordingApiClient({
        '/api/v1/avatars/abc/claim': const RequirementsNotMetException(),
      });
      final repo = AvatarRepository(client);
      expect(() => repo.claim('abc'), throwsA(isA<RequirementsNotMetException>()));
    });

    test('F-API-14 404 maps correctly', () async {
      final client = RecordingApiClient({
        '/api/v1/avatars/abc/purchase': const NotFoundException(),
      });
      final repo = AvatarRepository(client);
      expect(() => repo.purchase('abc'), throwsA(isA<NotFoundException>()));
    });

    test('F-API-15 409 maps correctly', () async {
      final client = RecordingApiClient({
        '/api/v1/avatars/abc/purchase': const ConflictException('already owned'),
      });
      final repo = AvatarRepository(client);
      expect(() => repo.purchase('abc'), throwsA(isA<ConflictException>()));
    });
  });
}
