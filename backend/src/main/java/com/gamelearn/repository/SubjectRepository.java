package com.gamelearn.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Subject;

public interface SubjectRepository extends JpaRepository<Subject, java.util.UUID> {

    java.util.List<Subject> findByActiveTrueOrderByDisplayOrderAscIdAsc();

}
