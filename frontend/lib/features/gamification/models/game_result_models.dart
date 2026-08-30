/// Game-result submission payload (PROG-101) and server response (PROG-101
/// success) and per-game progress (PROG-102). The server is the source of
/// truth; the frontend sends a client-generated UUID for idempotency and a
/// server-validated outcome, never a desired XP value.
class GameResultSubmission {
  const GameResultSubmission({
    required this.clientRequestId,
    required this.gameType,
    required this.completed,
    required this.score,
    required this.durationSeconds,
    required this.bestCombo,
  });

  final String clientRequestId;
  final String gameType;
  final bool completed;
  final int score;
  final int durationSeconds;
  final int bestCombo;

  Map<String, dynamic> toJson() => {
        'clientRequestId': clientRequestId,
        'gameType': gameType,
        'completed': completed,
        'score': score,
        'durationSeconds': durationSeconds,
        'bestCombo': bestCombo,
      };
}

class GameResultSubmissionResponse {
  const GameResultSubmissionResponse({
    required this.requestId,
    required this.xpEarned,
    required this.previousLevel,
    required this.currentLevel,
    required this.previousTotalXp,
    required this.currentTotalXp,
    required this.leveledUp,
    required this.levelsGained,
    required this.playedAt,
  });

  final String requestId;
  final int xpEarned;
  final int previousLevel;
  final int currentLevel;
  final int previousTotalXp;
  final int currentTotalXp;
  final bool leveledUp;
  final int levelsGained;
  final DateTime playedAt;
  final int? nextLevelThresholdXp = null;
  final int? xpToNextLevel = null;

  factory GameResultSubmissionResponse.fromJson(Map<String, dynamic> json) =>
      GameResultSubmissionResponse(
        requestId: json['requestId'] as String,
        xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
        previousLevel: (json['previousLevel'] as num?)?.toInt() ?? 1,
        currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
        previousTotalXp: (json['previousTotalXp'] as num?)?.toInt() ?? 0,
        currentTotalXp: (json['currentTotalXp'] as num?)?.toInt() ?? 0,
        leveledUp: json['leveledUp'] as bool? ?? false,
        levelsGained: (json['levelsGained'] as num?)?.toInt() ?? 0,
        playedAt: DateTime.tryParse(json['playedAt'] as String? ?? '')?.toUtc() ??
            DateTime.now().toUtc(),
        nextLevelThresholdXp: (json['nextLevelThresholdXp'] as num?)?.toInt(),
        xpToNextLevel: (json['xpToNextLevel'] as num?)?.toInt(),
      );
}

class GameResultProgress {
  const GameResultProgress({
    required this.gameType,
    required this.gamesPlayed,
    required this.gamesCompleted,
    required this.bestScore,
    required this.bestCombo,
    required this.totalXpEarned,
    required this.lastPlayedAt,
  });

  final String gameType;
  final int gamesPlayed;
  final int gamesCompleted;
  final int bestScore;
  final int bestCombo;
  final int totalXpEarned;
  final DateTime? lastPlayedAt;

  factory GameResultProgress.fromJson(Map<String, dynamic> json) =>
      GameResultProgress(
        gameType: json['gameType'] as String? ?? '',
        gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
        gamesCompleted: (json['gamesCompleted'] as num?)?.toInt() ?? 0,
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
        bestCombo: (json['bestCombo'] as num?)?.toInt() ?? 0,
        totalXpEarned: (json['totalXpEarned'] as num?)?.toInt() ?? 0,
        lastPlayedAt: DateTime.tryParse(json['lastPlayedAt'] as String? ?? '')
            ?.toUtc(),
      );
}
