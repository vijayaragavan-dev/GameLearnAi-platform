import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/utils/avatar_asset_resolver.dart';

void main() {
  group('AvatarAssetResolver', () {
    test('L8-01 asset resolver maps assetKey correctly', () {
      expect(resolveAvatarAsset('characters/nova_spark'), 'assets/characters/nova_spark.svg');
      expect(resolveAvatarAsset('characters/lumen_coder'), 'assets/characters/lumen_coder.svg');
      expect(resolveAvatarAsset('characters/oracle_of_data'), 'assets/characters/oracle_of_data.svg');
    });

    test('L8-02 unknown assetKey falls back safely', () {
      expect(resolveAvatarAsset('characters/unknown_xyz'), 'assets/characters/nova_spark.svg');
      expect(resolveAvatarAsset(''), 'assets/characters/nova_spark.svg');
      expect(resolveAvatarAsset(null), 'assets/characters/nova_spark.svg');
    });

    test('L8-03 default Nova Spark fallback', () {
      expect(resolveAvatarAsset('characters/nova_spark'), contains('nova_spark.svg'));
      expect(isKnownAvatarAsset('characters/nova_spark'), true);
      expect(isKnownAvatarAsset('characters/unknown'), false);
    });

    test('L8-28 asset path integrity', () {
      for (final asset in allKnownAvatarAssets) {
        expect(asset, startsWith('assets/characters/'));
        expect(asset, endsWith('.svg'));
      }
    });

    test('L8-29 no arbitrary external asset URL', () {
      expect(resolveAvatarAsset('https://evil.com/malicious.svg'), 'assets/characters/nova_spark.svg');
      expect(resolveAvatarAsset('http://example.com/asset.png'), 'assets/characters/nova_spark.svg');
      expect(resolveAvatarAsset('characters/nova_spark'), isNot(contains('http')));
    });

    test('L8-30 no copyrighted character references in resolver', () {
      for (final asset in allKnownAvatarAssets) {
        expect(asset.toLowerCase(), isNot(contains('subway')));
        expect(asset.toLowerCase(), isNot(contains('marvel')));
        expect(asset.toLowerCase(), isNot(contains('pokemon')));
        expect(asset.toLowerCase(), isNot(contains('anime')));
      }
    });
  });
}
