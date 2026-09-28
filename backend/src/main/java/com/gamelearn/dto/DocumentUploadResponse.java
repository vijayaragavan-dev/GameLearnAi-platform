package com.gamelearn.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * USER-DOC RAG Phase C: safe upload response — metadata only. Never
 * carries filesystem paths, PDF bytes, extracted text, storage roots,
 * vector details or secrets.
 */
public record DocumentUploadResponse(
        UUID id,
        String filename,
        String contentType,
        long byteSize,
        Integer pageCount,
        String status,
        int docVersion,
        Instant createdAt,
        int chunkCount) {
}
