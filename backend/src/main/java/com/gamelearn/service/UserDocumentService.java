package com.gamelearn.service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.User;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.entity.enums.DocumentStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.UserDocumentRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Security boundary for user-document metadata (USER-DOC RAG Phase B).
 *
 * <p>NON-NEGOTIABLE INVARIANT: the owner id is ALWAYS the
 * server-authenticated identity. Every method takes
 * {@code authenticatedUserId} — supplied by the caller from the
 * {@code SecurityContext} principal ({@code AuthenticatedUser.id()}),
 * exactly like {@code AiTutorService.ask}. There is NO owner parameter in
 * any signature, so a client can never create or reach another user's
 * document by supplying another user id.</p>
 *
 * <p>Cross-owner access (including soft-deleted rows) surfaces as
 * {@code RESOURCE_NOT_FOUND}, never {@code FORBIDDEN}, so callers learn
 * nothing about other users' documents. No public document API
 * (controller/DTO) is added in this phase.</p>
 */
@Service
public class UserDocumentService {

    /** SHA-256 hex length; enforced when a checksum is supplied. */
    static final int SHA256_HEX_LENGTH = 64;

    private final UserDocumentRepository documentRepository;
    private final UserRepository userRepository;

    public UserDocumentService(UserDocumentRepository documentRepository,
                               UserRepository userRepository) {
        this.documentRepository = documentRepository;
        this.userRepository = userRepository;
    }

    /**
     * Registers one metadata row owned by the authenticated user. Starts
     * in {@code UPLOADED}; extraction/indexing fields stay null until
     * later phases fill them.
     */
    @Transactional
    public UserDocument register(UUID authenticatedUserId, String filename,
                                 String contentType, long byteSize) {
        return register(authenticatedUserId, filename, contentType, byteSize, null);
    }

    /**
     * Phase C overload: registers with the server-computed SHA-256 of the
     * uploaded bytes. The checksum is never client-supplied — callers pass
     * the digest they computed over the bytes they received (or null when
     * no bytes exist yet).
     */
    @Transactional
    public UserDocument register(UUID authenticatedUserId, String filename,
                                 String contentType, long byteSize, String sha256Hex) {
        User owner = userOrThrow(authenticatedUserId);
        requireText(filename, "filename");
        requireText(contentType, "contentType");
        if (byteSize < 0) {
            throw validationFailure("byteSize", "byteSize must be >= 0");
        }
        if (sha256Hex != null
                && !java.util.regex.Pattern.matches("[0-9a-f]{64}", sha256Hex)) {
            throw validationFailure("sha256", "sha256 must be 64 lowercase hex characters");
        }
        UserDocument document = new UserDocument();
        document.setUser(owner);
        document.setFilename(filename.strip());
        document.setContentType(contentType.strip());
        document.setByteSize(byteSize);
        document.setSha256(sha256Hex);
        document.setStatus(DocumentStatus.UPLOADED);
        return documentRepository.save(document);
    }

    /**
     * Phase C: records the server-counted page total after extraction.
     * Owner-scoped like every other mutation; 404 for foreign/inactive
     * rows so later phases cannot attach counts to another user's row.
     */
    @Transactional
    public UserDocument setPageCount(UUID authenticatedUserId, UUID documentId,
                                     int pageCount) {
        if (pageCount < 0) {
            throw validationFailure("pageCount", "pageCount must be >= 0");
        }
        UserDocument document = documentRepository.findByIdAndUserId(documentId, authenticatedUserId)
                .orElseThrow(() -> notFound());
        if (!document.isActive()) {
            throw notFound();
        }
        document.setPageCount(pageCount);
        return documentRepository.save(document);
    }

    /** One owned, servable document; 404 when missing, foreign or inactive. */
    @Transactional(readOnly = true)
    public UserDocument getOwned(UUID authenticatedUserId, UUID documentId) {
        return documentRepository.findByIdAndUserIdAndActiveTrue(documentId, authenticatedUserId)
                .orElseThrow(() -> notFound());
    }

    /** Owned, servable documents of the authenticated user, newest first. */
    @Transactional(readOnly = true)
    public List<UserDocument> listOwned(UUID authenticatedUserId) {
        return documentRepository.findAllByUserIdAndActiveTrueOrderByCreatedAtDesc(authenticatedUserId);
    }

    /**
     * Advances one owned document to {@code target}. Illegal jumps
     * (per {@link DocumentStatus#canTransitionTo}) are rejected with
     * {@code VALIDATION_FAILED}; foreign/inactive rows are 404.
     */
    @Transactional
    public UserDocument transitionStatus(UUID authenticatedUserId, UUID documentId,
                                         DocumentStatus target) {
        if (target == null) {
            throw validationFailure("status", "status is required");
        }
        UserDocument document = documentRepository.findByIdAndUserId(documentId, authenticatedUserId)
                .orElseThrow(() -> notFound());
        if (!document.isActive()) {
            throw notFound();
        }
        if (!document.getStatus().canTransitionTo(target)) {
            throw validationFailure("status",
                    "illegal transition from " + document.getStatus() + " to " + target);
        }
        document.setStatus(target);
        return documentRepository.save(document);
    }

    /**
     * Soft-deletes one owned document (sets {@code active=false}; the row
     * stays for audit, retrieval never serves it). Idempotent outcome for
     * the owner: already-inactive rows are 404, like foreign rows.
     */
    @Transactional
    public void delete(UUID authenticatedUserId, UUID documentId) {
        UserDocument document = documentRepository.findByIdAndUserId(documentId, authenticatedUserId)
                .orElseThrow(() -> notFound());
        if (!document.isActive()) {
            throw notFound();
        }
        document.setActive(false);
        documentRepository.save(document);
    }

    private User userOrThrow(UUID authenticatedUserId) {
        return userRepository.findById(authenticatedUserId)
                .orElseThrow(() -> new ApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(),
                        ErrorCode.UNAUTHORIZED.name(), "Authentication required"));
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                ErrorCode.RESOURCE_NOT_FOUND.name(), "Document not found");
    }

    private static ApiException validationFailure(String field, String message) {
        return new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                ErrorCode.VALIDATION_FAILED.name(), "Request validation failed",
                Map.of(field, message));
    }

    private static void requireText(String value, String field) {
        if (value == null || value.isBlank()) {
            throw validationFailure(field, field + " is required");
        }
    }
}
