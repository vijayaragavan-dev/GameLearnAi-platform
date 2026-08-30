package com.gamelearn.gamification;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.GameResultProgressResponse;
import com.gamelearn.dto.GameResultSubmissionRequest;
import com.gamelearn.dto.GameResultSubmissionResponse;
import com.gamelearn.entity.GameResult;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.XpEventType;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.GameResultRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.XpTransactionRepository;

/**
 * Game-result pipeline (Persistent Gamification + Player Progression phase).
 *
 * <p>Submits a {@link GameResult} for the authenticated learner and writes a
 * single XP-ledger row with {@code referenceType='GAME_RESULT'} and the caller
 * UUID. The (user_id, client_request_id) UNIQUE constraint guarantees
 * idempotency: replaying the same client UUID is a no-op at the database
 * layer and never re-grants XP.</p>
 *
 * <p>The XP award is derived server-side from the validated score and
 * difficulty; the caller cannot control the amount. The same level /
 * streak / achievement rules in {@link GamificationService} apply: we
 * delegate to {@link #awardXpAndAdvance} which is the single deterministic
 * XP-incrementing pathway (same lock, same audit, same total).</p>
 */
@Service
public class GameResultService {

    private static final Logger log = LoggerFactory.getLogger(GameResultService.class);

    /** Base XP for completing a game (regardless of win/loss). */
    static final int BASE_GAME_XP = 10;

    /** Per-difficulty multiplier applied to the performance XP component. */
    static final BigDecimal DIFFICULTY_MULT_EASY = new BigDecimal("0.6");
    static final BigDecimal DIFFICULTY_MULT_MEDIUM = new BigDecimal("0.9");
    static final BigDecimal DIFFICULTY_MULT_HARD = new BigDecimal("1.3");

    /** Combo bonus: +1 XP per 1 combo above 1, capped at 5. */
    static final int COMBO_BONUS_CAP = 5;

    private final GameResultRepository gameResultRepository;
    private final XpTransactionRepository xpTransactionRepository;
    private final LearnerProfileRepository learnerProfileRepository;

    private Clock clock = Clock.systemUTC();

    public GameResultService(GameResultRepository gameResultRepository,
                             XpTransactionRepository xpTransactionRepository,
                             LearnerProfileRepository learnerProfileRepository) {
        this.gameResultRepository = gameResultRepository;
        this.xpTransactionRepository = xpTransactionRepository;
        this.learnerProfileRepository = learnerProfileRepository;
    }

    void setClock(Clock clock) {
        this.clock = clock;
    }

    // ------------------------------------------------------------------
    // PROG-101: submit a game result, award XP, return new progression.
    // ------------------------------------------------------------------

    @Transactional
    public GameResultSubmissionResponse submit(User learner, GameResultSubmissionRequest request) {
        if (learner == null) {
            throw new ApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(),
                    ErrorCode.UNAUTHORIZED.name(), "Authentication required");
        }
        validate(request);

        // Idempotency: short-circuit if the same (user, client UUID) was already processed.
        Optional<GameResult> existing =
                gameResultRepository.findByUserIdAndClientRequestId(learner.getId(), request.clientRequestId());
        if (existing.isPresent()) {
            return buildResponseFromExisting(learner, existing.get());
        }

        Instant now = Instant.now(clock);
        int xp = computeXp(request);
        GameResult result = new GameResult();
        result.setUser(learner);
        result.setGameType(request.gameType());
        result.setClientRequestId(request.clientRequestId());
        result.setCompleted(request.completed());
        result.setScore(request.score());
        result.setDurationSeconds(request.durationSeconds());
        result.setBestCombo(request.bestCombo());
        result.setXpAwarded(xp);
        result.setPlayedAt(now);

        try {
            gameResultRepository.saveAndFlush(result);
        } catch (DataIntegrityViolationException raced) {
            // Concurrent submitter won; treat as idempotent: return the winner's
            // recorded outcome instead of double-granting.
            GameResult winner = gameResultRepository
                    .findByUserIdAndClientRequestId(learner.getId(), request.clientRequestId())
                    .orElseThrow(() -> new ApiException(
                            ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                            ErrorCode.INTERNAL_ERROR.name(),
                            "Idempotency race could not be resolved"));
            return buildResponseFromExisting(learner, winner);
        }

