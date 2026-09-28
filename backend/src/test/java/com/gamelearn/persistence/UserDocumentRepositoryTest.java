package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.User;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.entity.enums.DocumentStatus;
import com.gamelearn.repository.UserDocumentRepository;
import com.gamelearn.repository.UserRepository;

@SpringBootTest
@ActiveProfiles("test")
class UserDocumentRepositoryTest {

    @Autowired
    private UserDocumentRepository documentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void metadataPersistsWithDefaults() {
        User owner = userRepository.saveAndFlush(PersistenceTestFixtures.user("doc"));

        UserDocument saved = documentRepository.saveAndFlush(
                PersistenceTestFixtures.userDocument(owner));

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
        assertThat(saved.getStatus()).isEqualTo(DocumentStatus.UPLOADED);
        assertThat(saved.isActive()).isTrue();
        assertThat(saved.getDocVersion()).isEqualTo(1);
        assertThat(saved.getPageCount()).isNull();
        assertThat(saved.getSha256()).isNull();
    }

    @Test
    void ownerRelationshipRoundTrips() {
        User owner = userRepository.saveAndFlush(PersistenceTestFixtures.user("docowner"));

        UserDocument saved = documentRepository.saveAndFlush(
                PersistenceTestFixtures.userDocument(owner));

        UserDocument reloaded = documentRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getUser().getId()).isEqualTo(owner.getId());
        assertThat(reloaded.getFilename()).isEqualTo(saved.getFilename());
        assertThat(reloaded.getContentType()).isEqualTo("application/pdf");
        assertThat(reloaded.getByteSize()).isEqualTo(1024);
    }

    @Test
    void statusAndColumnsArePersistedAsExpectedRawValues() {
        User owner = userRepository.saveAndFlush(PersistenceTestFixtures.user("docraw"));
        UserDocument document = PersistenceTestFixtures.userDocument(owner);
        document.setStatus(DocumentStatus.EXTRACTING);
        document.setPageCount(7);
        document.setSha256("a".repeat(64));
        UserDocument saved = documentRepository.saveAndFlush(document);

        var raw = jdbcTemplate.queryForMap(
                "SELECT status, page_count, sha256, is_active, doc_version, filename, content_type"
                        + " FROM user_documents WHERE id = ?",
                saved.getId());
        assertThat(raw.get("status")).isEqualTo("EXTRACTING");
        assertThat(((Number) raw.get("page_count")).intValue()).isEqualTo(7);
        assertThat(String.valueOf(raw.get("sha256"))).isEqualTo("a".repeat(64));
        assertThat(raw.get("is_active")).isEqualTo(Boolean.TRUE);
        assertThat(((Number) raw.get("doc_version")).intValue()).isEqualTo(1);
        assertThat(String.valueOf(raw.get("filename"))).endsWith(".pdf");
        assertThat(raw.get("content_type")).isEqualTo("application/pdf");
    }

    @Test
    void ownerScopedLookupFindsOwnedDocument() {
        User owner = userRepository.saveAndFlush(PersistenceTestFixtures.user("docscope"));

        UserDocument saved = documentRepository.saveAndFlush(
                PersistenceTestFixtures.userDocument(owner));

        assertThat(documentRepository.findByIdAndUserId(saved.getId(), owner.getId()))
                .isPresent();
        assertThat(documentRepository.findByIdAndUserIdAndActiveTrue(saved.getId(), owner.getId()))
                .isPresent();
        assertThat(documentRepository.existsByIdAndUserId(saved.getId(), owner.getId()))
                .isTrue();
    }

    @Test
    void otherUserCannotReachForeignDocument() {
        User ownerA = userRepository.saveAndFlush(PersistenceTestFixtures.user("docA"));
        User ownerB = userRepository.saveAndFlush(PersistenceTestFixtures.user("docB"));

        UserDocument ownedByA = documentRepository.saveAndFlush(
                PersistenceTestFixtures.userDocument(ownerA));

        // B's owner-scoped lookups must behave as if A's document does not exist.
        assertThat(documentRepository.findByIdAndUserId(ownedByA.getId(), ownerB.getId()))
                .isEmpty();
        assertThat(documentRepository.findByIdAndUserIdAndActiveTrue(ownedByA.getId(), ownerB.getId()))
                .isEmpty();
        assertThat(documentRepository.existsByIdAndUserId(ownedByA.getId(), ownerB.getId()))
                .isFalse();

        List<UserDocument> visibleToB =
                documentRepository.findAllByUserIdAndActiveTrueOrderByCreatedAtDesc(ownerB.getId());
        assertThat(visibleToB).isEmpty();

        // A is unaffected.
        assertThat(documentRepository.findByIdAndUserId(ownedByA.getId(), ownerA.getId()))
                .isPresent();
    }

    @Test
    void listingReturnsOnlyOwnedActiveDocuments() {
        User ownerA = userRepository.saveAndFlush(PersistenceTestFixtures.user("doclistA"));
        User ownerB = userRepository.saveAndFlush(PersistenceTestFixtures.user("doclistB"));

        UserDocument first = documentRepository.saveAndFlush(
                PersistenceTestFixtures.userDocument(ownerA));
        UserDocument second = documentRepository.saveAndFlush(
                PersistenceTestFixtures.userDocument(ownerA));
        documentRepository.saveAndFlush(PersistenceTestFixtures.userDocument(ownerB));

        List<UserDocument> visibleToA =
                documentRepository.findAllByUserIdAndActiveTrueOrderByCreatedAtDesc(ownerA.getId());
        assertThat(visibleToA).extracting(UserDocument::getId)
                .containsExactlyInAnyOrder(first.getId(), second.getId());
    }

    @Test
    void softDeletedDocumentIsExcludedFromServingQueries() {
        User owner = userRepository.saveAndFlush(PersistenceTestFixtures.user("docdel"));

        UserDocument saved = documentRepository.saveAndFlush(
                PersistenceTestFixtures.userDocument(owner));
        saved.setActive(false);
        documentRepository.saveAndFlush(saved);

        UUID id = saved.getId();
        assertThat(documentRepository.findByIdAndUserIdAndActiveTrue(id, owner.getId()))
                .isEmpty();
        assertThat(documentRepository.findAllByUserIdAndActiveTrueOrderByCreatedAtDesc(owner.getId()))
                .isEmpty();
        // The row itself still exists for audit (ownership probe is not a serving path).
        assertThat(documentRepository.findByIdAndUserId(id, owner.getId())).isPresent();
    }
}
