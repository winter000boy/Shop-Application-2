package com.repairshop.backend.model;

import com.repairshop.backend.security.EncryptedStringConverter;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.domain.Persistable;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;

@Entity
@Table(name = "repair_orders")
public class RepairOrder implements Persistable<String> {

    @Id
    @Column(nullable = false, length = 64)
    private String id; // String ID to allow client-side generated UUIDs

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", referencedColumnName = "id", nullable = false)
    private Shop shop;

    @NotNull
    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, length = 20)
    private OrderStatus status;

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
    @Column(name = "customer_number", nullable = false, length = 50)
    private String customerNumber;

    @Column(name = "customer_address", length = 500)
    private String customerAddress;

    @NotBlank
    @Column(name = "device_problem", length = 1000, nullable = false)
    private String deviceProblem;

    @NotNull
    @Column(name = "estimate_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal estimatePrice;

    @NotNull
    @Column(name = "paid_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal paidPrice;

    // Customer device unlock secrets are encrypted at rest (AES-GCM)
    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "device_password", length = 512)
    private String devicePassword;

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "device_pattern", length = 512)
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

    // Tombstone: deleted orders are kept so the deletion can be synced to every device
    @Column(nullable = false)
    private boolean deleted;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    // When the order content was last edited (used for last-write-wins conflict resolution)
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    // When the server last wrote this row (used as the delta-sync cursor; always server clock)
    @Column(name = "server_modified_at", nullable = false)
    private Instant serverModifiedAt;

    // IDs are assigned by the client, so Spring Data can't infer "new" from a null ID. Without this,
    // save() would merge (an extra SELECT per order) instead of a plain INSERT.
    @Transient
    private boolean isNew = true;

    public RepairOrder() {
    }

    @Override
    public boolean isNew() {
        return isNew;
    }

    @PostLoad
    @PostPersist
    protected void markNotNew() {
        isNew = false;
    }

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now().truncatedTo(ChronoUnit.MILLIS);
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
        serverModifiedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        serverModifiedAt = Instant.now().truncatedTo(ChronoUnit.MILLIS);
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

    public Instant getServerModifiedAt() {
        return serverModifiedAt;
    }
}
