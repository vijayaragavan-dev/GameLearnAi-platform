package com.gamelearn.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.gamelearn.ai.documents.PdfExtractionClient;
import com.gamelearn.ai.documents.PdfExtractionException;
import com.gamelearn.config.AiProperties;
import com.gamelearn.dto.DocumentUploadResponse;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.entity.enums.DocumentStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.logging.RequestCorrelationFilter;

/**
 * USER-DOC RAG Phase C: secure PDF upload → extract → screen pipeline.
 *
 * <p>Flow (single bounded synchronous request, no queue framework):
 * cheap validation → rate limit → SHA-256 → metadata row
 * ({@code UPLOADED}) → filesystem store → {@code EXTRACTING} →
 * localhost sidecar extraction → authoritative limit re-check →
 * {@code pages.json} → {@code CHUNKED}.</p>
 *
 * <p>Security posture: ownership is the server-authenticated id only
 * (no owner parameter exists); the client filename is metadata only
 * (storage paths derive from the server UUID); PDF bytes are validated
 * by magic signature, never by extension/MIME claims; extracted text is
 * never logged, never returned, never sent to Gemini; failures land on
 * {@code FAILED} with stored bytes removed. {@code INDEXED} is never
 * produced here — no vector index exists in this phase.</p>
 *
 * <p>Atomicity is compensating, not transactional: filesystem + database
 * cannot share a transaction, so every post-row failure explicitly
 * marks {@code FAILED} and deletes stored bytes.</p>
 */
@Service
public class DocumentUploadService {

