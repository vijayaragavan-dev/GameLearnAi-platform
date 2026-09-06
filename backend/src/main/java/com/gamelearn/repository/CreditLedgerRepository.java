package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.CreditLedger;

public interface CreditLedgerRepository extends JpaRepository<CreditLedger, UUID> {

    List<CreditLedger> findByUserIdOrderByCreatedAtAsc(UUID userId);

    long countByUserIdAndReferenceTypeAndReferenceId(UUID userId, String referenceType, UUID referenceId);
}
