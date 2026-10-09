package com.repairshop.backend.dto;

import java.time.Instant;
import java.util.List;

public class SyncResponse {

    // Orders changed on the server since lastSyncTime; entries with deleted=true must be removed locally
    private List<RepairOrderDto> serverOrders;
    private Instant serverSyncTime;

    public SyncResponse(List<RepairOrderDto> serverOrders, Instant serverSyncTime) {
        this.serverOrders = serverOrders;
        this.serverSyncTime = serverSyncTime;
    }

    public List<RepairOrderDto> getServerOrders() {
        return serverOrders;
    }

    public void setServerOrders(List<RepairOrderDto> serverOrders) {
        this.serverOrders = serverOrders;
    }

    public Instant getServerSyncTime() {
        return serverSyncTime;
    }

    public void setServerSyncTime(Instant serverSyncTime) {
        this.serverSyncTime = serverSyncTime;
    }
}
