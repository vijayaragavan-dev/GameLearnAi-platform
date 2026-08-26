package com.gamelearn.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.AiInteraction;

public interface AiInteractionRepository extends JpaRepository<AiInteraction, java.util.UUID> {
}
