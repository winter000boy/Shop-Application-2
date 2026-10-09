package com.repairshop.backend.dto;

import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;

public class SyncRequest {

    // Server time returned by the previous sync (null = first sync, send everything)
    private Instant lastSyncTime;

    // Each order is validated individually by OrderService so one bad record can't block the whole sync
    @Size(max = 500, message = "Too many orders in one sync batch")
    private List<RepairOrderDto> localOrders;

    @Size(max = 500, message = "Too many deletions in one sync batch")
    private List<String> deletedOrderIds;

    public SyncRequest() {
    }

    public Instant getLastSyncTime() {
        return lastSyncTime;
    }

    public void setLastSyncTime(Instant lastSyncTime) {
        this.lastSyncTime = lastSyncTime;
    }

    public List<RepairOrderDto> getLocalOrders() {
        return localOrders;
    }

    public void setLocalOrders(List<RepairOrderDto> localOrders) {
        this.localOrders = localOrders;
    }

    public List<String> getDeletedOrderIds() {
        return deletedOrderIds;
    }

    public void setDeletedOrderIds(List<String> deletedOrderIds) {
        this.deletedOrderIds = deletedOrderIds;
    }
}
