package com.repairshop.backend.repository;

import com.repairshop.backend.model.RepairOrder;
import com.repairshop.backend.model.Shop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface RepairOrderRepository extends JpaRepository<RepairOrder, String> {

    List<RepairOrder> findByShopOrderByCreatedAtDesc(Shop shop);

    List<RepairOrder> findByShopAndStatusOrderByCreatedAtDesc(Shop shop, String status);

    @Query("SELECT r FROM RepairOrder r WHERE r.shop = :shop AND " +
           "(LOWER(r.customerName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "r.customerNumber LIKE CONCAT('%', :query, '%')) " +
           "ORDER BY r.createdAt DESC")
    List<RepairOrder> searchOrders(@Param("shop") Shop shop, @Param("query") String query);

    @Query("SELECT r FROM RepairOrder r WHERE r.shop = :shop AND " +
           "r.status = :status AND " +
           "(LOWER(r.customerName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "r.customerNumber LIKE CONCAT('%', :query, '%')) " +
           "ORDER BY r.createdAt DESC")
    List<RepairOrder> searchOrdersByStatus(@Param("shop") Shop shop, @Param("status") String status, @Param("query") String query);

    List<RepairOrder> findByShopAndUpdatedAtAfter(Shop shop, LocalDateTime updatedAt);
}