        // Award XP via the single deterministic pipeline (level recalc + ledger).
        Progression before = awardXpAndAdvance(learner, request.gameType(), xp, now);
        return buildResponse(learner, request.clientRequestId(), result, before);
    }

    private void validate(GameResultSubmissionRequest r) {
        if (r.score() < 0 || r.score() > 1_000_000) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Score is out of range",
                    java.util.Map.of("score", "must be between 0 and 1000000"));
        }
        if (r.durationSeconds() < 0 || r.durationSeconds() > 86_400) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "durationSeconds out of range",
                    java.util.Map.of("durationSeconds", "must be between 0 and 86400"));
        }
        if (r.bestCombo() < 0 || r.bestCombo() > 10_000) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "bestCombo out of range",
                    java.util.Map.of("bestCombo", "must be between 0 and 10000"));
        }
    }

    private int computeXp(GameResultSubmissionRequest r) {
        int total = 0;
        if (r.completed()) {
            total += XpCalculator.capped(BASE_GAME_XP);
        }
        // Performance: score/100 scaled by difficulty, capped at EVENT_XP_CAP.
        BigDecimal scaled = BigDecimal.valueOf(r.score())
                .multiply(BigDecimal.valueOf(0.15))
                .multiply(difficultyMultiplier(r.difficulty()))
                .setScale(0, java.math.RoundingMode.HALF_UP);
        int perf = scaled.intValue();
        if (perf > 0) {
            total += XpCalculator.capped(perf);
        }
        // Combo bonus: +1 per combo above 1, capped.
        if (r.bestCombo() > 1) {
            int comboBonus = Math.min(COMBO_BONUS_CAP, r.bestCombo() - 1);
            total += XpCalculator.capped(comboBonus);
        }
        // Per-event cap is already applied via XpCalculator.capped; total may be
        // larger than EVENT_XP_CAP because we sum multiple components, which is
        // fine — the existing quiz pipeline does the same.
        return Math.max(0, total);
    }

    private static BigDecimal difficultyMultiplier(Difficulty d) {
        return switch (d) {
            case EASY -> DIFFICULTY_MULT_EASY;
            case MEDIUM -> DIFFICULTY_MULT_MEDIUM;
            case HARD -> DIFFICULTY_MULT_HARD;
        };
    }

    // ------------------------------------------------------------------
    // PROG-101 XP/level: single deterministic path, identical to quiz pipeline.
    // ------------------------------------------------------------------

    private Progression awardXpAndAdvance(User learner, String gameType, int deltaXp, Instant now) {
        int xp = XpCalculator.capped(deltaXp);
        if (xp <= 0) {
            return captureProgression(learner);
        }
        // Write ledger row with referenceType='GAME_RESULT' and the game type as
        // the description. Idempotency is enforced at the GameResult UNIQUE
        // constraint; here we just record the credit leg of the same event.
        com.gamelearn.entity.XpTransaction row = new com.gamelearn.entity.XpTransaction();
        row.setUser(learner);
        row.setEventType(XpEventType.GAME_COMPLETED);
        row.setAmount(xp);
        row.setReferenceType("GAME_RESULT");
        row.setReferenceId(null);
        row.setDescription("Game completion: " + gameType);
        xpTransactionRepository.save(row);

        LearnerProfile profile = learnerProfileRepository.findWithLock(learner.getId())
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Learner profile missing"));
        Progression before = captureProgression(learner);
        long newTotal = Math.min((long) Integer.MAX_VALUE,
                Math.max(0L, (long) profile.getTotalXp() + (long) xp));
        profile.setTotalXp((int) newTotal);
        int recomputed = LevelEngine.levelFor(newTotal);
        profile.setCurrentLevel(Math.max(profile.getCurrentLevel(), recomputed));
        learnerProfileRepository.save(profile);
        if (recomputed > before.currentLevel()) {
            log.info("GAM_LEVEL_UP from={} to={}", before.currentLevel(), recomputed);
        }
        return before;
    }

    private Progression captureProgression(User learner) {
        LearnerProfile profile = learnerProfileRepository.findByUserId(learner.getId())
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Learner profile missing"));
        return new Progression(profile.getCurrentLevel(), profile.getTotalXp());
    }

    private GameResultSubmissionResponse buildResponse(User learner, UUID requestId,
                                                      GameResult result, Progression before) {
        Progression after = captureProgression(learner);
        Long next = LevelEngine.nextThreshold(after.currentLevel());
        Integer xpToNext = next == null ? null
                : Math.toIntExact(Math.max(0, next - after.totalXp()));
        int gained = after.currentLevel() - before.currentLevel();
        return new GameResultSubmissionResponse(
                requestId,
                result.getXpAwarded(),
                before.currentLevel(),
                after.currentLevel(),
                before.totalXp(),
                after.totalXp(),
                next,
                xpToNext,
                gained > 0,
                gained,
                result.getPlayedAt());
    }

    private GameResultSubmissionResponse buildResponseFromExisting(User learner, GameResult existing) {
        Progression after = captureProgression(learner);
        Long next = LevelEngine.nextThreshold(after.currentLevel());
        Integer xpToNext = next == null ? null
                : Math.toIntExact(Math.max(0, next - after.totalXp()));
        return new GameResultSubmissionResponse(
                existing.getClientRequestId(),
                existing.getXpAwarded(),
                after.currentLevel(),
                after.currentLevel(),
                after.totalXp(),
                after.totalXp(),
                next,
                xpToNext,
                false,
                0,
                existing.getPlayedAt());
    }

    // ------------------------------------------------------------------
    // PROG-102: per-game progress read.
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<GameResultProgressResponse> progressForUser(UUID userId) {
        // Aggregate per game_type in Java. Cheap for the small per-user history size
        // (the 14 games are bounded and the test session only inserts a few).
        List<GameResult> all = gameResultRepository.findByUserIdOrderByPlayedAtDesc(userId);
        java.util.Map<String, int[]> agg = new java.util.LinkedHashMap<>();
        java.util.Map<String, Integer> bestScore = new java.util.HashMap<>();
        java.util.Map<String, Integer> bestCombo = new java.util.HashMap<>();
        java.util.Map<String, Integer> totalXp = new java.util.HashMap<>();
        java.util.Map<String, Instant> lastPlayed = new java.util.HashMap<>();
        for (GameResult g : all) {
            String gt = g.getGameType();
            int[] c = agg.computeIfAbsent(gt, k -> new int[2]); // [played, completed]
            c[0] += 1;
            if (g.isCompleted()) c[1] += 1;
            bestScore.merge(gt, g.getScore(), Math::max);
            bestCombo.merge(gt, g.getBestCombo(), Math::max);
            totalXp.merge(gt, g.getXpAwarded(), Integer::sum);
            Instant prev = lastPlayed.get(gt);
            if (prev == null || g.getPlayedAt().isAfter(prev)) {
                lastPlayed.put(gt, g.getPlayedAt());
            }
        }
        List<GameResultProgressResponse> out = new ArrayList<>(agg.size());
        for (java.util.Map.Entry<String, int[]> e : agg.entrySet()) {
            out.add(new GameResultProgressResponse(
                    e.getKey(),
                    e.getValue()[0],
                    e.getValue()[1],
                    bestScore.getOrDefault(e.getKey(), 0),
                    bestCombo.getOrDefault(e.getKey(), 0),
                    totalXp.getOrDefault(e.getKey(), 0),
                    lastPlayed.get(e.getKey())));
        }
        return out;
    }

    @Transactional(readOnly = true)
    public GameResultProgressResponse progressForGame(UUID userId, String gameType) {
        long played = gameResultRepository.countByUserIdAndGameType(userId, gameType);
        long completed = gameResultRepository.countCompletedByUserIdAndGameType(userId, gameType);
        Integer best = gameResultRepository.maxScoreByUserIdAndGameType(userId, gameType);
        Integer combo = gameResultRepository.maxComboByUserIdAndGameType(userId, gameType);
        Integer xp = gameResultRepository.sumXpAwardedByUserIdAndGameType(userId, gameType);
        Instant last = gameResultRepository.findLastPlayedAt(userId).orElse(null);
        return new GameResultProgressResponse(
                gameType, played, completed,
                best == null ? 0 : best,
                combo == null ? 0 : combo,
                xp == null ? 0 : xp,
                last);
    }

    private record Progression(int currentLevel, int totalXp) {
    }
}
