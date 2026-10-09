package com.repairshop.backend.repository;

import com.repairshop.backend.model.PasswordResetCode;
import com.repairshop.backend.model.Shop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, UUID> {

    Optional<PasswordResetCode> findFirstByShopAndUsedFalseOrderByExpiresAtDesc(Shop shop);

    @Modifying
    int deleteByShop(Shop shop);
}
