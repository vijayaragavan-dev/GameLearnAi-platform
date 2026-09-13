package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

/**
 * One authoritative game content item. Every item preserves subject
 * identity ({@code subjectId}); topic-bound items additionally carry
 * {@code topicId} and the nullable {@code unitId} consistent with
 * topic → unit → subject. QUESTION items expose options but never correct
 * answers or explanations; CONCEPT items expose an authoritative
 * definition resolved server-side from lesson/topic content.
 */
public record GameContentItem(String kind, UUID id, UUID subjectId, String subjectName, UUID topicId,
                              String topicName, UUID unitId, String gameType, String difficulty,
                              String questionText, List<String> options, String definition) {
}
