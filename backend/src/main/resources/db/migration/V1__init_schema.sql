-- =========================================================================
-- FixManager schema (PostgreSQL; also runs on H2 in PostgreSQL mode for dev/tests)
-- Owned by Flyway: never edit an applied migration, add V2__..., V3__... instead.
-- =========================================================================

CREATE TABLE shops (
    id UUID PRIMARY KEY,
    shop_name VARCHAR(255) NOT NULL,
    shop_type VARCHAR(100) NOT NULL,
    gst_number VARCHAR(100),
    owner_name VARCHAR(255) NOT NULL,
    username VARCHAR(150) NOT NULL UNIQUE,
    mobile_number VARCHAR(30) NOT NULL,
    country_code VARCHAR(10) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- BCrypt hash
    currency_symbol VARCHAR(10) NOT NULL,
    address VARCHAR(500),
    logo_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- One row per signed-in device. Only the SHA-256 hash of the token is stored.
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    shop_id UUID NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_refresh_tokens_shop FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
);

CREATE INDEX idx_refresh_tokens_shop ON refresh_tokens(shop_id);

-- Short-lived one-time codes for "forgot password". Only a BCrypt hash of the code is stored.
CREATE TABLE password_reset_codes (
    id UUID PRIMARY KEY,
    shop_id UUID NOT NULL,
    code_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_password_reset_codes_shop FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
);

CREATE INDEX idx_password_reset_codes_shop ON password_reset_codes(shop_id);

CREATE TABLE repair_orders (
    id VARCHAR(64) PRIMARY KEY, -- client-generated UUID string
    shop_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL, -- PENDING, REPAIRED, DELIVERED, CANCELLED
    repair_date DATE NOT NULL,
    repair_time TIME NOT NULL,
    reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    customer_name VARCHAR(255) NOT NULL,
    customer_number VARCHAR(50) NOT NULL,
    customer_address VARCHAR(500),
    device_problem VARCHAR(1000) NOT NULL,
    estimate_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    paid_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    device_password VARCHAR(512), -- AES-GCM ciphertext
    device_pattern VARCHAR(512),  -- AES-GCM ciphertext
    description VARCHAR(2000),
    accessories_sim BOOLEAN NOT NULL DEFAULT FALSE,
    accessories_sd_card BOOLEAN NOT NULL DEFAULT FALSE,
    accessories_back_cover BOOLEAN NOT NULL DEFAULT FALSE,
    accessories_charger BOOLEAN NOT NULL DEFAULT FALSE,
    notify_whatsapp BOOLEAN NOT NULL DEFAULT FALSE,
    notify_email BOOLEAN NOT NULL DEFAULT FALSE,
    deleted BOOLEAN NOT NULL DEFAULT FALSE, -- tombstone so deletions reach every device
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,         -- when the order was last edited (client clock, UTC)
    server_modified_at TIMESTAMP WITH TIME ZONE NOT NULL, -- when the server last wrote the row (sync cursor)
    CONSTRAINT fk_repair_orders_shop FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
);

-- Order lists: tenant + status, newest first
CREATE INDEX idx_repair_orders_shop_status_created ON repair_orders(shop_id, status, created_at);
CREATE INDEX idx_repair_orders_shop_created ON repair_orders(shop_id, created_at);
-- Delta sync: "what changed in my shop since X"
CREATE INDEX idx_repair_orders_shop_server_modified ON repair_orders(shop_id, server_modified_at);
