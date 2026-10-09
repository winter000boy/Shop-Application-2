package com.repairshop.backend.repository;

import com.repairshop.backend.model.RefreshToken;
import com.repairshop.backend.model.Shop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    @Modifying
    @Query("DELETE FROM RefreshToken t WHERE t.shop = :shop AND (t.revoked = true OR t.expiryDate < :now)")
    int deleteStaleTokens(@Param("shop") Shop shop, @Param("now") Instant now);

    @Modifying
    int deleteByShop(Shop shop);
}
