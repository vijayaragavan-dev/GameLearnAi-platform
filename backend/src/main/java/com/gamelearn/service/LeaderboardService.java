package com.gamelearn.service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.LeaderboardEntry;
import com.gamelearn.dto.LeaderboardPositionResponse;
import com.gamelearn.dto.LeaderboardResponse;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;

@Service
public class LeaderboardService {

    private final JdbcTemplate jdbcTemplate;

    public LeaderboardService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static class Row {
        String userId;
        String displayName;
        Instant createdAt;
        int totalXp;
        int level;
        Double mastery;
        String assetKey;
        String rarity;
        Integer streakDays;
        int rank;
    }

    private static class SubjectRow {
        String userId;
        String displayName;
        Instant createdAt;
        int subjectXp;
        int level;
        Double mastery;
        String assetKey;
        String rarity;
        Integer streakDays;
        int rank;
    }

    // Overall leaderboard
    @Transactional(readOnly = true)
    public LeaderboardResponse overall(UUID currentUserId, int page, int size, boolean includeTop, String season) {
        validateSeason(season);
        int totalPlayers = countOverallPlayers();
        int totalPages = totalPlayers == 0 ? 0 : (int) Math.ceil(totalPlayers / (double) size);
        int offset = (page - 1) * size;

        List<LeaderboardEntry> entries = fetchOverallPage(offset, size);
        // assign ranks for entries based on offset
        for (int i = 0; i < entries.size(); i++) {
            // rank already computed in query via row number
        }
        List<LeaderboardEntry> top = includeTop ? fetchOverallTop(10) : List.of();
        LeaderboardEntry me = fetchOverallMe(currentUserId);
        List<LeaderboardEntry> nearby = fetchOverallNearby(currentUserId, me);

        return new LeaderboardResponse(
                "OVERALL", "LIFETIME", null, null,
                page, size, totalPlayers, totalPages,
                top, entries, me, nearby, Instant.now(), 60);
    }

    @Transactional(readOnly = true)
    public LeaderboardResponse subject(UUID currentUserId, UUID subjectId, int page, int size, boolean includeTop, String season) {
        validateSeason(season);
        validateSubject(subjectId);
        String subjectName = fetchSubjectName(subjectId);
        int totalPlayers = countSubjectPlayers(subjectId);
        int totalPages = totalPlayers == 0 ? 0 : (int) Math.ceil(totalPlayers / (double) size);
        int offset = (page - 1) * size;

        List<LeaderboardEntry> entries = fetchSubjectPage(subjectId, offset, size);
        List<LeaderboardEntry> top = includeTop ? fetchSubjectTop(subjectId, 10) : List.of();
        LeaderboardEntry me = fetchSubjectMe(currentUserId, subjectId);
        List<LeaderboardEntry> nearby = fetchSubjectNearby(currentUserId, subjectId, me);

        return new LeaderboardResponse(
                "SUBJECT", "LIFETIME", subjectId.toString(), subjectName,
                page, size, totalPlayers, totalPages,
                top, entries, me, nearby, Instant.now(), 60);
    }

