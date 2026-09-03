package com.gamelearn.gamification;

import java.util.Arrays;
import java.util.Collections;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Server-authoritative whitelist for PROG-101 gameType (Gate 4 P1-5).
 * Matches the 14 official GameType ids from frontend/lib/features/game_engine/models/game_models.dart.
 * Backend owns validation; frontend enum is not trusted.
 */
public enum GameType {
    QUIZ_BATTLE("quiz_battle"),
    MEMORY_MATCH("memory_match"),
    DRAG_DROP("drag_drop"),
    SPEED_RUN("speed_run"),
    DEBUG_ARENA("debug_arena"),
    UNLOCK_CODE("unlock_code"),
    CONCEPT_BUILDER("concept_builder"),
    SEQUENCE_MASTER("sequence_master"),
    TARGET_CHALLENGE("target_challenge"),
    MYSTERY_CASE("mystery_case"),
    BOSS_BATTLE("boss_battle"),
    PUZZLE_ARENA("puzzle_arena"),
    CONNECTIVITY_LAB("connectivity_lab"),
    SNAKE_AND_LADDER("snake_and_ladder");

    private final String id;

    GameType(String id) {
        this.id = id;
    }

    public String id() {
        return id;
    }

    private static final Set<String> IDS = Collections.unmodifiableSet(
            Arrays.stream(values()).map(GameType::id).collect(Collectors.toSet()));

    public static boolean isValid(String value) {
        return value != null && IDS.contains(value);
    }

    public static Set<String> allIds() {
        return IDS;
    }
}
