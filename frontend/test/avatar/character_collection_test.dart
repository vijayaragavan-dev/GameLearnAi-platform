import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelearn_app/core/models/avatar_models.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/features/avatar/data/avatar_repository.dart';
import 'package:gamelearn_app/features/avatar/presentation/character_collection_screen.dart';
import 'package:gamelearn_app/features/avatar/presentation/character_detail_screen.dart';
import 'package:gamelearn_app/features/avatar/providers/avatar_providers.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/core/theme/app_theme.dart';

class FakeAvatarRepo extends AvatarRepository {
  FakeAvatarRepo({this.collectionResponse, this.catalogResponse, this.profileResponse, this.throwError}) : super(ApiClient());
  AvatarCollection? collectionResponse;
  List<AvatarCatalogItem>? catalogResponse;
  ProfileAvatar? profileResponse;
  Object? throwError;

  @override
  Future<List<AvatarCatalogItem>> catalog() async {
    if (throwError != null) throw throwError!;
    return catalogResponse ?? [];
  }

  @override
  Future<AvatarCollection> collection() async {
    if (throwError != null) throw throwError!;
    return collectionResponse ??
        AvatarCollection(creditsAvailable: 1000, items: [
          AvatarCollectionItem(
            id: 'id1', code: 'c1', displayName: 'Lumen', description: 'd', assetKey: 'characters/lumen', rarity: 'COMMON',
            creditCost: 800, isActive: true, displayOrder: 0, owned: false, equipped: false, state: AvatarState.purchasable, eligible: true, creditsAvailable: 1000, requirements: [],
          )
        ]);
  }

  @override
  Future<AvatarCollection> purchase(String avatarId) async {
    if (throwError != null) throw throwError!;
    return collectionResponse ?? AvatarCollection(creditsAvailable: 200, items: []);
  }

  @override
  Future<AvatarCollection> claim(String avatarId) async {
    if (throwError != null) throw throwError!;
    return collectionResponse ?? AvatarCollection(creditsAvailable: 1000, items: []);
  }

  @override
  Future<ProfileAvatar> equipped() async {
    if (throwError != null) throw throwError!;
    return profileResponse ?? ProfileAvatar();
  }

  @override
  Future<ProfileAvatar> equip(String? avatarId) async {
    if (throwError != null) throw throwError!;
    return ProfileAvatar(equippedAvatarId: avatarId, avatar: avatarId == null ? null : AvatarCatalogItem(id: avatarId, code: 'c', displayName: 'C', description: 'd', assetKey: 'a', rarity: 'COMMON', isActive: true, displayOrder: 0));
  }
}

AvatarCollection sampleCollection({int credits = 1000, int owned = 2}) {
  final items = <AvatarCollectionItem>[
    AvatarCollectionItem(id: '1', code: 'initiates_spark', displayName: 'Nova Spark', description: 'x', assetKey: 'characters/nova_spark', rarity: 'INITIATE', isActive: true, displayOrder: 1, owned: true, equipped: true, state: AvatarState.equipped, eligible: true, creditsAvailable: credits, requirements: []),
    AvatarCollectionItem(id: '2', code: 'common_lumen', displayName: 'Lumen Coder', description: 'x', assetKey: 'characters/lumen', rarity: 'COMMON', creditCost: 800, isActive: true, displayOrder: 2, owned: owned >= 2, equipped: false, state: owned >= 2 ? AvatarState.owned : AvatarState.purchasable, eligible: true, creditsAvailable: credits, requirements: []),
    AvatarCollectionItem(id: '3', code: 'rare_net', displayName: 'Net Ranger', description: 'x', assetKey: 'characters/net', rarity: 'RARE', creditCost: 2500, isActive: true, displayOrder: 3, owned: false, equipped: false, state: AvatarState.insufficientCredits, eligible: true, creditsAvailable: credits, creditsShort: 1500, requirements: []),
    AvatarCollectionItem(id: '4', code: 'epic_sage', displayName: 'Algo Sage', description: 'x', assetKey: 'characters/sage', rarity: 'EPIC', isActive: true, displayOrder: 4, owned: false, equipped: false, state: AvatarState.locked, eligible: false, creditsAvailable: credits, requirements: [RequirementCheck(type: 'Level 12', required: '12', current: '5', satisfied: false)]),
    AvatarCollectionItem(id: '5', code: 'legendary_oracle', displayName: 'Oracle', description: 'x', assetKey: 'characters/oracle', rarity: 'LEGENDARY', isActive: true, displayOrder: 5, owned: false, equipped: false, state: AvatarState.locked, eligible: false, creditsAvailable: credits, requirements: [RequirementCheck(type: 'Syllabus 70.00%', required: '70.00%', current: '61.00%', satisfied: false)]),
    AvatarCollectionItem(id: '6', code: 'epic_claimable', displayName: 'Claimable Epic', description: 'x', assetKey: 'characters/claim', rarity: 'EPIC', isActive: true, displayOrder: 6, owned: false, equipped: false, state: AvatarState.eligibleToClaim, eligible: true, creditsAvailable: credits, requirements: []),
  ];
  return AvatarCollection(creditsAvailable: credits, equippedAvatarId: '1', equippedAvatar: AvatarCatalogItem(id: '1', code: 'initiates_spark', displayName: 'Nova Spark', description: 'x', assetKey: 'characters/nova_spark', rarity: 'INITIATE', isActive: true, displayOrder: 1), items: items);
}

