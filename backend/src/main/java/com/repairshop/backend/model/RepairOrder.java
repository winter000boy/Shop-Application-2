package com.repairshop.backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;

@Entity
@Table(name = "repair_orders")
public class RepairOrder {

    @Id
    @Column(nullable = false)
    private String id; // String ID to allow client-side generated UUIDs

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", referencedColumnName = "id", nullable = false)
    private Shop shop;

    @NotBlank
    @Column(nullable = false)
    private String status; // PENDING, REPAIRED, DELIVERED, CANCELLED

    @NotNull
    @Column(name = "repair_date", nullable = false)
    private LocalDate repairDate;

    @NotNull
    @Column(name = "repair_time", nullable = false)
    private LocalTime repairTime;

    @Column(name = "reminder_enabled", nullable = false)
    private boolean reminderEnabled;

    @NotBlank
    @Column(name = "customer_name", nullable = false)
    private String customerName;

    @NotBlank
    @Column(name = "customer_number", nullable = false)
    private String customerNumber;

    @Column(name = "customer_address")
    private String customerAddress;

    @NotBlank
    @Column(name = "device_problem", length = 1000, nullable = false)
    private String deviceProblem;

    @NotNull
    @Column(name = "estimate_price", nullable = false)
    private BigDecimal estimatePrice;

    @NotNull
    @Column(name = "paid_price", nullable = false)
    private BigDecimal paidPrice;

    @Column(name = "device_password")
    private String devicePassword;

    @Column(name = "device_pattern")
    private String devicePattern;

    @Column(length = 2000)
    private String description;

    // Accessories checklist
    @Column(name = "accessories_sim", nullable = false)
    private boolean accessoriesSim;

    @Column(name = "accessories_sd_card", nullable = false)
    private boolean accessoriesSdCard;

    @Column(name = "accessories_back_cover", nullable = false)
    private boolean accessoriesBackCover;

    @Column(name = "accessories_charger", nullable = false)
    private boolean accessoriesCharger;

    // Notifications
    @Column(name = "notify_whatsapp", nullable = false)
    private boolean notifyWhatsapp;

    @Column(name = "notify_email", nullable = false)
    private boolean notifyEmail;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public RepairOrder() {
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Shop getShop() {
        return shop;
    }

    public void setShop(Shop shop) {
        this.shop = shop;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDate getRepairDate() {
        return repairDate;
    }

    public void setRepairDate(LocalDate repairDate) {
        this.repairDate = repairDate;
    }

    public LocalTime getRepairTime() {
        return repairTime;
    }

    public void setRepairTime(LocalTime repairTime) {
        this.repairTime = repairTime;
    }

    public boolean isReminderEnabled() {
        return reminderEnabled;
    }

    public void setReminderEnabled(boolean reminderEnabled) {
        this.reminderEnabled = reminderEnabled;
    }

    public String getCustomerName() {
        return customerName;
    }

    public void setCustomerName(String customerName) {
        this.customerName = customerName;
    }

    public String getCustomerNumber() {
        return customerNumber;
    }

    public void setCustomerNumber(String customerNumber) {
        this.customerNumber = customerNumber;
    }

    public String getCustomerAddress() {
        return customerAddress;
    }

    public void setCustomerAddress(String customerAddress) {
        this.customerAddress = customerAddress;
    }

    public String getDeviceProblem() {
        return deviceProblem;
    }

    public void setDeviceProblem(String deviceProblem) {
        this.deviceProblem = deviceProblem;
    }

    public BigDecimal getEstimatePrice() {
        return estimatePrice;
    }

    public void setEstimatePrice(BigDecimal estimatePrice) {
        this.estimatePrice = estimatePrice;
    }

    public BigDecimal getPaidPrice() {
        return paidPrice;
    }

    public void setPaidPrice(BigDecimal paidPrice) {
        this.paidPrice = paidPrice;
    }

    public String getDevicePassword() {
        return devicePassword;
    }

    public void setDevicePassword(String devicePassword) {
        this.devicePassword = devicePassword;
    }

    public String getDevicePattern() {
        return devicePattern;
    }

    public void setDevicePattern(String devicePattern) {
        this.devicePattern = devicePattern;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isAccessoriesSim() {
        return accessoriesSim;
    }

    public void setAccessoriesSim(boolean accessoriesSim) {
        this.accessoriesSim = accessoriesSim;
    }

    public boolean isAccessoriesSdCard() {
        return accessoriesSdCard;
    }

    public void setAccessoriesSdCard(boolean accessoriesSdCard) {
        this.accessoriesSdCard = accessoriesSdCard;
    }

    public boolean isAccessoriesBackCover() {
        return accessoriesBackCover;
    }

    public void setAccessoriesBackCover(boolean accessoriesBackCover) {
        this.accessoriesBackCover = accessoriesBackCover;
    }

    public boolean isAccessoriesCharger() {
        return accessoriesCharger;
    }

    public void setAccessoriesCharger(boolean accessoriesCharger) {
        this.accessoriesCharger = accessoriesCharger;
    }

    public boolean isNotifyWhatsapp() {
        return notifyWhatsapp;
    }

    public void setNotifyWhatsapp(boolean notifyWhatsapp) {
        this.notifyWhatsapp = notifyWhatsapp;
    }

    public boolean isNotifyEmail() {
        return notifyEmail;
    }

    public void setNotifyEmail(boolean notifyEmail) {
        this.notifyEmail = notifyEmail;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
