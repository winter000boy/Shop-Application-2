package com.repairshop.backend.dto;

import java.time.LocalDateTime;
import java.util.List;

public class SyncRequest {

    private LocalDateTime lastSyncTime;
    private List<RepairOrderDto> localOrders;
    private List<String> deletedOrderIds;

    public SyncRequest() {
    }

    public LocalDateTime getLastSyncTime() {
        return lastSyncTime;
    }

    public void setLastSyncTime(LocalDateTime lastSyncTime) {
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
