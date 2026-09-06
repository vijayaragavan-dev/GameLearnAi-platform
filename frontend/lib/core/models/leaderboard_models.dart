

/// Server segment for leaderboard queries.
enum LeaderboardSegment { overall, subject }

/// Strongly-typed avatar rarity with safe fallback.
enum AvatarRarity {
  initiate,
  common,
  rare,
  epic,
  legendary,
  prestige,
  unknown;

  static AvatarRarity fromString(String? raw) {
    final v = raw?.trim().toLowerCase();
    return switch (v) {
      'initiate' => initiate,
      'common' => common,
      'rare' => rare,
      'epic' => epic,
      'legendary' => legendary,
      'prestige' => prestige,
      _ => unknown,
    };
  }
}

class LeaderboardAvatar {
  const LeaderboardAvatar({required this.assetKey, required this.rarity});

  final String assetKey;
  final AvatarRarity rarity;

  factory LeaderboardAvatar.fromJson(Map<String, dynamic> json) => LeaderboardAvatar(
        assetKey: json['assetKey'] as String? ?? 'characters/nova_spark',
        rarity: AvatarRarity.fromString(json['rarity'] as String?),
      );

  Map<String, dynamic> toJson() => {'assetKey': assetKey, 'rarity': rarity.name};
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.avatar,
    required this.level,
    required this.totalXp,
    this.subjectXp,
    this.streakDays,
    this.mastery,
    this.isMe = false,
    this.rankDelta,
  });

  final int rank;
  final String displayName;
  final LeaderboardAvatar avatar;
  final int level;
  final int totalXp;
  final int? subjectXp;
  final int? streakDays;
  final double? mastery;
  final bool isMe;
  final int? rankDelta;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        displayName: json['displayName'] as String? ?? 'Player',
        avatar: json['avatar'] is Map<String, dynamic>
            ? LeaderboardAvatar.fromJson(json['avatar'] as Map<String, dynamic>)
            : const LeaderboardAvatar(assetKey: 'characters/nova_spark', rarity: AvatarRarity.initiate),
        level: (json['level'] as num?)?.toInt() ?? 1,
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
        subjectXp: (json['subjectXp'] as num?)?.toInt(),
        streakDays: (json['streakDays'] as num?)?.toInt(),
        mastery: (json['mastery'] as num?)?.toDouble(),
        isMe: json['isMe'] as bool? ?? false,
        rankDelta: (json['rankDelta'] as num?)?.toInt(),
      );
}

class LeaderboardResponse {
  const LeaderboardResponse({
    required this.segment,
    required this.season,
    this.subjectId,
    this.subjectName,
    required this.page,
    required this.size,
    required this.totalPlayers,
    required this.totalPages,
    required this.top,
    required this.entries,
    this.me,
    required this.nearby,
    this.generatedAt,
    this.cacheTtlSeconds,
  });

  final String segment;
  final String season;
  final String? subjectId;
  final String? subjectName;
  final int page;
  final int size;
  final int totalPlayers;
  final int totalPages;
  final List<LeaderboardEntry> top;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? me;
  final List<LeaderboardEntry> nearby;
  final DateTime? generatedAt;
  final int? cacheTtlSeconds;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    List<LeaderboardEntry> parseList(dynamic v) {
      if (v is! List) return const [];
      return v.whereType<Map<String, dynamic>>().map(LeaderboardEntry.fromJson).toList(growable: false);
    }

    return LeaderboardResponse(
      segment: json['segment'] as String? ?? 'OVERALL',
      season: json['season'] as String? ?? 'LIFETIME',
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      page: (json['page'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalPlayers: (json['totalPlayers'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      top: parseList(json['top']),
      entries: parseList(json['entries']),
      me: json['me'] is Map<String, dynamic> ? LeaderboardEntry.fromJson(json['me'] as Map<String, dynamic>) : null,
      nearby: parseList(json['nearby']),
      generatedAt: json['generatedAt'] is String ? DateTime.tryParse(json['generatedAt'] as String)?.toUtc() : null,
      cacheTtlSeconds: (json['cacheTtlSeconds'] as num?)?.toInt(),
    );
  }
}

class LeaderboardPosition {
  const LeaderboardPosition({
    required this.segment,
    this.subjectId,
    required this.rank,
    required this.totalXp,
    this.subjectXp,
    required this.level,
    this.xpToNextRank,
    this.nextRank,
    this.nextRankXp,
    required this.totalPlayers,
    this.avatar,
    required this.top,
  });

  final String segment;
  final String? subjectId;
  final int rank;
  final int totalXp;
  final int? subjectXp;
  final int level;
  final int? xpToNextRank;
  final int? nextRank;
  final int? nextRankXp;
  final int totalPlayers;
  final LeaderboardAvatar? avatar;
  final List<LeaderboardEntry> top;

  factory LeaderboardPosition.fromJson(Map<String, dynamic> json) => LeaderboardPosition(
        segment: json['segment'] as String? ?? 'OVERALL',
        subjectId: json['subjectId'] as String?,
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
        subjectXp: (json['subjectXp'] as num?)?.toInt(),
        level: (json['level'] as num?)?.toInt() ?? 1,
        xpToNextRank: (json['xpToNextRank'] as num?)?.toInt(),
        nextRank: (json['nextRank'] as num?)?.toInt(),
        nextRankXp: (json['nextRankXp'] as num?)?.toInt(),
        totalPlayers: (json['totalPlayers'] as num?)?.toInt() ?? 0,
        avatar: json['avatar'] is Map<String, dynamic>
            ? LeaderboardAvatar.fromJson(json['avatar'] as Map<String, dynamic>)
            : null,
        top: json['top'] is List
            ? (json['top'] as List).whereType<Map<String, dynamic>>().map(LeaderboardEntry.fromJson).toList(growable: false)
            : const [],
      );
}
