package com.repairshop.backend.repository;

import com.repairshop.backend.model.OrderStatus;
import com.repairshop.backend.model.RepairOrder;
import com.repairshop.backend.model.Shop;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface RepairOrderRepository extends JpaRepository<RepairOrder, String> {

    Page<RepairOrder> findByShopAndDeletedFalse(Shop shop, Pageable pageable);

    Page<RepairOrder> findByShopAndStatusAndDeletedFalse(Shop shop, OrderStatus status, Pageable pageable);

    @Query("SELECT r FROM RepairOrder r WHERE r.shop = :shop AND r.deleted = false AND " +
           "(LOWER(r.customerName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "r.customerNumber LIKE CONCAT('%', :query, '%'))")
    Page<RepairOrder> searchOrders(@Param("shop") Shop shop, @Param("query") String query, Pageable pageable);

    @Query("SELECT r FROM RepairOrder r WHERE r.shop = :shop AND r.deleted = false AND " +
           "r.status = :status AND " +
           "(LOWER(r.customerName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "r.customerNumber LIKE CONCAT('%', :query, '%'))")
    Page<RepairOrder> searchOrdersByStatus(@Param("shop") Shop shop,
                                           @Param("status") OrderStatus status,
                                           @Param("query") String query,
                                           Pageable pageable);

    // First sync on a device: every live order
    List<RepairOrder> findByShopAndDeletedFalse(Shop shop);

    // Delta sync: everything (including tombstones) the server wrote after the cursor
    List<RepairOrder> findByShopAndServerModifiedAtAfter(Shop shop, Instant serverModifiedAt);
}
