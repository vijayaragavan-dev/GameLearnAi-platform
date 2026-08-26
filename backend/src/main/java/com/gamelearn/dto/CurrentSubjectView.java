package com.gamelearn.dto;

import java.util.UUID;

/**
 * Dashboard section 2 (Dashboard Specification section 8.2): the
 * "continue where you left off" card. Non-null only when the profile's
 * current subject pointer resolves to an ACTIVE subject; null otherwise.
 */
public record CurrentSubjectView(
        UUID id,
        String name,
        String iconKey,
        CurrentTopicView currentTopic) {
}
