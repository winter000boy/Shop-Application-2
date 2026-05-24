package com.repairshop.backend.service;

import com.repairshop.backend.dto.RepairOrderDto;
import com.repairshop.backend.dto.SyncRequest;
import com.repairshop.backend.dto.SyncResponse;
import com.repairshop.backend.model.RepairOrder;
import com.repairshop.backend.model.Shop;
import com.repairshop.backend.repository.RepairOrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class OrderService {

    private final RepairOrderRepository orderRepository;
    private final ShopService shopService;

    public OrderService(RepairOrderRepository orderRepository, ShopService shopService) {
        this.orderRepository = orderRepository;
        this.shopService = shopService;
    }

    public List<RepairOrderDto> getOrders(String status, String query) {
        Shop currentShop = shopService.getCurrentShop();
        List<RepairOrder> orders;

        if (status != null && !status.isBlank() && query != null && !query.isBlank()) {
            orders = orderRepository.searchOrdersByStatus(currentShop, status, query);
        } else if (status != null && !status.isBlank()) {
            orders = orderRepository.findByShopAndStatusOrderByCreatedAtDesc(currentShop, status);
        } else if (query != null && !query.isBlank()) {
            orders = orderRepository.searchOrders(currentShop, query);
        } else {
            orders = orderRepository.findByShopOrderByCreatedAtDesc(currentShop);
        }

        return orders.stream().map(this::toDto).collect(Collectors.toList());
    }

    public RepairOrderDto getOrderById(String id) {
        RepairOrder order = getAndVerifyOrder(id);
        return toDto(order);
    }

    @Transactional
    public RepairOrderDto createOrder(RepairOrderDto dto) {
        Shop currentShop = shopService.getCurrentShop();
        RepairOrder order = new RepairOrder();
        
        // Use client-provided ID (UUID) or generate one if not present
        if (dto.getId() == null || dto.getId().isBlank()) {
            order.setId(UUID.randomUUID().toString());
        } else {
            order.setId(dto.getId());
        }

        order.setShop(currentShop);
        updateOrderFields(order, dto);

        RepairOrder savedOrder = orderRepository.save(order);
        return toDto(savedOrder);
    }

    @Transactional
    public RepairOrderDto updateOrder(String id, RepairOrderDto dto) {
        RepairOrder order = getAndVerifyOrder(id);
        updateOrderFields(order, dto);
        RepairOrder savedOrder = orderRepository.save(order);
        return toDto(savedOrder);
    }

    @Transactional
    public void deleteOrder(String id) {
        RepairOrder order = getAndVerifyOrder(id);
        orderRepository.delete(order);
    }

    @Transactional
    public SyncResponse syncOrders(SyncRequest request) {
        Shop currentShop = shopService.getCurrentShop();
        LocalDateTime serverSyncTime = LocalDateTime.now();

        // 1. Process deletions requested by the client
        if (request.getDeletedOrderIds() != null && !request.getDeletedOrderIds().isEmpty()) {
            for (String orderId : request.getDeletedOrderIds()) {
                orderRepository.findById(orderId).ifPresent(order -> {
                    if (order.getShop().getId().equals(currentShop.getId())) {
                        orderRepository.delete(order);
                    }
                });
            }
        }

        // 2. Process additions/updates requested by the client
        if (request.getLocalOrders() != null && !request.getLocalOrders().isEmpty()) {
            for (RepairOrderDto localDto : request.getLocalOrders()) {
                if (localDto.getId() == null || localDto.getId().isBlank()) {
                    continue;
                }

                Optional<RepairOrder> existingOrderOpt = orderRepository.findById(localDto.getId());
                RepairOrder order;
                
                if (existingOrderOpt.isPresent()) {
                    order = existingOrderOpt.get();
                    // Ensure the order belongs to the syncing shop
                    if (!order.getShop().getId().equals(currentShop.getId())) {
                        continue;
                    }
                } else {
                    order = new RepairOrder();
                    order.setId(localDto.getId());
                    order.setShop(currentShop);
                }

                // If existing, compare timestamps to resolve conflicts (last-write-wins)
                if (existingOrderOpt.isPresent() && localDto.getUpdatedAt() != null && order.getUpdatedAt() != null) {
                    if (localDto.getUpdatedAt().isBefore(order.getUpdatedAt())) {
                        // Server version is newer, skip saving local client version
                        continue;
                    }
                }

                updateOrderFields(order, localDto);
                if (localDto.getCreatedAt() != null) {
                    order.setCreatedAt(localDto.getCreatedAt());
                }
                orderRepository.save(order);
            }
        }

        // 3. Fetch server updates to send back to the client
        List<RepairOrder> serverUpdates;
        if (request.getLastSyncTime() == null) {
            serverUpdates = orderRepository.findByShopOrderByCreatedAtDesc(currentShop);
        } else {
            serverUpdates = orderRepository.findByShopAndUpdatedAtAfter(currentShop, request.getLastSyncTime());
        }

        List<RepairOrderDto> updatesDto = serverUpdates.stream()
                .map(this::toDto)
                .collect(Collectors.toList());

        return new SyncResponse(updatesDto, serverSyncTime);
    }

    private RepairOrder getAndVerifyOrder(String id) {
        Shop currentShop = shopService.getCurrentShop();
        RepairOrder order = orderRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Repair order not found with ID: " + id));

        if (!order.getShop().getId().equals(currentShop.getId())) {
            throw new SecurityException("Unauthorized access to repair order");
        }
        return order;
    }

    private void updateOrderFields(RepairOrder order, RepairOrderDto dto) {
        order.setStatus(dto.getStatus());
        order.setRepairDate(dto.getRepairDate());
        order.setRepairTime(dto.getRepairTime());
        order.setReminderEnabled(dto.isReminderEnabled());
        order.setCustomerName(dto.getCustomerName());
        order.setCustomerNumber(dto.getCustomerNumber());
        order.setCustomerAddress(dto.getCustomerAddress());
        order.setDeviceProblem(dto.getDeviceProblem());
        order.setEstimatePrice(dto.getEstimatePrice());
        order.setPaidPrice(dto.getPaidPrice());
        order.setDevicePassword(dto.getDevicePassword());
        order.setDevicePattern(dto.getDevicePattern());
        order.setDescription(dto.getDescription());
        order.setAccessoriesSim(dto.isAccessoriesSim());
        order.setAccessoriesSdCard(dto.isAccessoriesSdCard());
        order.setAccessoriesBackCover(dto.isAccessoriesBackCover());
        order.setAccessoriesCharger(dto.isAccessoriesCharger());
        order.setNotifyWhatsapp(dto.isNotifyWhatsapp());
        order.setNotifyEmail(dto.isNotifyEmail());
    }

    private RepairOrderDto toDto(RepairOrder order) {
        RepairOrderDto dto = new RepairOrderDto();
        dto.setId(order.getId());
        dto.setStatus(order.getStatus());
        dto.setRepairDate(order.getRepairDate());
        dto.setRepairTime(order.getRepairTime());
        dto.setReminderEnabled(order.isReminderEnabled());
        dto.setCustomerName(order.getCustomerName());
        dto.setCustomerNumber(order.getCustomerNumber());
        dto.setCustomerAddress(order.getCustomerAddress());
        dto.setDeviceProblem(order.getDeviceProblem());
        dto.setEstimatePrice(order.getEstimatePrice());
        dto.setPaidPrice(order.getPaidPrice());
        dto.setDevicePassword(order.getDevicePassword());
        dto.setDevicePattern(order.getDevicePattern());
        dto.setDescription(order.getDescription());
        dto.setAccessoriesSim(order.isAccessoriesSim());
        dto.setAccessoriesSdCard(order.isAccessoriesSdCard());
        dto.setAccessoriesBackCover(order.isAccessoriesBackCover());
        dto.setAccessoriesCharger(order.isAccessoriesCharger());
        dto.setNotifyWhatsapp(order.isNotifyWhatsapp());
        dto.setNotifyEmail(order.isNotifyEmail());
        dto.setCreatedAt(order.getCreatedAt());
        dto.setUpdatedAt(order.getUpdatedAt());
        return dto;
    }
}
