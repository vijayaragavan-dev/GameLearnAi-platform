package com.gamelearn.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.UserDocument;

/**
 * Owner-scoped access to user-document metadata (USER-DOC RAG Phase B).
 *
 * <p>SECURITY: every method here takes the server-derived owner id (from
 * the authenticated principal) as a parameter. A lookup with a non-owner
 * id returns empty — never another user's row. The inherited plain
 * {@code findById} exists only because {@code JpaRepository} declares it;
 * service-layer code MUST NOT use it for authorization-sensitive access —
 * use the {@code ...AndUserId} methods below so ownership is enforced by
 * the query itself.</p>
 */
public interface UserDocumentRepository extends JpaRepository<UserDocument, UUID> {

    /** Single owned document (any active state); empty when not owned. */
    Optional<UserDocument> findByIdAndUserId(UUID id, UUID userId);

    /** Single owned AND servable document (soft-deleted rows excluded). */
    Optional<UserDocument> findByIdAndUserIdAndActiveTrue(UUID id, UUID userId);

    /** Owned servable documents, newest first (future list/delete views). */
    List<UserDocument> findAllByUserIdAndActiveTrueOrderByCreatedAtDesc(UUID userId);

    /** Ownership probe without loading the row (future auth checks). */
    boolean existsByIdAndUserId(UUID id, UUID userId);
}
