package com.repairshop.backend.controller;

import com.repairshop.backend.dto.PageResponse;
import com.repairshop.backend.dto.RepairOrderDto;
import com.repairshop.backend.dto.SyncRequest;
import com.repairshop.backend.dto.SyncResponse;
import com.repairshop.backend.model.OrderStatus;
import com.repairshop.backend.service.OrderService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping
    public ResponseEntity<PageResponse<RepairOrderDto>> getOrders(
            @RequestParam(value = "status", required = false) OrderStatus status,
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "20") int size
    ) {
        return ResponseEntity.ok(orderService.getOrders(status, query, page, size));
    }

    @GetMapping("/{id}")
    public ResponseEntity<RepairOrderDto> getOrderById(@PathVariable("id") String id) {
        return ResponseEntity.ok(orderService.getOrderById(id));
    }

    @PostMapping
    public ResponseEntity<RepairOrderDto> createOrder(@Valid @RequestBody RepairOrderDto dto) {
        return new ResponseEntity<>(orderService.createOrder(dto), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<RepairOrderDto> updateOrder(
            @PathVariable("id") String id,
            @Valid @RequestBody RepairOrderDto dto
    ) {
        return ResponseEntity.ok(orderService.updateOrder(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteOrder(@PathVariable("id") String id) {
        orderService.deleteOrder(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/sync")
    public ResponseEntity<SyncResponse> syncOrders(@Valid @RequestBody SyncRequest request) {
        return ResponseEntity.ok(orderService.syncOrders(request));
    }
}
