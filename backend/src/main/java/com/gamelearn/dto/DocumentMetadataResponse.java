package com.gamelearn.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * USER-DOC library entry: owner-scoped document metadata for the
 * learner's document list. Metadata only — never filesystem paths,
 * PDF bytes, extracted text, or secrets. Served newest-first.
 */
public record DocumentMetadataResponse(
        UUID id,
        String filename,
        String contentType,
        long byteSize,
        Integer pageCount,
        String status,
        int docVersion,
        Instant createdAt) {
}
