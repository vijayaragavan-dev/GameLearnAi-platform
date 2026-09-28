import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/models/avatar_models.dart';

void main() {
  group('Avatar models', () {
    test('F-AV-01 catalog decodes', () {
      final json = {
        'id': '22222222-2222-2222-2222-222222222011',
        'code': 'common_lumen_coder',
        'displayName': 'Lumen Coder',
        'description': 'Types fast',
        'assetKey': 'characters/lumen_coder',
        'rarity': 'COMMON',
        'creditCost': 1200,
        'isActive': true,
        'displayOrder': 10,
        'requirement': {'levelMin': 2}
      };
      final item = AvatarCatalogItem.fromJson(json);
      expect(item.code, 'common_lumen_coder');
      expect(item.creditCost, 1200);
      expect(item.requirement?.levelMin, 2);
    });

    test('F-AV-02 collection decodes', () {
      final json = {
        'creditsAvailable': 5000,
        'equippedAvatarId': '22222222-2222-2222-2222-222222222011',
        'equippedAvatar': {
          'id': '22222222-2222-2222-2222-222222222011',
          'code': 'common_lumen_coder',
          'displayName': 'Lumen Coder',
          'description': 'x',
          'assetKey': 'characters/lumen_coder',
          'rarity': 'COMMON',
          'creditCost': 1200,
          'isActive': true,
          'displayOrder': 10,
        },
        'items': [
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
            'owned': true,
            'equipped': true,
            'state': 'EQUIPPED',
            'eligible': true,
            'creditsRequired': 1200,
            'creditsAvailable': 5000,
            'requirements': []
          }
        ]
      };
      final coll = AvatarCollection.fromJson(json);
      expect(coll.creditsAvailable, 5000);
      expect(coll.items.length, 1);
      expect(coll.items.first.owned, true);
      expect(coll.items.first.equipped, true);
    });

    test('F-AV-03 requirements decode', () {
      final json = {
        'id': 'id',
        'code': 'epic',
        'displayName': 'Epic',
        'description': 'x',
        'assetKey': 'characters/epic',
        'rarity': 'EPIC',
        'isActive': true,
        'displayOrder': 30,
        'owned': false,
        'equipped': false,
        'state': 'LOCKED',
        'eligible': false,
        'creditsAvailable': 0,
        'requirements': [
          {'type': 'Level 12', 'required': '12', 'current': '5', 'satisfied': false},
          {'type': 'Syllabus 50.00%', 'required': '50.00%', 'current': '0.00%', 'satisfied': false},
        ]
      };
      final item = AvatarCollectionItem.fromJson(json);
      expect(item.requirements.length, 2);
      expect(item.requirements.first.satisfied, false);
    });

    test('F-AV-04 creditsShort decodes', () {
      final json = {
        'id': 'id',
        'code': 'rare',
        'displayName': 'Rare',
        'description': 'x',
        'assetKey': 'characters/rare',
        'rarity': 'RARE',
        'creditCost': 2500,
        'isActive': true,
        'displayOrder': 20,
        'owned': false,
        'equipped': false,
        'state': 'INSUFFICIENT_CREDITS',
        'eligible': true,
        'creditsRequired': 2500,
        'creditsAvailable': 1300,
        'creditsShort': 1200,
        'requirements': []
      };
      final item = AvatarCollectionItem.fromJson(json);
      expect(item.creditsShort, 1200);
      expect(item.state, AvatarState.insufficientCredits);
    });

    test('F-AV-05 owned/equipped states decode', () {
      final ownedJson = {
        'id': 'id',
        'code': 'c',
        'displayName': 'C',
        'description': 'x',
        'assetKey': 'a',
        'rarity': 'COMMON',
        'isActive': true,
        'displayOrder': 0,
        'owned': true,
        'equipped': false,
        'state': 'OWNED',
        'eligible': true,
        'creditsAvailable': 0,
        'requirements': []
      };
      expect(AvatarCollectionItem.fromJson(ownedJson).state, AvatarState.owned);
      final equippedJson = {...ownedJson, 'state': 'EQUIPPED', 'equipped': true};
      expect(AvatarCollectionItem.fromJson(equippedJson).state, AvatarState.equipped);
    });

    test('F-AV-06 unknown state safely handled', () {
      final json = {
        'id': 'id',
        'code': 'c',
        'displayName': 'C',
        'description': 'x',
        'assetKey': 'a',
        'rarity': 'COMMON',
        'isActive': true,
        'displayOrder': 0,
        'owned': false,
        'equipped': false,
        'state': 'FUTURE_STATE_XYZ',
        'eligible': false,
        'creditsAvailable': 0,
        'requirements': []
      };
      final item = AvatarCollectionItem.fromJson(json);
      expect(item.state, AvatarState.unknown);
    });

    test('ProfileAvatar default when null', () {
      final json = {'equippedAvatarId': null, 'avatar': null};
      final pa = ProfileAvatar.fromJson(json);
      expect(pa.hasEquipped, false);
      expect(pa.assetKey, 'characters/nova_spark');
      expect(pa.rarity, 'INITIATE');
    });
  });
}