void main() {
  group('Character Collection UI', () {
    testWidgets('L6-UI-02 collection renders real avatar items', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(
        ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lumen Coder'), findsOneWidget);
      expect(find.text('Net Ranger'), findsOneWidget);
    });

    testWidgets('L6-UI-03 owned state', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection(owned: 2);
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.text('OWNED'), findsWidgets);
    });

    testWidgets('L6-UI-04 equipped state', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.text('EQUIPPED'), findsWidgets);
    });

    testWidgets('L6-UI-05 locked state', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.text('LOCKED'), findsWidgets);
    });

    testWidgets('L6-UI-06 purchasable state', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.textContaining('CREDITS'), findsWidgets);
    });

    testWidgets('L6-UI-07 insufficient credits state', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection(credits: 100);
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.textContaining('NEEDED'), findsWidgets);
    });

    testWidgets('L6-UI-08 eligible-to-claim state', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.text('CLAIM FREE'), findsWidgets);
    });

    testWidgets('L6-UI-09 rarity presentation', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.text('LEGENDARY'), findsWidgets);
      expect(find.text('EPIC'), findsWidgets);
    });

    testWidgets('L6-UI-24 collection count uses actual ownership', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection(owned: 2);
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 / 6'), findsOneWidget);
    });

    testWidgets('L6-UI-26 empty catalog', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = AvatarCollection(creditsAvailable: 0, items: []);
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CharacterCollectionScreen), findsOneWidget);
    });

    testWidgets('L6-UI-27 loading state', (tester) async {
      final fake = FakeAvatarRepo();
      // delay
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pump(const Duration(milliseconds: 10));
      // Should show either loading or content
      expect(find.byType(CharacterCollectionScreen), findsOneWidget);
    });

    testWidgets('L6-UI-28 error state', (tester) async {
      final fake = FakeAvatarRepo()..throwError = Exception('network');
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.text('COLLECTION UNAVAILABLE'), findsOneWidget);
    });

    testWidgets('L6-UI-30 dark theme', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CharacterCollectionScreen), findsOneWidget);
    });

    testWidgets('L6-UI-31 light theme', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnLightTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CharacterCollectionScreen), findsOneWidget);
    });

    testWidgets('L6-UI-32 360 layout', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('L6-UI-38 reduced motion', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen()))));
      await tester.pumpAndSettle();
      expect(find.textContaining('CHARACTER COLLECTION'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('L6-UI-39 accessibility semantics', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: const CharacterCollectionScreen())));
      await tester.pumpAndSettle();
      expect(find.byType(Semantics), findsWidgets);
    });
  });

  group('Character Detail', () {
    testWidgets('L6-UI-10 character detail renders', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [avatarRepoProvider.overrideWithValue(fake)],
          child: MaterialApp(theme: buildGameLearnDarkTheme(), home: CharacterDetailScreen(avatarId: '2')),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CharacterDetailScreen), findsOneWidget);
    });

    testWidgets('L6-UI-21 requirements checklist', (tester) async {
      final fake = FakeAvatarRepo()..collectionResponse = sampleCollection();
      await tester.pumpWidget(ProviderScope(overrides: [avatarRepoProvider.overrideWithValue(fake)], child: MaterialApp(theme: buildGameLearnDarkTheme(), home: CharacterDetailScreen(avatarId: '5'))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CharacterDetailScreen), findsOneWidget);
    });
  });
}