    @Transactional(readOnly = true)
    public LeaderboardPositionResponse position(UUID currentUserId, String segment, UUID subjectId) {
        if ("SUBJECT".equalsIgnoreCase(segment)) {
            if (subjectId == null) throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(), ErrorCode.VALIDATION_FAILED.name(), "subjectId required for SUBJECT segment");
            validateSubject(subjectId);
            LeaderboardEntry me = fetchSubjectMe(currentUserId, subjectId);
            List<LeaderboardEntry> top = fetchSubjectTop(subjectId, 3);
            int totalPlayers = countSubjectPlayers(subjectId);
            return new LeaderboardPositionResponse(
                    "SUBJECT", subjectId.toString(), me.rank(), 0, me.subjectXp(), me.level(), me.rank() == 1 ? null : computeXpToNextSubject(currentUserId, subjectId, me), me.rank() == 1 ? null : me.rank() - 1, null, totalPlayers, me.avatar(), top);
        } else {
            LeaderboardEntry me = fetchOverallMe(currentUserId);
            List<LeaderboardEntry> top = fetchOverallTop(3);
            int totalPlayers = countOverallPlayers();
            return new LeaderboardPositionResponse(
                    "OVERALL", null, me.rank(), me.totalXp(), null, me.level(), me.rank() == 1 ? null : computeXpToNextOverall(currentUserId, me), me.rank() == 1 ? null : me.rank() - 1, null, totalPlayers, me.avatar(), top);
        }
    }

    // --- overall helpers ---

    private int countOverallPlayers() {
        Integer c = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM learner_profiles lp JOIN users u ON u.id = lp.user_id WHERE u.status='ACTIVE'",
                Integer.class);
        return c == null ? 0 : c;
    }

    private List<LeaderboardEntry> fetchOverallPage(int offset, int size) {
        String sql = """
                SELECT u.id as user_id, u.display_name, u.created_at, lp.total_xp, lp.current_level, lp.overall_mastery,
                       a.asset_key, a.rarity, s.current_streak_days
                FROM learner_profiles lp
                JOIN users u ON u.id = lp.user_id
                LEFT JOIN streaks s ON s.user_id = u.id
                LEFT JOIN avatars a ON a.id = lp.equipped_avatar_id
                WHERE u.status='ACTIVE'
                ORDER BY lp.total_xp DESC, u.created_at ASC, u.id ASC
                LIMIT ? OFFSET ?
                """;
        return jdbcTemplate.query(sql, (rs, idx) -> {
            LeaderboardEntry e = new LeaderboardEntry(
                    offset + idx + 1,
                    rs.getString("display_name"),
                    new LeaderboardEntry.AvatarInfo(
                            rs.getString("asset_key") != null ? rs.getString("asset_key") : "characters/nova_spark",
                            rs.getString("rarity") != null ? rs.getString("rarity") : "INITIATE"),
                    rs.getInt("current_level"),
                    rs.getInt("total_xp"),
                    null,
                    rs.getObject("current_streak_days") == null ? null : rs.getInt("current_streak_days"),
                    rs.getObject("overall_mastery") == null ? null : rs.getDouble("overall_mastery"),
                    false, null);
            return e;
        }, size, offset);
    }

    private List<LeaderboardEntry> fetchOverallTop(int n) {
        return fetchOverallPage(0, n);
    }

    private LeaderboardEntry fetchOverallMe(UUID currentUserId) {
        // fetch current user's data
        String sql = """
                SELECT u.id as user_id, u.display_name, u.created_at, lp.total_xp, lp.current_level, lp.overall_mastery,
                       a.asset_key, a.rarity, s.current_streak_days
                FROM learner_profiles lp
                JOIN users u ON u.id = lp.user_id
                LEFT JOIN streaks s ON s.user_id = u.id
                LEFT JOIN avatars a ON a.id = lp.equipped_avatar_id
                WHERE u.id = ?
                """;
        List<LeaderboardEntry> list = jdbcTemplate.query(sql, (rs, idx) -> {
            int xp = rs.getInt("total_xp");
            Instant created = rs.getTimestamp("created_at").toInstant();
            String uid = rs.getString("user_id");
            int rank = computeOverallRank(xp, created, uid);
            return new LeaderboardEntry(
                    rank,
                    rs.getString("display_name"),
                    new LeaderboardEntry.AvatarInfo(
                            rs.getString("asset_key") != null ? rs.getString("asset_key") : "characters/nova_spark",
                            rs.getString("rarity") != null ? rs.getString("rarity") : "INITIATE"),
                    rs.getInt("current_level"),
                    xp,
                    null,
                    rs.getObject("current_streak_days") == null ? null : rs.getInt("current_streak_days"),
                    rs.getObject("overall_mastery") == null ? null : rs.getDouble("overall_mastery"),
                    true, null);
        }, currentUserId.toString());
        if (list.isEmpty()) {
            // user not in learner_profiles? fallback
            String usql = "SELECT id, display_name, created_at FROM users WHERE id=?";
            return jdbcTemplate.query(usql, (rs, idx) -> {
                Instant created = rs.getTimestamp("created_at").toInstant();
                String uid = rs.getString("id");
                int rank = computeOverallRank(0, created, uid);
                return new LeaderboardEntry(rank, rs.getString("display_name"),
                        new LeaderboardEntry.AvatarInfo("characters/nova_spark", "INITIATE"),
                        1, 0, null, null, null, true, null);
            }, currentUserId.toString()).get(0);
        }
        return list.get(0);
    }

    private int computeOverallRank(int myXp, Instant myCreated, String myId) {
        Integer cnt = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM learner_profiles lp JOIN users u ON u.id = lp.user_id WHERE u.status='ACTIVE' AND (lp.total_xp > ? OR (lp.total_xp = ? AND u.created_at < ?) OR (lp.total_xp = ? AND u.created_at = ? AND u.id < ?))",
                Integer.class, myXp, myXp, java.sql.Timestamp.from(myCreated), myXp, java.sql.Timestamp.from(myCreated), myId);
        return (cnt == null ? 0 : cnt) + 1;
    }

    private Integer computeXpToNextOverall(UUID userId, LeaderboardEntry me) {
        if (me.rank() <= 1) return null;
        String sql = """
                SELECT lp.total_xp FROM learner_profiles lp JOIN users u ON u.id = lp.user_id
                WHERE u.status='ACTIVE' ORDER BY lp.total_xp DESC, u.created_at ASC, u.id ASC LIMIT 1 OFFSET ?
                """;
        int offset = me.rank() - 2;
        List<Integer> list = jdbcTemplate.query(sql, (rs, idx) -> rs.getInt("total_xp"), offset);
        if (list.isEmpty()) return null;
        int aboveXp = list.get(0);
        return aboveXp - me.totalXp() + 1;
    }

    private List<LeaderboardEntry> fetchOverallNearby(UUID currentUserId, LeaderboardEntry me) {
        int rank = me.rank();
        int startRank = Math.max(1, rank - 2);
        int offset = startRank - 1;
        String sql = """
                SELECT u.id as user_id, u.display_name, u.created_at, lp.total_xp, lp.current_level, lp.overall_mastery,
                       a.asset_key, a.rarity, s.current_streak_days
                FROM learner_profiles lp
                JOIN users u ON u.id = lp.user_id
                LEFT JOIN streaks s ON s.user_id = u.id
                LEFT JOIN avatars a ON a.id = lp.equipped_avatar_id
                WHERE u.status='ACTIVE'
                ORDER BY lp.total_xp DESC, u.created_at ASC, u.id ASC
                LIMIT 5 OFFSET ?
                """;
        List<LeaderboardEntry> window = jdbcTemplate.query(sql, (rs, idx) -> {
            int r = offset + idx + 1;
            boolean isMe = rs.getString("user_id").equals(currentUserId.toString());
            return new LeaderboardEntry(
                    r,
                    rs.getString("display_name"),
                    new LeaderboardEntry.AvatarInfo(
                            rs.getString("asset_key") != null ? rs.getString("asset_key") : "characters/nova_spark",
                            rs.getString("rarity") != null ? rs.getString("rarity") : "INITIATE"),
                    rs.getInt("current_level"),
                    rs.getInt("total_xp"),
                    null,
                    rs.getObject("current_streak_days") == null ? null : rs.getInt("current_streak_days"),
                    rs.getObject("overall_mastery") == null ? null : rs.getDouble("overall_mastery"),
                    isMe, null);
        }, offset);
        return window;
    }

    // --- subject helpers ---

    private void validateSubject(UUID subjectId) {
        Integer c = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM subjects WHERE id=? AND is_active=TRUE", Integer.class, subjectId.toString());
        if (c == null || c == 0) throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(), ErrorCode.RESOURCE_NOT_FOUND.name(), "Subject not found");
    }

    private String fetchSubjectName(UUID subjectId) {
        String n = jdbcTemplate.queryForObject("SELECT name FROM subjects WHERE id=?", String.class, subjectId.toString());
        return n == null ? "" : n;
    }

    private int countSubjectPlayers(UUID subjectId) {
        String sql = """
                SELECT COUNT(DISTINCT lp.user_id) FROM learner_profiles lp
                JOIN users u ON u.id = lp.user_id
                JOIN xp_transactions xp ON xp.user_id = lp.user_id AND xp.reference_type='QUIZ_ATTEMPT'
                JOIN quiz_attempts qa ON qa.id = xp.reference_id
                JOIN quizzes q ON q.id = qa.quiz_id
                JOIN topics t ON t.id = q.topic_id
                WHERE u.status='ACTIVE' AND t.subject_id = ? AND t.is_active=TRUE
                """;
        Integer c = jdbcTemplate.queryForObject(sql, Integer.class, subjectId.toString());
        return c == null ? 0 : c;
    }

    private List<LeaderboardEntry> fetchSubjectPage(UUID subjectId, int offset, int size) {
        String sql = """
                SELECT u.id as user_id, u.display_name, u.created_at, lp.current_level, lp.overall_mastery,
                       a.asset_key, a.rarity, s.current_streak_days,
                       COALESCE(SUM(xp.amount),0) as subject_xp
                FROM learner_profiles lp
                JOIN users u ON u.id = lp.user_id
                LEFT JOIN streaks s ON s.user_id = u.id
                LEFT JOIN avatars a ON a.id = lp.equipped_avatar_id
                JOIN xp_transactions xp ON xp.user_id = lp.user_id AND xp.reference_type='QUIZ_ATTEMPT'
                JOIN quiz_attempts qa ON qa.id = xp.reference_id
                JOIN quizzes q ON q.id = qa.quiz_id
                JOIN topics t ON t.id = q.topic_id AND t.subject_id = ? AND t.is_active=TRUE
                WHERE u.status='ACTIVE'
                GROUP BY u.id, u.display_name, u.created_at, lp.current_level, lp.overall_mastery, a.asset_key, a.rarity, s.current_streak_days
                HAVING COALESCE(SUM(xp.amount),0) > 0
                ORDER BY subject_xp DESC, u.created_at ASC, u.id ASC
                LIMIT ? OFFSET ?
                """;
        return jdbcTemplate.query(sql, (rs, idx) -> {
            int r = offset + idx + 1;
            return new LeaderboardEntry(
                    r,
                    rs.getString("display_name"),
                    new LeaderboardEntry.AvatarInfo(
                            rs.getString("asset_key") != null ? rs.getString("asset_key") : "characters/nova_spark",
                            rs.getString("rarity") != null ? rs.getString("rarity") : "INITIATE"),
                    rs.getInt("current_level"),
                    0,
                    rs.getInt("subject_xp"),
                    rs.getObject("current_streak_days") == null ? null : rs.getInt("current_streak_days"),
                    rs.getObject("overall_mastery") == null ? null : rs.getDouble("overall_mastery"),
                    false, null);
        }, subjectId.toString(), size, offset);
    }

    private List<LeaderboardEntry> fetchSubjectTop(UUID subjectId, int n) {
        return fetchSubjectPage(subjectId, 0, n);
    }

    private LeaderboardEntry fetchSubjectMe(UUID currentUserId, UUID subjectId) {
        // compute this user's subject xp
        String sqlXp = """
                SELECT COALESCE(SUM(xp.amount),0) as subject_xp
                FROM xp_transactions xp
                JOIN quiz_attempts qa ON qa.id = xp.reference_id AND xp.reference_type='QUIZ_ATTEMPT'
                JOIN quizzes q ON q.id = qa.quiz_id
                JOIN topics t ON t.id = q.topic_id AND t.subject_id = ? AND t.is_active=TRUE
                WHERE xp.user_id = ?
                """;
        Integer subjectXp = jdbcTemplate.queryForObject(sqlXp, Integer.class, subjectId.toString(), currentUserId.toString());
        int sxp = subjectXp == null ? 0 : subjectXp;

        // fetch user profile data
        String sqlUser = """
                SELECT u.display_name, u.created_at, lp.current_level, lp.overall_mastery, a.asset_key, a.rarity, s.current_streak_days
                FROM users u
                JOIN learner_profiles lp ON lp.user_id = u.id
                LEFT JOIN streaks s ON s.user_id = u.id
                LEFT JOIN avatars a ON a.id = lp.equipped_avatar_id
                WHERE u.id = ?
                """;
        var list = jdbcTemplate.query(sqlUser, (rs, idx) -> {
            Instant created = jdbcTemplate.queryForObject("SELECT created_at FROM users WHERE id=?", java.sql.Timestamp.class, currentUserId.toString()).toInstant();
            int rank = computeSubjectRank(subjectId, sxp, created, currentUserId.toString());
            return new LeaderboardEntry(
                    rank,
                    rs.getString("display_name"),
                    new LeaderboardEntry.AvatarInfo(
                            rs.getString("asset_key") != null ? rs.getString("asset_key") : "characters/nova_spark",
                            rs.getString("rarity") != null ? rs.getString("rarity") : "INITIATE"),
                    rs.getInt("current_level"),
                    0,
                    sxp,
                    rs.getObject("current_streak_days") == null ? null : rs.getInt("current_streak_days"),
                    rs.getObject("overall_mastery") == null ? null : rs.getDouble("overall_mastery"),
                    true, null);
        }, currentUserId.toString());
        if (list.isEmpty()) {
            Instant created = jdbcTemplate.queryForObject("SELECT created_at FROM users WHERE id=?", java.sql.Timestamp.class, currentUserId.toString()).toInstant();
            int rank = computeSubjectRank(subjectId, sxp, created, currentUserId.toString());
            String name = jdbcTemplate.queryForObject("SELECT display_name FROM users WHERE id=?", String.class, currentUserId.toString());
            return new LeaderboardEntry(rank, name, new LeaderboardEntry.AvatarInfo("characters/nova_spark", "INITIATE"), 1, 0, sxp, null, null, true, null);
        }
        return list.get(0);
    }

    private int computeSubjectRank(UUID subjectId, int mySxp, Instant myCreated, String myId) {
        if (mySxp <= 0) {
            // users with 0 are not counted in subject leaderboard; rank = totalPlayers+1
            int total = countSubjectPlayers(subjectId);
            return total + 1;
        }
        String sql = """
                SELECT COUNT(*) FROM (
                    SELECT u.id, u.created_at, COALESCE(SUM(xp.amount),0) as sxp
                    FROM learner_profiles lp
                    JOIN users u ON u.id = lp.user_id
                    JOIN xp_transactions xp ON xp.user_id = lp.user_id AND xp.reference_type='QUIZ_ATTEMPT'
                    JOIN quiz_attempts qa ON qa.id = xp.reference_id
                    JOIN quizzes q ON q.id = qa.quiz_id
                    JOIN topics t ON t.id = q.topic_id AND t.subject_id = ? AND t.is_active=TRUE
                    WHERE u.status='ACTIVE'
                    GROUP BY u.id, u.created_at
                    HAVING COALESCE(SUM(xp.amount),0) > 0
                ) ranked
                WHERE (sxp > ?) OR (sxp = ? AND created_at < ?) OR (sxp = ? AND created_at = ? AND id < ?)
                """;
        Integer cnt = jdbcTemplate.queryForObject(sql, Integer.class,
                subjectId.toString(), mySxp, mySxp, java.sql.Timestamp.from(myCreated), mySxp, java.sql.Timestamp.from(myCreated), myId);
        return (cnt == null ? 0 : cnt) + 1;
    }

    private List<LeaderboardEntry> fetchSubjectNearby(UUID currentUserId, UUID subjectId, LeaderboardEntry me) {
        int rank = me.rank();
        if (me.subjectXp() != null && me.subjectXp() == 0) {
            // no nearby for zero xp users (they are outside leaderboard)
            return List.of();
        }
        int startRank = Math.max(1, rank - 2);
        int offset = startRank - 1;
        String sql = """
                SELECT u.id as user_id, u.display_name, u.created_at, lp.current_level, lp.overall_mastery,
                       a.asset_key, a.rarity, s.current_streak_days,
                       COALESCE(SUM(xp.amount),0) as subject_xp
                FROM learner_profiles lp
                JOIN users u ON u.id = lp.user_id
                LEFT JOIN streaks s ON s.user_id = u.id
                LEFT JOIN avatars a ON a.id = lp.equipped_avatar_id
                JOIN xp_transactions xp ON xp.user_id = lp.user_id AND xp.reference_type='QUIZ_ATTEMPT'
                JOIN quiz_attempts qa ON qa.id = xp.reference_id
                JOIN quizzes q ON q.id = qa.quiz_id
                JOIN topics t ON t.id = q.topic_id AND t.subject_id = ? AND t.is_active=TRUE
                WHERE u.status='ACTIVE'
                GROUP BY u.id, u.display_name, u.created_at, lp.current_level, lp.overall_mastery, a.asset_key, a.rarity, s.current_streak_days
                HAVING COALESCE(SUM(xp.amount),0) > 0
                ORDER BY subject_xp DESC, u.created_at ASC, u.id ASC
                LIMIT 5 OFFSET ?
                """;
        return jdbcTemplate.query(sql, (rs, idx) -> {
            int r = offset + idx + 1;
            boolean isMe = rs.getString("user_id").equals(currentUserId.toString());
            return new LeaderboardEntry(
                    r,
                    rs.getString("display_name"),
                    new LeaderboardEntry.AvatarInfo(
                            rs.getString("asset_key") != null ? rs.getString("asset_key") : "characters/nova_spark",
                            rs.getString("rarity") != null ? rs.getString("rarity") : "INITIATE"),
                    rs.getInt("current_level"),
                    0,
                    rs.getInt("subject_xp"),
                    rs.getObject("current_streak_days") == null ? null : rs.getInt("current_streak_days"),
                    rs.getObject("overall_mastery") == null ? null : rs.getDouble("overall_mastery"),
                    isMe, null);
        }, subjectId.toString(), offset);
    }

    private Integer computeXpToNextSubject(UUID userId, UUID subjectId, LeaderboardEntry me) {
        if (me.rank() <= 1 || me.subjectXp() == null) return null;
        String sql = """
                SELECT COALESCE(SUM(xp.amount),0) as sxp
                FROM learner_profiles lp
                JOIN users u ON u.id = lp.user_id
                JOIN xp_transactions xp ON xp.user_id = lp.user_id AND xp.reference_type='QUIZ_ATTEMPT'
                JOIN quiz_attempts qa ON qa.id = xp.reference_id
                JOIN quizzes q ON q.id = qa.quiz_id
                JOIN topics t ON t.id = q.topic_id AND t.subject_id = ? AND t.is_active=TRUE
                WHERE u.status='ACTIVE'
                GROUP BY u.id, u.created_at, u.id
                HAVING COALESCE(SUM(xp.amount),0) > 0
                ORDER BY sxp DESC, u.created_at ASC, u.id ASC
                LIMIT 1 OFFSET ?
                """;
        int offset = me.rank() - 2;
        List<Integer> list = jdbcTemplate.query(sql, (rs, idx) -> rs.getInt("sxp"), subjectId.toString(), offset);
        if (list.isEmpty()) return null;
        return list.get(0) - me.subjectXp() + 1;
    }

    private void validateSeason(String season) {
        if (season == null || season.isBlank() || "LIFETIME".equalsIgnoreCase(season)) return;
        throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(), ErrorCode.VALIDATION_FAILED.name(), "Unsupported season: " + season);
    }
}