    private static final Logger log = LoggerFactory.getLogger(DocumentUploadService.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private static final byte[] PDF_MAGIC = "%PDF-".getBytes(StandardCharsets.US_ASCII);
    private static final Set<String> ACCEPTED_DECLARED_TYPES =
            Set.of("application/pdf", "application/octet-stream");
    private static final int FILENAME_MAX_CHARS = 255;
    private static final Pattern CONTROL_CHARS = Pattern.compile("\\p{Cntrl}");

    private final UserDocumentService documentService;
    private final DocumentStorageService storageService;
    private final PdfExtractionClient extractionClient;
    private final DocumentUploadRateLimiter rateLimiter;
    private final AiProperties properties;

    public DocumentUploadService(UserDocumentService documentService,
                                 DocumentStorageService storageService,
                                 PdfExtractionClient extractionClient,
                                 DocumentUploadRateLimiter rateLimiter,
                                 AiProperties properties) {
        this.documentService = documentService;
        this.storageService = storageService;
        this.extractionClient = extractionClient;
        this.rateLimiter = rateLimiter;
        this.properties = properties;
    }

    /**
     * Accepts one user-owned PDF and drives it to {@code CHUNKED} (or
     * {@code FAILED} with cleanup). Ownership comes exclusively from the
     * authenticated id; content limits fail closed.
     */
    public DocumentUploadResponse upload(UUID authenticatedUserId, MultipartFile file) {
        long startedAt = System.currentTimeMillis();
        // Cheap validation first: nothing expensive runs for bad input.
        if (file == null || file.isEmpty()) {
            throw validationFailure("file", "a PDF file is required");
        }
        String filename = sanitizeFilename(file.getOriginalFilename());
        checkDeclaredType(file.getContentType());
        long maxBytes = properties.getDocuments().getMaxBytes();
        if (file.getSize() > maxBytes) {
            throw tooLarge("file", "file exceeds the maximum allowed size");
        }
        byte[] pdfBytes;
        try {
            pdfBytes = file.getBytes();
        } catch (Exception ex) {
            throw internal("could not read uploaded file", ex);
        }
        if (pdfBytes.length == 0) {
            throw validationFailure("file", "a PDF file is required");
        }
        if (pdfBytes.length > maxBytes) {
            throw tooLarge("file", "file exceeds the maximum allowed size");
        }
        if (!hasPdfMagic(pdfBytes)) {
            throw validationFailure("file", "unsupported file type: PDF content required");
        }
        if (!rateLimiter.tryAcquire(authenticatedUserId)) {
            throw new ApiException(ErrorCode.DOCUMENT_RATE_LIMITED.getHttpStatus(),
                    ErrorCode.DOCUMENT_RATE_LIMITED.name(),
                    "Document upload limit reached. Try again later.");
        }

        String sha256 = sha256Hex(pdfBytes);
        // Declared type is NOT stored: the validated PDF signature is
        // authoritative, so the canonical content type is recorded.
        UserDocument document = documentService.register(
                authenticatedUserId, filename, "application/pdf", pdfBytes.length, sha256);
        UUID documentId = document.getId();

        try {
            try {
                storageService.store(documentId, pdfBytes);
            } catch (ApiException storeFailure) {
                throw failed(authenticatedUserId, document, storeFailure);
            }
            documentService.transitionStatus(authenticatedUserId, documentId,
                    DocumentStatus.EXTRACTING);

            // The sidecar receives the exact bytes just stored (bounded by
            // maxBytes); disk remains the source of truth for later phases.
            PdfExtractionClient.Extraction extraction;
            try {
                extraction = extractionClient.extract(
                        RequestCorrelationFilter.currentRequestId(), pdfBytes);
            } catch (PdfExtractionException ex) {
                throw failed(authenticatedUserId, document, mapExtractionFault(ex));
            }
            if (!extraction.ok()) {
                throw failed(authenticatedUserId, document, mapRefusal(extraction.reason()));
            }
            enforceLimits(authenticatedUserId, extraction, document);

            documentService.setPageCount(authenticatedUserId, documentId,
                    extraction.pageCount());
            try {
                storageService.writePages(documentId, pagesJson(documentId, extraction));
            } catch (ApiException storeFailure) {
                throw failed(authenticatedUserId, document, storeFailure);
            }
            // Phase D: page-local chunking over the extracted pages. The
            // sidecar returns provenance records; Spring validates identity
            // echo + page membership and persists chunks.json beside
            // pages.json. Still CHUNKED — INDEXED needs future vectors.
            PdfExtractionClient.ChunkResult chunked;
            try {
                chunked = extractionClient.chunk(
                        RequestCorrelationFilter.currentRequestId(), documentId,
                        document.getDocVersion(), authenticatedUserId,
                        extraction.pages());
            } catch (PdfExtractionException ex) {
                throw failed(authenticatedUserId, document, mapExtractionFault(ex));
            }
            if (!chunked.ok()) {
                throw failed(authenticatedUserId, document,
                        mapChunkRefusal(chunked.reason()));
            }
            try {
                storageService.writeChunks(documentId, chunksJson(document, chunked));
            } catch (ApiException storeFailure) {
                throw failed(authenticatedUserId, document, storeFailure);
            }
            // Phase E: embed chunk texts with the pinned model. Vectors are
            // validated (384/finite/unit-norm) and the embedding
            // fingerprint is recomputed here; any mismatch fails closed.
            // Still CHUNKED — INDEXED needs future Qdrant writes.
            PdfExtractionClient.EmbedResult embedded;
            try {
                embedded = extractionClient.embed(
                        RequestCorrelationFilter.currentRequestId(), documentId,
                        document.getDocVersion(), authenticatedUserId,
                        toEmbeddableChunks(chunked));
            } catch (PdfExtractionException ex) {
                throw failed(authenticatedUserId, document, mapExtractionFault(ex));
            }
            if (!embedded.ok()) {
                throw failed(authenticatedUserId, document,
                        mapEmbedRefusal(embedded.reason()));
            }
            try {
                storageService.writeEmbeddings(documentId,
                        embeddingsJson(document, chunked, embedded));
            } catch (ApiException storeFailure) {
                throw failed(authenticatedUserId, document, storeFailure);
            }
            UserDocument done = documentService.transitionStatus(authenticatedUserId,
                    documentId, DocumentStatus.CHUNKED);
            log.info("DOC_UPLOAD_OK chunks={} embedded={} bytes={} pages={} latencyMs={}",
                    chunked.chunkCount(), embedded.chunkCount(), done.getByteSize(),
                    extraction.pageCount(),
                    System.currentTimeMillis() - startedAt);
            return new DocumentUploadResponse(done.getId(), done.getFilename(),
                    done.getContentType(), done.getByteSize(), extraction.pageCount(),
                    done.getStatus().name(), done.getDocVersion(), done.getCreatedAt(),
                    chunked.chunkCount());
        } catch (ApiException ex) {
            throw ex;
        } catch (RuntimeException ex) {
            throw failed(authenticatedUserId, document,
                    internal("document processing failed", ex));
        }
    }

    // ------------------------------------------------------------------
    // validation
    // ------------------------------------------------------------------

    static boolean hasPdfMagic(byte[] bytes) {
        if (bytes.length < PDF_MAGIC.length) {
            return false;
        }
        for (int i = 0; i < PDF_MAGIC.length; i++) {
            if (bytes[i] != PDF_MAGIC[i]) {
                return false;
            }
        }
        return true;
    }

    private static String sanitizeFilename(String raw) {
        String name = raw == null ? "" : raw.strip().replace('\\', '/');
        int slash = name.lastIndexOf('/');
        if (slash >= 0) {
            name = name.substring(slash + 1);
        }
        name = name.strip();
        if (name.isEmpty() || name.equals(".") || name.equals("..")) {
            throw validationFailure("file", "a PDF filename is required");
        }
        if (CONTROL_CHARS.matcher(name).find()) {
            throw validationFailure("file", "filename contains unsupported characters");
        }
        if (name.length() > FILENAME_MAX_CHARS) {
            throw validationFailure("file", "filename is too long");
        }
        if (!name.toLowerCase(Locale.ROOT).endsWith(".pdf")) {
            throw validationFailure("file", "unsupported file type: a .pdf file is required");
        }
        return name;
    }

    private static void checkDeclaredType(String declared) {
        if (declared == null || declared.isBlank()) {
            return; // absent claim: the magic signature decides
        }
        String base = declared.split(";", 2)[0].trim().toLowerCase(Locale.ROOT);
        if (!ACCEPTED_DECLARED_TYPES.contains(base)) {
            throw validationFailure("file",
                    "unsupported file type: declared as " + base);
        }
    }

    private static String sha256Hex(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception ex) {
            throw new IllegalStateException("SHA-256 unavailable", ex);
        }
    }

