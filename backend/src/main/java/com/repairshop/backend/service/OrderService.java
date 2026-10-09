package com.repairshop.backend.service;

import com.repairshop.backend.dto.PageResponse;
import com.repairshop.backend.dto.RepairOrderDto;
import com.repairshop.backend.dto.SyncRequest;
import com.repairshop.backend.dto.SyncResponse;
import com.repairshop.backend.exception.ConflictException;
import com.repairshop.backend.exception.ResourceNotFoundException;
import com.repairshop.backend.model.OrderStatus;
import com.repairshop.backend.model.RepairOrder;
import com.repairshop.backend.model.Shop;
import com.repairshop.backend.repository.RepairOrderRepository;
import jakarta.validation.Validator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    static final int MAX_PAGE_SIZE = 100;
    // Re-send rows written slightly before the client's cursor, so a transaction that committed
    // late (after another device's sync read the table) is never skipped. Clients upsert idempotently.
    static final Duration SYNC_OVERLAP = Duration.ofSeconds(30);
    // Client edit timestamps further in the future than this are clamped to "now" so a phone with a
    // wrong clock can't win every future conflict.
    static final Duration MAX_CLOCK_SKEW = Duration.ofMinutes(5);

    private final RepairOrderRepository orderRepository;
    private final ShopService shopService;
    private final Validator validator;

    public OrderService(RepairOrderRepository orderRepository, ShopService shopService, Validator validator) {
        this.orderRepository = orderRepository;
        this.shopService = shopService;
        this.validator = validator;
    }

    @Transactional(readOnly = true)
    public PageResponse<RepairOrderDto> getOrders(OrderStatus status, String query, int page, int size) {
        Shop currentShop = shopService.getCurrentShop();
        Pageable pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        boolean hasQuery = query != null && !query.isBlank();

        Page<RepairOrder> orders;
        if (status != null && hasQuery) {
            orders = orderRepository.searchOrdersByStatus(currentShop, status, query.trim(), pageable);
        } else if (status != null) {
            orders = orderRepository.findByShopAndStatusAndDeletedFalse(currentShop, status, pageable);
        } else if (hasQuery) {
            orders = orderRepository.searchOrders(currentShop, query.trim(), pageable);
        } else {
            orders = orderRepository.findByShopAndDeletedFalse(currentShop, pageable);
        }

        return PageResponse.of(orders.map(this::toDto));
    }

    @Transactional(readOnly = true)
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
        } else if (orderRepository.existsById(dto.getId())) {
            throw new ConflictException("A repair order with this ID already exists");
        } else {
            order.setId(dto.getId());
        }

        order.setShop(currentShop);
        updateOrderFields(order, dto);
        order.setUpdatedAt(now());

        RepairOrder savedOrder = orderRepository.save(order);
        return toDto(savedOrder);
    }

    @Transactional
    public RepairOrderDto updateOrder(String id, RepairOrderDto dto) {
        RepairOrder order = getAndVerifyOrder(id);
        updateOrderFields(order, dto);
        order.setUpdatedAt(now());
        RepairOrder savedOrder = orderRepository.save(order);
        return toDto(savedOrder);
    }

    @Transactional
    public void deleteOrder(String id) {
        RepairOrder order = getAndVerifyOrder(id);
        markDeleted(order, now());
    }

    @Transactional
    public SyncResponse syncOrders(SyncRequest request) {
        Shop currentShop = shopService.getCurrentShop();
        Instant serverSyncTime = now();

        List<String> deletedIds = request.getDeletedOrderIds() != null ? request.getDeletedOrderIds() : List.of();
        List<RepairOrderDto> localOrders = request.getLocalOrders() != null ? request.getLocalOrders() : List.of();

        // Load every referenced order in one query instead of one query per order
        Set<String> referencedIds = new HashSet<>(deletedIds);
        localOrders.stream().map(RepairOrderDto::getId).filter(id -> id != null && !id.isBlank()).forEach(referencedIds::add);
        Map<String, RepairOrder> existing = orderRepository.findAllById(referencedIds).stream()
                .collect(Collectors.toMap(RepairOrder::getId, Function.identity()));

        // Orders whose pushed version lost a conflict; the winning server version is sent back
        Map<String, RepairOrder> rejected = new LinkedHashMap<>();

        // 1. Deletions requested by the client become tombstones (so other devices learn about them)
        for (String orderId : deletedIds) {
            RepairOrder order = existing.get(orderId);
            if (order != null && belongsTo(order, currentShop) && !order.isDeleted()) {
                markDeleted(order, serverSyncTime);
            }
        }

        // 2. Additions/updates requested by the client (last-write-wins on the edit timestamp)
        List<RepairOrder> toSave = new ArrayList<>();
        for (RepairOrderDto localDto : localOrders) {
            if (localDto.getId() == null || localDto.getId().isBlank()) {
                continue;
            }
            if (!validator.validate(localDto).isEmpty()) {
                log.warn("Skipping invalid order {} in sync from shop {}", localDto.getId(), currentShop.getId());
                continue;
            }

            Instant clientEditTime = clampToServerClock(localDto.getUpdatedAt(), serverSyncTime);
            RepairOrder order = existing.get(localDto.getId());

            if (order != null) {
                // Ensure the order belongs to the syncing shop
                if (!belongsTo(order, currentShop)) {
                    continue;
                }
                // A deletion wins over a concurrent edit; an older edit loses to a newer one
                if (order.isDeleted() || (clientEditTime != null && !clientEditTime.isAfter(order.getUpdatedAt()))) {
                    rejected.put(order.getId(), order);
                    continue;
                }
            } else {
                order = new RepairOrder();
                order.setId(localDto.getId());
                order.setShop(currentShop);
                order.setCreatedAt(localDto.getCreatedAt() != null ? localDto.getCreatedAt() : serverSyncTime);
            }

            updateOrderFields(order, localDto);
            order.setUpdatedAt(clientEditTime != null ? clientEditTime : serverSyncTime);
            toSave.add(order);
        }
        orderRepository.saveAll(toSave);
        orderRepository.flush();

        // 3. Server changes to send back to the client (tombstones included as deleted=true)
        List<RepairOrder> serverUpdates;
        if (request.getLastSyncTime() == null) {
            serverUpdates = orderRepository.findByShopAndDeletedFalse(currentShop);
        } else {
            serverUpdates = orderRepository.findByShopAndServerModifiedAtAfter(
                    currentShop, request.getLastSyncTime().minus(SYNC_OVERLAP));
        }

        Map<String, RepairOrder> response = new LinkedHashMap<>();
        serverUpdates.forEach(order -> response.put(order.getId(), order));
        rejected.forEach(response::putIfAbsent);

        List<RepairOrderDto> updatesDto = response.values().stream()
                .map(this::toDto)
                .collect(Collectors.toList());

        return new SyncResponse(updatesDto, serverSyncTime);
    }

    private RepairOrder getAndVerifyOrder(String id) {
        Shop currentShop = shopService.getCurrentShop();
        // Orders of other shops are reported as "not found" so IDs can't be probed
        return orderRepository.findById(id)
                .filter(order -> belongsTo(order, currentShop) && !order.isDeleted())
                .orElseThrow(() -> new ResourceNotFoundException("Repair order not found"));
    }

    private static boolean belongsTo(RepairOrder order, Shop shop) {
        return order.getShop().getId().equals(shop.getId());
    }

    private static Instant now() {
        return Instant.now().truncatedTo(ChronoUnit.MILLIS);
    }

    private static Instant clampToServerClock(Instant clientTime, Instant serverNow) {
        if (clientTime == null) {
            return null;
        }
        return clientTime.isAfter(serverNow.plus(MAX_CLOCK_SKEW)) ? serverNow : clientTime;
    }

    private static void markDeleted(RepairOrder order, Instant when) {
        order.setDeleted(true);
        order.setDevicePassword(null);
        order.setDevicePattern(null);
        order.setUpdatedAt(when);
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
        // Once the device has left the shop there is no reason to keep the customer's unlock secrets
        boolean deviceReturned = dto.getStatus() == OrderStatus.DELIVERED || dto.getStatus() == OrderStatus.CANCELLED;
        order.setDevicePassword(deviceReturned ? null : dto.getDevicePassword());
        order.setDevicePattern(deviceReturned ? null : dto.getDevicePattern());
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
        dto.setDeleted(order.isDeleted());
        dto.setCreatedAt(order.getCreatedAt());
        dto.setUpdatedAt(order.getUpdatedAt());
        return dto;
    }
}
