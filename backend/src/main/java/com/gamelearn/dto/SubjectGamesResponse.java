package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

public record SubjectGamesResponse(UUID subjectId, String subjectName, List<SubjectGameEntry> games) {
}
