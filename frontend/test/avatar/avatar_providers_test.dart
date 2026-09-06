import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelearn_app/core/models/avatar_models.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/avatar/data/avatar_repository.dart';
import 'package:gamelearn_app/features/avatar/providers/avatar_providers.dart';
import 'package:gamelearn_app/core/providers.dart';

class FakeAvatarRepo extends AvatarRepository {
  FakeAvatarRepo() : super(ApiClient());
  int catalogCalls = 0;
  int collectionCalls = 0;
  int purchaseCalls = 0;
  int claimCalls = 0;
  int equipCalls = 0;
  AvatarCollection? collectionResponse;
  List<AvatarCatalogItem>? catalogResponse;
  ProfileAvatar? profileResponse;
  Object? throwError;
  String? lastPurchasedId;
  String? lastClaimedId;
  String? lastEquippedId;

  @override
  Future<List<AvatarCatalogItem>> catalog() async {
    catalogCalls++;
    if (throwError != null) throw throwError!;
    return catalogResponse ??
        [
          AvatarCatalogItem(
            id: 'id1',
            code: 'c1',
            displayName: 'C1',
            description: 'd',
            assetKey: 'a',
            rarity: 'COMMON',
            isActive: true,
            displayOrder: 0,
          )
        ];
  }

  @override
  Future<AvatarCollection> collection() async {
    collectionCalls++;
    if (throwError != null) throw throwError!;
    return collectionResponse ??
        AvatarCollection(creditsAvailable: 1000, items: [
          AvatarCollectionItem(
            id: 'id1',
            code: 'c1',
            displayName: 'C1',
            description: 'd',
            assetKey: 'a',
            rarity: 'COMMON',
            creditCost: 800,
            isActive: true,
            displayOrder: 0,
            owned: false,
            equipped: false,
            state: AvatarState.purchasable,
            eligible: true,
            creditsAvailable: 1000,
            requirements: [],
          )
        ]);
  }

  @override
  Future<AvatarCollection> purchase(String avatarId) async {
    purchaseCalls++;
    lastPurchasedId = avatarId;
    if (throwError != null) throw throwError!;
    return collectionResponse ??
        AvatarCollection(creditsAvailable: 200, items: [
          AvatarCollectionItem(
            id: avatarId,
            code: 'c1',
            displayName: 'C1',
            description: 'd',
            assetKey: 'a',
            rarity: 'COMMON',
            isActive: true,
            displayOrder: 0,
            owned: true,
            equipped: false,
            state: AvatarState.owned,
            eligible: true,
            creditsAvailable: 200,
            requirements: [],
          )
        ]);
  }

  @override
  Future<AvatarCollection> claim(String avatarId) async {
    claimCalls++;
    lastClaimedId = avatarId;
    if (throwError != null) throw throwError!;
    return collection();
  }

  @override
  Future<ProfileAvatar> equipped() async {
    if (throwError != null) throw throwError!;
    return profileResponse ?? ProfileAvatar(avatar: null);
  }

  @override
  Future<ProfileAvatar> equip(String? avatarId) async {
    equipCalls++;
    lastEquippedId = avatarId;
    if (throwError != null) throw throwError!;
    return ProfileAvatar(
      equippedAvatarId: avatarId,
      avatar: avatarId == null ? null : AvatarCatalogItem(
        id: avatarId,
        code: 'c',
        displayName: 'C',
        description: 'd',
        assetKey: 'a',
        rarity: 'COMMON',
        isActive: true,
        displayOrder: 0,
      ),
    );
  }
}

void main() {
  group('Avatar providers', () {
    test('F-PROV-05 avatar collection loading/success/error', () async {
      final fake = FakeAvatarRepo();
      final container = ProviderContainer(overrides: [avatarRepoProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      final notifier = container.read(avatarCollectionProvider.notifier);
      await notifier.load();
      expect(container.read(avatarCollectionProvider).data?.creditsAvailable, 1000);
      // error case
      fake.throwError = const ServerErrorException('fail');
      await notifier.load();
      expect(container.read(avatarCollectionProvider).error, isA<ServerErrorException>());
      fake.throwError = null;
    });

    test('F-PROV-06 successful purchase refreshes collection', () async {
      final fake = FakeAvatarRepo();
      final container = ProviderContainer(overrides: [avatarRepoProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      final notifier = container.read(avatarCollectionProvider.notifier);
      await notifier.load();
      expect(fake.collectionCalls, greaterThanOrEqualTo(1));
      await notifier.purchase('id1');
      expect(fake.purchaseCalls, 1);
      expect(container.read(avatarCollectionProvider).data?.items.first.owned, true);
    });

    test('F-PROV-07 failed purchase does not fabricate ownership', () async {
      final fake = FakeAvatarRepo()..throwError = const InsufficientCreditsException();
      final container = ProviderContainer(overrides: [avatarRepoProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      final notifier = container.read(avatarCollectionProvider.notifier);
      await notifier.load();
      final before = container.read(avatarCollectionProvider).data;
      try {
        await notifier.purchase('id1');
        fail('should throw');
      } catch (_) {}
      // error is set, data preserved (previous)
      expect(container.read(avatarCollectionProvider).error, isA<InsufficientCreditsException>());
      expect(container.read(avatarCollectionProvider).data, before);
    });

    test('F-PROV-08 successful claim refreshes collection', () async {
      final fake = FakeAvatarRepo();
      final container = ProviderContainer(overrides: [avatarRepoProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      final notifier = container.read(avatarCollectionProvider.notifier);
      await notifier.claim('id1');
      expect(fake.claimCalls, 1);
      expect(container.read(avatarCollectionProvider).data, isNotNull);
    });

    test('F-PROV-09 successful equip refreshes profile state', () async {
      final fake = FakeAvatarRepo();
      final container = ProviderContainer(overrides: [avatarRepoProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      final notifier = container.read(profileAvatarProvider.notifier);
      await notifier.load();
      await notifier.equip('id1');
      expect(fake.equipCalls, 1);
      expect(container.read(profileAvatarProvider).data?.equippedAvatarId, 'id1');
    });

    test('F-PROV-10 logout clears private state', () async {
      // Simulate logout by disposing provider and checking that new container has fresh state
      final fake = FakeAvatarRepo();
      final container = ProviderContainer(overrides: [avatarRepoProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      await container.read(avatarCollectionProvider.notifier).load();
      expect(container.read(avatarCollectionProvider).data, isNotNull);
      // simulate logout by invalidating
      container.invalidate(avatarCollectionProvider);
      // new read should be loading
      expect(container.read(avatarCollectionProvider).loading, true);
    });
  });
}
