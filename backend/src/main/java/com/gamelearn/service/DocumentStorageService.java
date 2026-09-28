package com.gamelearn.service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Comparator;
import java.util.UUID;
import java.util.stream.Stream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gamelearn.config.AiProperties;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;

/**
 * USER-DOC RAG Phase C: application-controlled PDF file storage.
 *
 * <p>Layout: {@code <storage-root>/<document-uuid>/source.pdf} plus
 * {@code pages.json} (page-aware extraction output). The physical path is
 * ALWAYS derived from the server-generated document UUID — the client
 * filename is metadata only and never becomes a path segment, so
 * traversal sequences ({@code ../}, absolute paths, drive letters,
 * URL-encoded sequences) cannot escape the root. Every resolution is
 * normalized and verified to stay under the root.</p>
 *
 * <p>Storage lives outside the webroot, frontend assets, sources and Git
 * (default {@code ~/.gamelearn/documents}, overridable via
 * {@code GAMELEARN_DOCUMENTS_STORAGE_ROOT}). No PDF bytes ever enter
 * MySQL. Cleanup ({@link #deleteDocumentDir}) is best-effort and never
 * throws: callers use it as compensating cleanup on failure paths.</p>
 */
@Service
public class DocumentStorageService {

    private static final Logger log = LoggerFactory.getLogger(DocumentStorageService.class);

    static final String SOURCE_FILENAME = "source.pdf";
    static final String PAGES_FILENAME = "pages.json";
    static final String CHUNKS_FILENAME = "chunks.json";
    static final String EMBEDDINGS_FILENAME = "embeddings.json";

    private final Path root;

    public DocumentStorageService(AiProperties properties) {
        String configured = properties.getDocuments().getStorageRoot();
        if (configured == null || configured.isBlank()) {
            throw new IllegalStateException(
                    "Document storage root is not configured (gamelearn.documents.storage-root)");
        }
        this.root = Paths.get(configured).toAbsolutePath().normalize();
    }

    /**
     * Persists raw PDF bytes for a server-generated document id.
     * Fails with {@code INTERNAL_ERROR} on any I/O fault (nothing
     * partial is left behind: the file is created atomically).
     */
    public void store(UUID documentId, byte[] pdfBytes) {
        Path dir = documentDir(documentId);
        try {
            Files.createDirectories(dir);
            Files.write(dir.resolve(SOURCE_FILENAME), pdfBytes,
                    StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
        } catch (IOException ex) {
            log.warn("Document store failed");
            throw new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Document storage failed");
        }
    }

    /** Persists the page-aware extraction output next to the source PDF. */
    public void writePages(UUID documentId, String pagesJson) {
        Path dir = documentDir(documentId);
        try {
            Files.writeString(dir.resolve(PAGES_FILENAME), pagesJson,
                    StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING,
                    StandardOpenOption.WRITE);
        } catch (IOException ex) {
            log.warn("Document pages write failed");
            throw new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Document storage failed");
        }
    }

    /**
     * Persists the deterministic chunking output next to the source PDF.
     * Atomic where the filesystem supports it: bytes go to a temp file in
     * the same directory and are moved into place, so readers never see a
     * half-written artifact.
     */
    public void writeChunks(UUID documentId, String chunksJson) {
        writeAtomic(documentDir(documentId), CHUNKS_FILENAME, chunksJson, "chunks");
    }

    /**
     * Persists the Phase E embedding artifact (vectors + binding manifest)
     * next to the chunks it was computed from. Intermediate only: Qdrant
     * becomes the searchable home in Phase F; MySQL never holds vectors.
     */
    public void writeEmbeddings(UUID documentId, String embeddingsJson) {
        writeAtomic(documentDir(documentId), EMBEDDINGS_FILENAME, embeddingsJson,
                "embeddings");
    }

    private void writeAtomic(Path dir, String filename, String content, String kind) {
        Path tmp;
        try {
            Files.createDirectories(dir);
            tmp = Files.createTempFile(dir, "artifact", ".json.tmp");
            Files.writeString(tmp, content, StandardCharsets.UTF_8,
                    StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE);
            try {
                Files.move(tmp, dir.resolve(filename),
                        java.nio.file.StandardCopyOption.ATOMIC_MOVE,
                        java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            } catch (java.nio.file.AtomicMoveNotSupportedException notAtomic) {
                Files.move(tmp, dir.resolve(filename),
                        java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException ex) {
            log.warn("Document {} write failed", kind);
            throw new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Document storage failed");
        }
    }

    /**
     * Best-effort removal of one document directory (compensating cleanup
     * after failed ingestion). Never throws; failures are logged with ids
     * only. Deletes nothing outside the storage root.
     */
    public void deleteDocumentDir(UUID documentId) {
        Path dir = documentDir(documentId);
        try {
            if (!Files.exists(dir)) {
                return;
            }
            try (Stream<Path> walk = Files.walk(dir)) {
                walk.sorted(Comparator.reverseOrder())
                        .forEach(path -> {
                            try {
                                Files.deleteIfExists(path);
                            } catch (IOException ex) {
                                log.warn("Document cleanup failed for {}", documentId);
                            }
                        });
            }
        } catch (IOException | RuntimeException ex) {
            log.warn("Document cleanup failed for {}", documentId);
        }
    }

    /** Whether any stored bytes exist for this document (tests/ops). */
    public boolean exists(UUID documentId) {
        return Files.isRegularFile(documentDir(documentId).resolve(SOURCE_FILENAME));
    }

    /**
     * Reads a controlled JSON artifact ({@code pages.json},
     * {@code chunks.json}, {@code embeddings.json}) for a
     * server-generated document id. Fails with {@code INTERNAL_ERROR} when
     * the artifact is missing or unreadable — callers treat that as a
     * failed precondition, never as empty content.
     */
    public String readArtifact(UUID documentId, String filename) {
        if (!SOURCE_FILENAME.equals(filename) && !PAGES_FILENAME.equals(filename)
                && !CHUNKS_FILENAME.equals(filename) && !EMBEDDINGS_FILENAME.equals(filename)) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Document storage failed");
        }
        try {
            return Files.readString(documentDir(documentId).resolve(filename),
                    StandardCharsets.UTF_8);
        } catch (IOException ex) {
            log.warn("Document artifact read failed");
            throw new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Document storage failed");
        }
    }

    private Path documentDir(UUID documentId) {
        // UUID strings cannot traverse, but the guard is unconditional:
        // every resolved path must stay under the storage root.
        Path resolved = root.resolve(documentId.toString()).normalize();
        if (!resolved.startsWith(root)) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Document storage failed");
        }
        return resolved;
    }
}
