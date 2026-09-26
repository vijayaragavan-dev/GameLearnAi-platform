package com.gamelearn.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Realm;

public interface RealmRepository extends JpaRepository<Realm, UUID> {

    List<Realm> findByActiveTrueOrderByDisplayOrderAscIdAsc();

    Optional<Realm> findByRealmKeyIgnoreCase(String realmKey);

    boolean existsByRealmKeyIgnoreCase(String realmKey);
}
