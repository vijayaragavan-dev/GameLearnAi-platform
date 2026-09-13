package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.SubjectGameCompat;

public interface SubjectGameCompatRepository extends JpaRepository<SubjectGameCompat, UUID> {

    List<SubjectGameCompat> findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(UUID subjectId);

    boolean existsBySubjectIdAndGameTypeAndActiveTrue(UUID subjectId, String gameType);
}
