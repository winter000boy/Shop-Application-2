package com.repairshop.backend.dto;

import java.time.LocalDateTime;
import java.util.List;

public class SyncResponse {

    private List<RepairOrderDto> serverOrders;
    private LocalDateTime serverSyncTime;

    public SyncResponse(List<RepairOrderDto> serverOrders, LocalDateTime serverSyncTime) {
        this.serverOrders = serverOrders;
        this.serverSyncTime = serverSyncTime;
    }

    public List<RepairOrderDto> getServerOrders() {
        return serverOrders;
    }

    public void setServerOrders(List<RepairOrderDto> serverOrders) {
        this.serverOrders = serverOrders;
    }

    public LocalDateTime getServerSyncTime() {
        return serverSyncTime;
    }

    public void setServerSyncTime(LocalDateTime serverSyncTime) {
        this.serverSyncTime = serverSyncTime;
    }
}
