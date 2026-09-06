import 'model_ids.dart';

enum AvatarState {
  locked,
  purchasable,
  insufficientCredits,
  eligibleToClaim,
  owned,
  equipped,
  unknown;

  static AvatarState fromString(String? raw) {
    final v = raw?.trim().toLowerCase();
    return switch (v) {
      'locked' || 'requirements_not_met' => locked,
      'purchasable' => purchasable,
      'insufficient_credits' => insufficientCredits,
      'eligible_to_claim' => eligibleToClaim,
      'owned' => owned,
      'equipped' => equipped,
      _ => unknown,
    };
  }
}

class AvatarRequirementInfo {
  const AvatarRequirementInfo({
    this.levelMin,
    this.syllabusCompletionMin,
    this.syllabusSubjectId,
    this.streakCurrentMin,
    this.streakLongestMin,
    this.bossBattlesMin,
    this.masteredCountMin,
  });

  final int? levelMin;
  final double? syllabusCompletionMin;
  final String? syllabusSubjectId;
  final int? streakCurrentMin;
  final int? streakLongestMin;
  final int? bossBattlesMin;
  final int? masteredCountMin;

  factory AvatarRequirementInfo.fromJson(Map<String, dynamic> json) => AvatarRequirementInfo(
        levelMin: (json['levelMin'] as num?)?.toInt(),
        syllabusCompletionMin: (json['syllabusCompletionMin'] as num?)?.toDouble(),
        syllabusSubjectId: json['syllabusSubjectId'] as String?,
        streakCurrentMin: (json['streakCurrentMin'] as num?)?.toInt(),
        streakLongestMin: (json['streakLongestMin'] as num?)?.toInt(),
        bossBattlesMin: (json['bossBattlesMin'] as num?)?.toInt(),
        masteredCountMin: (json['masteredCountMin'] as num?)?.toInt(),
      );
}

class AvatarCatalogItem {
  const AvatarCatalogItem({
    required this.id,
    required this.code,
    required this.displayName,
    required this.description,
    required this.assetKey,
    required this.rarity,
    this.creditCost,
    required this.isActive,
    required this.displayOrder,
    this.requirement,
  });

  final String id;
  final String code;
  final String displayName;
  final String description;
  final String assetKey;
  final String rarity;
  final int? creditCost;
  final bool isActive;
  final int displayOrder;
  final AvatarRequirementInfo? requirement;

  factory AvatarCatalogItem.fromJson(Map<String, dynamic> json) => AvatarCatalogItem(
        id: uuidOf(json['id'], 'AvatarCatalogItem.id'),
        code: json['code'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        assetKey: json['assetKey'] as String? ?? 'characters/nova_spark',
        rarity: json['rarity'] as String? ?? 'COMMON',
        creditCost: (json['creditCost'] as num?)?.toInt(),
        isActive: json['isActive'] as bool? ?? true,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        requirement: json['requirement'] is Map<String, dynamic>
            ? AvatarRequirementInfo.fromJson(json['requirement'] as Map<String, dynamic>)
            : null,
      );
}

class RequirementCheck {
  const RequirementCheck({
    required this.type,
    this.required,
    this.current,
    required this.satisfied,
  });

  final String type;
  final Object? required;
  final Object? current;
  final bool satisfied;

  factory RequirementCheck.fromJson(Map<String, dynamic> json) => RequirementCheck(
        type: json['type'] as String? ?? 'unknown',
        required: json['required'],
        current: json['current'],
        satisfied: json['satisfied'] as bool? ?? false,
      );
}

class AvatarCollectionItem {
  const AvatarCollectionItem({
    required this.id,
    required this.code,
    required this.displayName,
    required this.description,
    required this.assetKey,
    required this.rarity,
    this.creditCost,
    required this.isActive,
    required this.displayOrder,
    required this.owned,
    required this.equipped,
    required this.state,
    required this.eligible,
    this.creditsRequired,
    required this.creditsAvailable,
    this.creditsShort,
    required this.requirements,
  });

  final String id;
  final String code;
  final String displayName;
  final String description;
  final String assetKey;
  final String rarity;
  final int? creditCost;
  final bool isActive;
  final int displayOrder;
  final bool owned;
  final bool equipped;
  final AvatarState state;
  final bool eligible;
  final int? creditsRequired;
  final int creditsAvailable;
  final int? creditsShort;
  final List<RequirementCheck> requirements;

  factory AvatarCollectionItem.fromJson(Map<String, dynamic> json) => AvatarCollectionItem(
        id: uuidOf(json['id'], 'AvatarCollectionItem.id'),
        code: json['code'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        assetKey: json['assetKey'] as String? ?? 'characters/nova_spark',
        rarity: json['rarity'] as String? ?? 'COMMON',
        creditCost: (json['creditCost'] as num?)?.toInt(),
        isActive: json['isActive'] as bool? ?? true,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        owned: json['owned'] as bool? ?? false,
        equipped: json['equipped'] as bool? ?? false,
        state: AvatarState.fromString(json['state'] as String?),
        eligible: json['eligible'] as bool? ?? false,
        creditsRequired: (json['creditsRequired'] as num?)?.toInt(),
        creditsAvailable: (json['creditsAvailable'] as num?)?.toInt() ?? 0,
        creditsShort: (json['creditsShort'] as num?)?.toInt(),
        requirements: json['requirements'] is List
            ? (json['requirements'] as List).whereType<Map<String, dynamic>>().map(RequirementCheck.fromJson).toList(growable: false)
            : const [],
      );
}

class AvatarCollection {
  const AvatarCollection({
    required this.creditsAvailable,
    this.equippedAvatarId,
    this.equippedAvatar,
    required this.items,
  });

  final int creditsAvailable;
  final String? equippedAvatarId;
  final AvatarCatalogItem? equippedAvatar;
  final List<AvatarCollectionItem> items;

  factory AvatarCollection.fromJson(Map<String, dynamic> json) => AvatarCollection(
        creditsAvailable: (json['creditsAvailable'] as num?)?.toInt() ?? 0,
        equippedAvatarId: json['equippedAvatarId'] as String?,
        equippedAvatar: json['equippedAvatar'] is Map<String, dynamic>
            ? AvatarCatalogItem.fromJson(json['equippedAvatar'] as Map<String, dynamic>)
            : null,
        items: json['items'] is List
            ? (json['items'] as List).whereType<Map<String, dynamic>>().map(AvatarCollectionItem.fromJson).toList(growable: false)
            : const [],
      );
}

class ProfileAvatar {
  const ProfileAvatar({this.equippedAvatarId, this.avatar});

  final String? equippedAvatarId;
  final AvatarCatalogItem? avatar;

  bool get hasEquipped => equippedAvatarId != null && avatar != null;

  String get assetKey => avatar?.assetKey ?? 'characters/nova_spark';
  String get rarity => avatar?.rarity ?? 'INITIATE';

  factory ProfileAvatar.fromJson(Map<String, dynamic> json) => ProfileAvatar(
        equippedAvatarId: json['equippedAvatarId'] as String?,
        avatar: json['avatar'] is Map<String, dynamic>
            ? AvatarCatalogItem.fromJson(json['avatar'] as Map<String, dynamic>)
            : null,
      );
}
