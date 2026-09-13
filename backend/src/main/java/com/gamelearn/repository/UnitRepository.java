package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Unit;

public interface UnitRepository extends JpaRepository<Unit, UUID> {

    List<Unit> findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(UUID subjectId);
}
