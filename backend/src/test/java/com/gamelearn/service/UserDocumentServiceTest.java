package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.User;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.entity.enums.DocumentStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.persistence.PersistenceTestFixtures;
import com.gamelearn.repository.UserRepository;

/**
 * Ownership and lifecycle tests for the Phase B document-metadata boundary.
 *
 * <p>Core invariant: every method takes the server-authenticated user id —
 * there is no owner parameter to spoof, so cross-user access can only be
 * attempted with a foreign PRINCIPAL id, and must always surface as
 * {@code RESOURCE_NOT_FOUND} (never the document, never {@code FORBIDDEN}
 * which would confirm existence).</p>
 */
@SpringBootTest
@ActiveProfiles("test")
class UserDocumentServiceTest {

    @Autowired
    private UserDocumentService documentService;

    @Autowired
    private UserRepository userRepository;

    @Test
    void registerDerivesOwnershipFromServerIdentity() {
        User ownerA = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcA"));

        UserDocument created = documentService.register(
                ownerA.getId(), "lecture.pdf", "application/pdf", 2048);

        assertThat(created.getId()).isNotNull();
        assertThat(created.getUser().getId()).isEqualTo(ownerA.getId());
        assertThat(created.getStatus()).isEqualTo(DocumentStatus.UPLOADED);
        assertThat(created.isActive()).isTrue();
        assertThat(created.getFilename()).isEqualTo("lecture.pdf");
    }

