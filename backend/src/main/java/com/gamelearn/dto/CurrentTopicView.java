package com.gamelearn.dto;

import java.util.UUID;

/**
 * Dashboard section 2 inner block (Dashboard Specification section 8.2):
 * non-null only when the profile's current topic pointer resolves to an
 * ACTIVE topic of the current subject (Case 8 guard).
 */
public record CurrentTopicView(
        UUID topicId,
        String topicName,
        String difficulty) {
}
