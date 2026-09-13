package com.gamelearn.gamification;

import java.util.Set;

/**
 * Backend content strategy per canonical game (Batch 2, Phase 4).
 *
 * <p>QUESTION games are served from active MCQ questions; CONCEPT games from
 * authoritative lesson/topic definitions (lesson summary first, then lesson
 * content, then topic description — the same priority the clients use, now
 * resolved server-side); STRUCTURE games from topic metadata. A game is
 * only playable for a subject when its strategy has backing rows, which is
 * exactly what content availability reports.
 */
public enum GameContentKind {
    QUESTION,
    CONCEPT,
    STRUCTURE;

    private static final Set<String> QUESTION_GAMES = Set.of(
            "quiz_battle", "speed_run", "boss_battle", "target_challenge",
            "snake_and_ladder", "unlock_code", "puzzle_arena", "mystery_case",
            "debug_arena");

    private static final Set<String> CONCEPT_GAMES = Set.of(
            "memory_match", "concept_builder");

    private static final Set<String> STRUCTURE_GAMES = Set.of(
            "drag_drop", "sequence_master", "connectivity_lab");

    public static GameContentKind forGameType(String gameType) {
        if (QUESTION_GAMES.contains(gameType)) {
            return QUESTION;
        }
        if (CONCEPT_GAMES.contains(gameType)) {
            return CONCEPT;
        }
        if (STRUCTURE_GAMES.contains(gameType)) {
            return STRUCTURE;
        }
        throw new IllegalArgumentException("Unknown game type: " + gameType);
    }
}
