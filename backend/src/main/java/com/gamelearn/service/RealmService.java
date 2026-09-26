package com.gamelearn.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.RealmResponse;
import com.gamelearn.dto.SubjectResponse;
import com.gamelearn.entity.Realm;
import com.gamelearn.entity.Subject;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.RealmRepository;
import com.gamelearn.repository.SubjectRepository;

/**
 * Learning-realm catalogue (REALM-001). Realms are a read-only
 * classification layer above subjects: Computer Science resolves into
 * the existing subject/world experience, and no realm changes how
 * subjects, topics, questions, games, results or progression behave.
 */
@Service
public class RealmService {

    private final RealmRepository realmRepository;
    private final SubjectRepository subjectRepository;

    public RealmService(RealmRepository realmRepository, SubjectRepository subjectRepository) {
        this.realmRepository = realmRepository;
        this.subjectRepository = subjectRepository;
    }

    @Transactional(readOnly = true)
    public List<RealmResponse> listActiveRealms() {
        return realmRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc().stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Realm requireActiveRealm(String realmKey) {
        Realm realm = realmRepository.findByRealmKeyIgnoreCase(realmKey)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Realm not found"));
        if (!realm.isActive()) {
            throw new ApiException(
                    ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(),
                    "Realm not found");
        }
        return realm;
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> subjectsForRealm(String realmKey) {
        Realm realm = requireActiveRealm(realmKey);
        return subjectRepository
                .findByRealmIdAndActiveTrueOrderByDisplayOrderAscIdAsc(realm.getId())
                .stream()
                .map(this::toSubjectResponse)
                .toList();
    }

    private RealmResponse toResponse(Realm realm) {
        return new RealmResponse(realm.getId(), realm.getRealmKey(), realm.getName(),
                realm.getDescription(), realm.getIconKey(), realm.isActive(),
                realm.getDisplayOrder());
    }

    private SubjectResponse toSubjectResponse(Subject subject) {
        String realmKey = subject.getRealm() != null ? subject.getRealm().getRealmKey() : null;
        return new SubjectResponse(subject.getId(), subject.getName(), subject.getDescription(),
                subject.getIconKey(), subject.isActive(), subject.getDisplayOrder(), realmKey);
    }
}
