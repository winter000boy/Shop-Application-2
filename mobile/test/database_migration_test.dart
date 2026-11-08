import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_shop_app/database/app_database.dart';

/// Schema of the orders table as shipped in app version 1.0.x (database schemaVersion 2).
const _v2Orders = '''
CREATE TABLE orders (
  id TEXT NOT NULL PRIMARY KEY, status TEXT NOT NULL, repair_date INTEGER NOT NULL, repair_time TEXT NOT NULL,
  reminder_enabled INTEGER NOT NULL DEFAULT 0, customer_name TEXT NOT NULL, customer_number TEXT NOT NULL,
  customer_address TEXT, device_problem TEXT NOT NULL, estimate_price_minor INTEGER NOT NULL,
  paid_price_minor INTEGER NOT NULL, device_password TEXT, device_pattern TEXT, description TEXT,
  accessories_sim INTEGER NOT NULL DEFAULT 0, accessories_sd_card INTEGER NOT NULL DEFAULT 0,
  accessories_back_cover INTEGER NOT NULL DEFAULT 0, accessories_charger INTEGER NOT NULL DEFAULT 0,
  notify_whatsapp INTEGER NOT NULL DEFAULT 0, notify_email INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'synced', local_revision INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
)''';

void main() {
  test('upgrading from schema v2 keeps existing orders and adds job card fields', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute(_v2Orders);
      raw.execute('''INSERT INTO orders (id, status, repair_date, repair_time, customer_name, customer_number,
          device_problem, estimate_price_minor, paid_price_minor, created_at, updated_at)
          VALUES ('existing', 'PENDING', 1759800000, '10:30', 'Ravi', '9876543210', 'Screen', 150000, 0,
          1759800000, 1759800000)''');
      raw.userVersion = 2;
    }));

    final order = await db.getOrderById('existing');
    expect(order, isNotNull);
    expect(order!.customerName, 'Ravi');
    expect(order.brand, isNull);
    expect(order.accessoriesBattery, isFalse);

    // New tables are usable
    expect(await db.getPhotos('existing'), isEmpty);
    expect(await db.watchOffers().first, isEmpty);
    await db.close();
  });
}
