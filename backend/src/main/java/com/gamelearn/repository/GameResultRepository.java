package com.gamelearn.repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.GameResult;

public interface GameResultRepository extends JpaRepository<GameResult, UUID> {

    /** Idempotency: same caller UUID + same user => at most one row. */
    Optional<GameResult> findByUserIdAndClientRequestId(UUID userId, UUID clientRequestId);

    List<GameResult> findByUserIdOrderByPlayedAtDesc(UUID userId);

    List<GameResult> findByUserIdAndGameTypeOrderByPlayedAtDesc(UUID userId, String gameType);

    /** Aggregate counts over a user's game results (used by per-game widgets). */
    @Query("SELECT COUNT(g) FROM GameResult g WHERE g.user.id = :userId AND g.completed = true")
    long countCompletedByUserId(@Param("userId") UUID userId);

    long countByUserIdAndGameType(UUID userId, String gameType);

    @Query("SELECT COUNT(g) FROM GameResult g WHERE g.user.id = :userId AND g.gameType = :gameType AND g.completed = true")
    long countCompletedByUserIdAndGameType(@Param("userId") UUID userId, @Param("gameType") String gameType);

    /** Sum XP awarded for a user across a given game type. */
    @Query("SELECT COALESCE(SUM(g.xpAwarded), 0) FROM GameResult g WHERE g.user.id = :userId AND g.gameType = :gameType")
    int sumXpAwardedByUserIdAndGameType(@Param("userId") UUID userId, @Param("gameType") String gameType);

    /** Highest score and highest combo per (user, game) for "best score" widgets. */
    @Query("SELECT MAX(g.score) FROM GameResult g WHERE g.user.id = :userId AND g.gameType = :gameType")
    Integer maxScoreByUserIdAndGameType(@Param("userId") UUID userId, @Param("gameType") String gameType);

    @Query("SELECT MAX(g.bestCombo) FROM GameResult g WHERE g.user.id = :userId AND g.gameType = :gameType")
    Integer maxComboByUserIdAndGameType(@Param("userId") UUID userId, @Param("gameType") String gameType);

    @Query("SELECT MAX(g.playedAt) FROM GameResult g WHERE g.user.id = :userId")
    Optional<Instant> findLastPlayedAt(@Param("userId") UUID userId);

    @Query("SELECT MAX(g.playedAt) FROM GameResult g WHERE g.user.id = :userId AND g.gameType = :gameType")
    Optional<Instant> findLastPlayedAtByUserIdAndGameType(@Param("userId") UUID userId,
                                                           @Param("gameType") String gameType);
}