    // ------------------------------------------------------------------
    // extraction outcome handling
    // ------------------------------------------------------------------

    private void enforceLimits(UUID authenticatedUserId,
                               PdfExtractionClient.Extraction extraction,
                               UserDocument document) {
        int maxPages = properties.getDocuments().getMaxPages();
        int maxPerPage = properties.getDocuments().getMaxCharsPerPage();
        int maxTotal = properties.getDocuments().getMaxTotalChars();
        if (extraction.pageCount() > maxPages) {
            throw failed(authenticatedUserId, document, validationFailure("file",
                    "PDF exceeds the maximum page count of " + maxPages));
        }
        long total = 0;
        for (PdfExtractionClient.ExtractionPage page : extraction.pages()) {
            int chars = page.text() == null ? 0 : page.text().length();
            if (chars > maxPerPage) {
                throw failed(authenticatedUserId, document, validationFailure("file",
                        "PDF page exceeds the maximum text length"));
            }
            total += chars;
        }
        if (total > maxTotal) {
            throw failed(authenticatedUserId, document, validationFailure("file",
                    "PDF exceeds the maximum extractable text length"));
        }
    }

    private ApiException mapExtractionFault(PdfExtractionException ex) {
        return switch (ex.getCategory()) {
            case PdfExtractionException.TIMEOUT -> internal(
                    "document processing timed out", ex);
            case PdfExtractionException.TOO_LARGE -> tooLarge(
                    "file", "file exceeds the maximum allowed size");
            case PdfExtractionException.MISCONFIGURED -> internal(
                    "document processing is not configured", ex);
            default -> internal("document processing is temporarily unavailable", ex);
        };
    }

    private ApiException mapRefusal(String reason) {
        String code = reason == null ? "unknown" : reason;
        return switch (code) {
            case "encrypted" -> validationFailure("file",
                    "encrypted or password-protected PDFs are not supported");
            case "too_many_pages" -> validationFailure("file",
                    "PDF exceeds the maximum page count of "
                            + properties.getDocuments().getMaxPages());
            case "page_text_limit_exceeded", "total_text_limit_exceeded" -> validationFailure(
                    "file", "PDF exceeds the maximum extractable text length");
            case "unsafe_content", "secret_found", "suspicious_content" -> validationFailure(
                    "file", "document failed security screening: " + code);
            case "no_extractable_text" -> validationFailure("file",
                    "no extractable text found: scanned images need OCR, which is not supported");
            default -> validationFailure("file",
                    "the PDF could not be processed: " + code);
        };
    }

    private java.util.List<PdfExtractionClient.DocChunk> toEmbeddableChunks(
            PdfExtractionClient.ChunkResult chunked) {
        // Only bare texts travel: owner/document metadata rides in the
        // request envelope for bookkeeping, never inside embedding input.
        return chunked.chunks();
    }

    private ApiException mapEmbedRefusal(String reason) {
        String code = reason == null ? "unknown" : reason;
        return switch (code) {
            case "empty_text", "invalid_vector" -> validationFailure("file",
                    "the PDF chunks could not be embedded: " + code);
            default -> validationFailure("file",
                    "the PDF could not be embedded: " + code);
        };
    }

