-- =========================================================================
-- FixManager Database Schema (PostgreSQL)
-- Phase 1 - Authentication, Shop Onboarding & Repair Order Management
-- =========================================================================

-- Enable UUID extension if not already present
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -------------------------------------------------------------------------
-- 1. Shops Table (Core tenant configuration)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_name VARCHAR(255) NOT NULL,
    shop_type VARCHAR(100) NOT NULL,
    gst_number VARCHAR(100),
    owner_name VARCHAR(255) NOT NULL,
    username VARCHAR(150) UNIQUE NOT NULL,
    mobile_number VARCHAR(30) NOT NULL,
    country_code VARCHAR(10) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- BCrypt Hash
    currency_symbol VARCHAR(10) NOT NULL DEFAULT '₹',
    address VARCHAR(500),
    logo_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------------------------
-- 2. Refresh Tokens Table (Persisted user sessions)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token VARCHAR(255) UNIQUE NOT NULL,
    shop_id UUID NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_refresh_tokens_shop FOREIGN KEY (shop_id) 
        REFERENCES shops(id) ON DELETE CASCADE
);

-- -------------------------------------------------------------------------
-- 3. Repair Orders Table (Isolated by Shop tenant)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS repair_orders (
    id VARCHAR(255) PRIMARY KEY, -- Client-generated UUID string
    shop_id UUID NOT NULL,
    status VARCHAR(50) NOT NULL, -- PENDING, REPAIRED, DELIVERED, CANCELLED
    repair_date DATE NOT NULL,
    repair_time TIME NOT NULL,
    reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    customer_name VARCHAR(255) NOT NULL,
    customer_number VARCHAR(50) NOT NULL,
    customer_address VARCHAR(500),
    device_problem VARCHAR(1000) NOT NULL,
    estimate_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    paid_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    device_password VARCHAR(255),
    device_pattern VARCHAR(255),
    description VARCHAR(2000),
    accessories_sim BOOLEAN NOT NULL DEFAULT FALSE,
    accessories_sd_card BOOLEAN NOT NULL DEFAULT FALSE,
    accessories_back_cover BOOLEAN NOT NULL DEFAULT FALSE,
    accessories_charger BOOLEAN NOT NULL DEFAULT FALSE,
    notify_whatsapp BOOLEAN NOT NULL DEFAULT FALSE,
    notify_email BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_repair_orders_shop FOREIGN KEY (shop_id) 
        REFERENCES shops(id) ON DELETE CASCADE
);

-- -------------------------------------------------------------------------
-- 4. High-Performance Search Indexes
-- -------------------------------------------------------------------------

-- Speed up tenant separation on repair orders
CREATE INDEX IF NOT EXISTS idx_repair_orders_shop ON repair_orders(shop_id);

-- Speed up status filtering (Tabs: Pending, Repaired, etc.)
CREATE INDEX IF NOT EXISTS idx_repair_orders_status ON repair_orders(status);

-- Speed up search by customer name/phone within a shop
CREATE INDEX IF NOT EXISTS idx_repair_orders_search ON repair_orders(shop_id, customer_name, customer_number);

-- Speed up token verification queries
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
