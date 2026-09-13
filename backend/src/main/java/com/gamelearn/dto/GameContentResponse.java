package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

public record GameContentResponse(String mode, UUID subjectId, List<GameContentItem> items) {
}
