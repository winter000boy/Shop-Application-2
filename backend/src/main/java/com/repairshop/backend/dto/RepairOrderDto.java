package com.repairshop.backend.dto;

import com.repairshop.backend.model.OrderStatus;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

public class RepairOrderDto {

    @Size(max = 64, message = "Order ID is too long")
    private String id;

    @NotNull(message = "Status is mandatory")
    private OrderStatus status;

    @NotNull(message = "Repair date is mandatory")
    private LocalDate repairDate;

    @NotNull(message = "Repair time is mandatory")
    private LocalTime repairTime;

    private boolean reminderEnabled;

    @NotBlank(message = "Customer name is mandatory")
    @Size(max = 255)
    private String customerName;

    @NotBlank(message = "Customer number is mandatory")
    @Size(max = 50)
    private String customerNumber;

    @Size(max = 500)
    private String customerAddress;

    @NotBlank(message = "Device problem is mandatory")
    @Size(max = 1000)
    private String deviceProblem;

    @NotNull(message = "Estimate price is mandatory")
    @DecimalMin(value = "0.00", message = "Estimate price cannot be negative")
    @Digits(integer = 10, fraction = 2)
    private BigDecimal estimatePrice;

    @NotNull(message = "Paid price is mandatory")
    @DecimalMin(value = "0.00", message = "Paid price cannot be negative")
    @Digits(integer = 10, fraction = 2)
    private BigDecimal paidPrice;

    @Size(max = 255)
    private String devicePassword;
    @Size(max = 255)
    private String devicePattern;
    @Size(max = 2000)
    private String description;

    // Accessories
    private boolean accessoriesSim;
    private boolean accessoriesSdCard;
    private boolean accessoriesBackCover;
    private boolean accessoriesCharger;

    // Notifications
    private boolean notifyWhatsapp;
    private boolean notifyEmail;

    private boolean deleted;

    private Instant createdAt;
    private Instant updatedAt;

    public RepairOrderDto() {
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public OrderStatus getStatus() {
        return status;
    }

    public void setStatus(OrderStatus status) {
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

    public boolean isDeleted() {
        return deleted;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
