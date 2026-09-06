package com.gamelearn.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Avatar;

public interface AvatarRepository extends JpaRepository<Avatar, UUID> {

    Optional<Avatar> findByCode(String code);

    List<Avatar> findByActiveTrueOrderByDisplayOrderAscIdAsc();

    List<Avatar> findAllByOrderByDisplayOrderAscIdAsc();

    List<Avatar> findByRarity(String rarity);
}
