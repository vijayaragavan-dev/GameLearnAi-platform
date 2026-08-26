package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.XpTransaction;

public interface XpTransactionRepository extends JpaRepository<XpTransaction, java.util.UUID> {

    /** Append-only ledger reads for a learner, oldest first. */
    List<XpTransaction> findByUserIdOrderByCreatedAtAsc(UUID userId);
}
