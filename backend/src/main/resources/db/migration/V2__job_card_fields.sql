-- Job card details captured at the counter
ALTER TABLE repair_orders ADD COLUMN alternate_number VARCHAR(50);
ALTER TABLE repair_orders ADD COLUMN brand VARCHAR(100);
ALTER TABLE repair_orders ADD COLUMN model VARCHAR(100);
ALTER TABLE repair_orders ADD COLUMN imei VARCHAR(20);
ALTER TABLE repair_orders ADD COLUMN estimated_delivery DATE;
ALTER TABLE repair_orders ADD COLUMN accessories_battery BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE repair_orders ADD COLUMN accessories_other VARCHAR(255);
ALTER TABLE repair_orders ADD COLUMN kyc_doc_type VARCHAR(50);