    private String embeddingsJson(UserDocument document,
                                  PdfExtractionClient.ChunkResult chunked,
                                  PdfExtractionClient.EmbedResult embedded) {
        ObjectNode root = MAPPER.createObjectNode();
        root.put("document_id", document.getId().toString());
        root.put("doc_version", document.getDocVersion());
        root.put("chunk_config_version", chunked.configVersion());
        root.put("model_id", embedded.modelId());
        root.put("model_revision", embedded.modelRevision());
        root.put("model_license", embedded.modelLicense());
        root.put("embedding_dimension", embedded.dimension());
        root.put("normalize_embeddings", embedded.normalized());
        root.put("similarity_metric", embedded.similarity());
        root.put("embedder_version", embedded.embedderVersion());
        root.put("chunk_count", embedded.chunkCount());
        ArrayNode ids = root.putArray("chunk_ids");
        for (String chunkId : embedded.chunkIds()) {
            ids.add(chunkId);
        }
        root.put("embedding_fingerprint", embedded.embeddingFingerprint());
        ArrayNode vectors = root.putArray("embeddings");
        for (PdfExtractionClient.EmbeddedChunk chunk : embedded.chunks()) {
            ObjectNode node = vectors.addObject();
            node.put("chunk_id", chunk.chunkId());
            ArrayNode values = node.putArray("vector");
            for (double value : chunk.vector()) {
                values.add(value);
            }
        }
        return root.toString();
    }

    private ApiException mapChunkRefusal(String reason) {
        String code = reason == null ? "unknown" : reason;
        return switch (code) {
            case "too_many_chunks" -> validationFailure("file",
                    "PDF exceeds the maximum chunk count");
            case "unsafe_chunk", "secret_found" -> validationFailure("file",
                    "document failed security screening: " + code);
            default -> validationFailure("file",
                    "the PDF could not be chunked: " + code);
        };
    }

    private String chunksJson(UserDocument document,
                              PdfExtractionClient.ChunkResult chunked) {
        ObjectNode root = MAPPER.createObjectNode();
        root.put("document_id", document.getId().toString());
        root.put("doc_version", document.getDocVersion());
        root.put("chunk_config_version", chunked.configVersion());
        root.put("chunk_count", chunked.chunkCount());
        ArrayNode chunks = root.putArray("chunks");
        for (PdfExtractionClient.DocChunk chunk : chunked.chunks()) {
            ObjectNode node = chunks.addObject();
            node.put("chunk_id", chunk.chunkId());
            node.put("document_id", document.getId().toString());
            node.put("doc_version", document.getDocVersion());
            node.put("page_no", chunk.pageNo());
            node.put("chunk_index", chunk.chunkIndex());
            node.put("citation", chunk.citation());
            node.put("text", chunk.text());
            node.put("chars", chunk.text().length());
            node.put("text_hash", chunk.textHash());
            if (chunk.ownerId() != null) {
                node.put("owner_id", chunk.ownerId());
            }
            node.put("chunk_config_version", chunked.configVersion());
        }
        return root.toString();
    }

    private String pagesJson(UUID documentId, PdfExtractionClient.Extraction extraction) {
        ObjectNode root = MAPPER.createObjectNode();
        root.put("document_id", documentId.toString());
        root.put("page_count", extraction.pageCount());
        ArrayNode pages = root.putArray("pages");
        for (PdfExtractionClient.ExtractionPage page : extraction.pages()) {
            ObjectNode node = pages.addObject();
            node.put("page_no", page.pageNo());
            node.put("chars", page.text() == null ? 0 : page.text().length());
            node.put("text", page.text() == null ? "" : page.text());
        }
        return root.toString();
    }

    /**
     * Compensating failure: mark {@code FAILED} through the owner-scoped
     * service boundary (a fresh persistence context — the in-flight
     * entity here is detached, so mutating it would never flush) and
     * remove stored bytes. Never throws itself; the caller's error is
     * what propagates.
     */
    private ApiException failed(UUID authenticatedUserId, UserDocument document,
                                ApiException error) {
        try {
            documentService.transitionStatus(authenticatedUserId, document.getId(),
                    DocumentStatus.FAILED);
        } catch (RuntimeException ignored) {
            // Status write is best-effort on the failure path.
        }
        try {
            storageService.deleteDocumentDir(document.getId());
        } catch (RuntimeException ignored) {
            // Cleanup is best-effort; the service never throws.
        }
        log.info("DOC_UPLOAD_FAILED reason={} bytes={}",
                error.getErrorCode(), document.getByteSize());
        return error;
    }

    private static ApiException validationFailure(String field, String message) {
        return new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                ErrorCode.VALIDATION_FAILED.name(), "Request validation failed",
                Map.of(field, message));
    }

    private static ApiException tooLarge(String field, String message) {
        return new ApiException(ErrorCode.PAYLOAD_TOO_LARGE.getHttpStatus(),
                ErrorCode.PAYLOAD_TOO_LARGE.name(), message,
                Map.of(field, message));
    }

    private ApiException internal(String message, Throwable cause) {
        // Causes stay in the server log only; the envelope never carries
        // stack traces, paths or parser internals.
        log.warn("Document processing fault: {}", cause.toString());
        return new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                ErrorCode.INTERNAL_ERROR.name(), message);
    }
}
