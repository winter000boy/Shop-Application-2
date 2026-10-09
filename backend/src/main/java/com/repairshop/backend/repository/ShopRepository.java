package com.repairshop.backend.repository;

import com.repairshop.backend.model.Shop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShopRepository extends JpaRepository<Shop, UUID> {

    Optional<Shop> findByEmail(String email);

    boolean existsByEmail(String email);

    boolean existsByUsername(String username);
}