    @Test
    void registerRejectsInvalidInput() {
        User owner = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcvalid"));

        assertThatThrownBy(() -> documentService.register(owner.getId(), "  ", "application/pdf", 10))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));

        assertThatThrownBy(() -> documentService.register(owner.getId(), "a.pdf", "application/pdf", -1))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));

        assertThatThrownBy(() -> documentService.register(UUID.randomUUID(), "a.pdf", "application/pdf", 1))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.UNAUTHORIZED.name()));
    }

    @Test
    void getOwnedEnforcesIsolationWithNotFound() {
        User ownerA = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcgetA"));
        User ownerB = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcgetB"));

        UserDocument ownedByA = documentService.register(
                ownerA.getId(), "private.pdf", "application/pdf", 512);

        // Owner reads fine.
        assertThat(documentService.getOwned(ownerA.getId(), ownedByA.getId()).getId())
                .isEqualTo(ownedByA.getId());

        // Foreign principal learns nothing: NOT FOUND, never FORBIDDEN, never the row.
        assertThatThrownBy(() -> documentService.getOwned(ownerB.getId(), ownedByA.getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException api = (ApiException) ex;
                    assertThat(api.getErrorCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name());
                    assertThat(api.getHttpStatus()).isEqualTo(404);
                });

        assertThatThrownBy(() -> documentService.getOwned(ownerA.getId(), UUID.randomUUID()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
    }

    @Test
    void listOwnedReturnsOnlyCallerActiveDocuments() {
        User ownerA = userRepository.saveAndFlush(PersistenceTestFixtures.user("svclistA"));
        User ownerB = userRepository.saveAndFlush(PersistenceTestFixtures.user("svclistB"));

        UserDocument first = documentService.register(ownerA.getId(), "one.pdf", "application/pdf", 1);
        UserDocument second = documentService.register(ownerA.getId(), "two.pdf", "application/pdf", 2);
        documentService.register(ownerB.getId(), "other.pdf", "application/pdf", 3);
        documentService.delete(ownerA.getId(), second.getId());

        List<UserDocument> visible = documentService.listOwned(ownerA.getId());
        assertThat(visible).extracting(UserDocument::getId).containsExactly(first.getId());
    }

    @Test
    void statusAdvancesThroughLegalTransitions() {
        User owner = userRepository.saveAndFlush(PersistenceTestFixtures.user("svctrans"));
        UserDocument document = documentService.register(
                owner.getId(), "flow.pdf", "application/pdf", 100);

        document = documentService.transitionStatus(owner.getId(), document.getId(),
                DocumentStatus.EXTRACTING);
        assertThat(document.getStatus()).isEqualTo(DocumentStatus.EXTRACTING);

        document = documentService.transitionStatus(owner.getId(), document.getId(),
                DocumentStatus.CHUNKED);
        assertThat(document.getStatus()).isEqualTo(DocumentStatus.CHUNKED);

        document = documentService.transitionStatus(owner.getId(), document.getId(),
                DocumentStatus.INDEXED);
        assertThat(document.getStatus()).isEqualTo(DocumentStatus.INDEXED);
    }

    @Test
    void illegalTransitionsAreRejected() {
        User owner = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcill"));

        // UPLOADED -> INDEXED skips the pipeline: rejected.
        UserDocument direct = documentService.register(owner.getId(), "skip.pdf", "application/pdf", 1);
        assertThatThrownBy(() -> documentService.transitionStatus(
                        owner.getId(), direct.getId(), DocumentStatus.INDEXED))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));

        // INDEXED -> UPLOADED goes backwards: rejected.
        UserDocument indexed = documentService.register(owner.getId(), "back.pdf", "application/pdf", 1);
        documentService.transitionStatus(owner.getId(), indexed.getId(), DocumentStatus.EXTRACTING);
        documentService.transitionStatus(owner.getId(), indexed.getId(), DocumentStatus.CHUNKED);
        documentService.transitionStatus(owner.getId(), indexed.getId(), DocumentStatus.INDEXED);
        assertThatThrownBy(() -> documentService.transitionStatus(
                        owner.getId(), indexed.getId(), DocumentStatus.UPLOADED))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));

        assertThatThrownBy(() -> documentService.transitionStatus(
                        owner.getId(), indexed.getId(), null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));
    }

    @Test
    void failedDocumentsCanRetryButForeignTransitionsAreNotFound() {
        User ownerA = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcretryA"));
        User ownerB = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcretryB"));

        UserDocument document = documentService.register(ownerA.getId(), "r.pdf", "application/pdf", 1);
        documentService.transitionStatus(ownerA.getId(), document.getId(), DocumentStatus.FAILED);

        // Retry is the only way out of FAILED.
        UserDocument retried = documentService.transitionStatus(
                ownerA.getId(), document.getId(), DocumentStatus.EXTRACTING);
        assertThat(retried.getStatus()).isEqualTo(DocumentStatus.EXTRACTING);

        // Foreign principal cannot move A's document, even to a legal state.
        assertThatThrownBy(() -> documentService.transitionStatus(
                        ownerB.getId(), document.getId(), DocumentStatus.CHUNKED))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
    }

    @Test
    void deleteSoftDeletesOwnedOnly() {
        User ownerA = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcdelA"));
        User ownerB = userRepository.saveAndFlush(PersistenceTestFixtures.user("svcdelB"));

        UserDocument ownedByA = documentService.register(ownerA.getId(), "bye.pdf", "application/pdf", 1);

        // Foreign delete fails as NOT FOUND and leaves the row active.
        assertThatThrownBy(() -> documentService.delete(ownerB.getId(), ownedByA.getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
        assertThat(documentService.getOwned(ownerA.getId(), ownedByA.getId()).isActive())
                .isTrue();

        // Owner delete hides it from serving reads; repeat delete is NOT FOUND.
        documentService.delete(ownerA.getId(), ownedByA.getId());
        assertThatThrownBy(() -> documentService.getOwned(ownerA.getId(), ownedByA.getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
        assertThatThrownBy(() -> documentService.delete(ownerA.getId(), ownedByA.getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
    }

    @Test
    void transitionMatrixMatchesDocumentedPolicy() {
        assertThat(DocumentStatus.UPLOADED.canTransitionTo(DocumentStatus.EXTRACTING)).isTrue();
        assertThat(DocumentStatus.UPLOADED.canTransitionTo(DocumentStatus.INDEXED)).isFalse();
        assertThat(DocumentStatus.EXTRACTING.canTransitionTo(DocumentStatus.CHUNKED)).isTrue();
        assertThat(DocumentStatus.CHUNKED.canTransitionTo(DocumentStatus.INDEXED)).isTrue();
        assertThat(DocumentStatus.INDEXED.canTransitionTo(DocumentStatus.EXTRACTING)).isTrue();
        assertThat(DocumentStatus.INDEXED.canTransitionTo(DocumentStatus.UPLOADED)).isFalse();
        assertThat(DocumentStatus.FAILED.canTransitionTo(DocumentStatus.EXTRACTING)).isTrue();
        assertThat(DocumentStatus.FAILED.canTransitionTo(DocumentStatus.INDEXED)).isFalse();
        assertThat(DocumentStatus.UPLOADED.canTransitionTo(DocumentStatus.UPLOADED)).isFalse();
        assertThat(DocumentStatus.UPLOADED.canTransitionTo(null)).isFalse();
    }
}
