import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class OrderStatus {
  static const String pending = 'PENDING';
  static const String repaired = 'REPAIRED';
  static const String delivered = 'DELIVERED';
  static const String cancelled = 'CANCELLED';

  static const List<String> values = [pending, repaired, delivered, cancelled];

  /// The device has been handed back, so its unlock secrets are no longer needed.
  static bool isDeviceReturned(String status) => status == delivered || status == cancelled;
}

class SyncStatus {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';
}

class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get status => text()(); // PENDING, REPAIRED, DELIVERED, CANCELLED
  DateTimeColumn get repairDate => dateTime()();
  TextColumn get repairTime => text()();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();

  // Customer details
  TextColumn get customerName => text()();
  TextColumn get customerNumber => text()();
  TextColumn get customerAddress => text().nullable()();
  // Second contact number (family member, office...)
  TextColumn get alternateNumber => text().nullable()();

  // Device details
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get imei => text().nullable()();
  TextColumn get deviceProblem => text()();
  DateTimeColumn get estimatedDelivery => dateTime().nullable()();
  // Money in minor units (paise/cents), never floating point
  IntColumn get estimatePriceMinor => integer()();
  IntColumn get paidPriceMinor => integer()();
  // Encrypted with DeviceSecretCipher
  TextColumn get devicePassword => text().nullable()();
  TextColumn get devicePattern => text().nullable()();
  TextColumn get description => text().nullable()();

  // Accessories Checklist
  BoolColumn get accessoriesSim => boolean().withDefault(const Constant(false))();
  BoolColumn get accessoriesSdCard => boolean().withDefault(const Constant(false))();
  BoolColumn get accessoriesBackCover => boolean().withDefault(const Constant(false))();
  BoolColumn get accessoriesCharger => boolean().withDefault(const Constant(false))();
  BoolColumn get accessoriesBattery => boolean().withDefault(const Constant(false))();
  // Anything else handed over (earphones, box, cable...)
  TextColumn get accessoriesOther => text().nullable()();

  // Which ID the customer showed (Aadhaar, PAN...). The photo itself stays on this device (OrderPhotos).
  TextColumn get kycDocType => text().nullable()();

  // Notifications
  BoolColumn get notifyWhatsapp => boolean().withDefault(const Constant(false))();
  BoolColumn get notifyEmail => boolean().withDefault(const Constant(false))();

  // Offline Sync columns
  TextColumn get syncStatus => text().withDefault(const Constant(SyncStatus.synced))();
  // Bumped on every local edit so a sync can tell whether a row changed while its request was in flight
  IntColumn get localRevision => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PhotoKind {
  static const String device = 'device';
  static const String kyc = 'kyc';
}

/// Photos of the customer's device and KYC documents. Device-local only: files live in the app's private
/// documents directory and are not uploaded to the server.
class OrderPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get kind => text()(); // PhotoKind
  TextColumn get filePath => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shop offers and promotions (device-local).
class Offers extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get details => text().nullable()();
  TextColumn get discount => text().nullable()(); // free text: "10% off", "₹200 off", "Free tempered glass"
  DateTimeColumn get validTill => dateTime().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Orders, OrderPhotos, Offers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 builds never compiled, so no real data can exist in a v1 database: rebuild it.
            // The next sync performs a full download (the cursor is reset by the caller on login).
            await m.deleteTable(orders.actualTableName);
            await m.createAll();
            await _createIndexes();
            return; // createAll already built the v3 tables
          }
          if (from < 3) {
            // Job card fields
            await m.addColumn(orders, orders.alternateNumber);
            await m.addColumn(orders, orders.brand);
            await m.addColumn(orders, orders.model);
            await m.addColumn(orders, orders.imei);
            await m.addColumn(orders, orders.estimatedDelivery);
            await m.addColumn(orders, orders.accessoriesBattery);
            await m.addColumn(orders, orders.accessoriesOther);
            await m.addColumn(orders, orders.kycDocType);
            await m.createTable(orderPhotos);
            await m.createTable(offers);
            await _createIndexes();
          }
        },
      );

  Future<void> _createIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_orders_status_created ON orders (status, created_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_orders_sync_status ON orders (sync_status)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_order_photos_order ON order_photos (order_id)');
  }

  // Query Operations

  /// Live list of visible orders, newest first, optionally filtered by status and a name/phone search.
  Stream<List<Order>> watchOrders({String? status, String searchQuery = ''}) {
    final query = select(orders)
      ..where((t) {
        Expression<bool> condition = t.syncStatus.equals(SyncStatus.pendingDelete).not();
        if (status != null) {
          condition = condition & t.status.equals(status);
        }
        if (searchQuery.isNotEmpty) {
          final pattern = '%${_escapeLike(searchQuery)}%';
          condition = condition &
              (t.customerName.like(pattern, escapeChar: r'\') | t.customerNumber.like(pattern, escapeChar: r'\'));
        }
        return condition;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.watch();
  }

  static String _escapeLike(String input) =>
      input.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  Future<Order?> getOrderById(String id) =>
      (select(orders)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Write Operations
  Future<int> insertOrder(Order order) => into(orders).insert(order, mode: InsertMode.insertOrReplace);

  Future<bool> updateOrder(Order order) => update(orders).replace(order);

  // Soft delete locally (mark as pending_delete) so the sync manager can notify the backend
  Future<void> softDeleteOrder(String id) async {
    final existing = await getOrderById(id);
    if (existing != null) {
      if (existing.syncStatus == SyncStatus.pendingCreate) {
        // If it was created offline and never synced, we can physically delete it now!
        await (delete(orders)..where((t) => t.id.equals(id))).go();
      } else {
        // Otherwise, mark it as pending_delete so we sync the deletion to the server
        await (update(orders)..where((t) => t.id.equals(id))).write(
          OrdersCompanion(
            syncStatus: const Value(SyncStatus.pendingDelete),
            devicePassword: const Value(null),
            devicePattern: const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
            localRevision: Value(existing.localRevision + 1),
          ),
        );
      }
    }
  }

  // Sync Operations

  Future<List<Order>> getUnsyncedOrders({int limit = 200}) =>
      (select(orders)
            ..where((t) => t.syncStatus.equals(SyncStatus.synced).not())
            ..orderBy([(t) => OrderingTerm(expression: t.updatedAt)])
            ..limit(limit))
          .get();

  Future<int> countUnsyncedOrders() async {
    final count = orders.id.count();
    final query = selectOnly(orders)
      ..addColumns([count])
      ..where(orders.syncStatus.equals(SyncStatus.synced).not());
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// Marks pushed rows as synced, but only if the user didn't edit them again while the request was in flight.
  Future<void> markPushedAsSynced(List<Order> pushed) async {
    await batch((b) {
      for (final order in pushed) {
        b.update(
          orders,
          const OrdersCompanion(syncStatus: Value(SyncStatus.synced)),
          where: (t) => t.id.equals(order.id) & t.localRevision.equals(order.localRevision),
        );
      }
    });
  }

  /// Removes rows whose deletion the server has accepted (unless they were somehow edited again meanwhile).
  Future<void> purgeDeleted(List<String> ids) async {
    if (ids.isEmpty) return;
    await (delete(orders)..where((t) => t.id.isIn(ids) & t.syncStatus.equals(SyncStatus.pendingDelete))).go();
  }

  /// Applies changes pulled from the server. Rows with local edits that haven't been pushed yet are kept;
  /// they go up on the next sync and the server resolves the conflict.
  Future<void> applyServerChanges({required List<Order> upserts, required List<String> deletedIds}) async {
    await transaction(() async {
      if (deletedIds.isNotEmpty) {
        await (delete(orders)..where((t) => t.id.isIn(deletedIds))).go();
      }
      if (upserts.isEmpty) return;

      final ids = upserts.map((o) => o.id).toList();
      final locallyModified = await (selectOnly(orders)
            ..addColumns([orders.id])
            ..where(orders.id.isIn(ids) & orders.syncStatus.equals(SyncStatus.synced).not()))
          .map((row) => row.read(orders.id)!)
          .get();
      final skip = locallyModified.toSet();

      await batch((b) {
        b.insertAll(
          orders,
          upserts.where((o) => !skip.contains(o.id)).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<void> clearAll() => delete(orders).go();

  // Photos

  Stream<List<OrderPhoto>> watchPhotos(String orderId) => (select(orderPhotos)
        ..where((t) => t.orderId.equals(orderId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
      .watch();

  Future<List<OrderPhoto>> getPhotos(String orderId) =>
      (select(orderPhotos)..where((t) => t.orderId.equals(orderId))).get();

  Future<List<OrderPhoto>> getAllPhotos() => select(orderPhotos).get();

  Future<void> insertPhoto(OrderPhoto photo) => into(orderPhotos).insert(photo);

  Future<void> deletePhotosByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    await (delete(orderPhotos)..where((t) => t.id.isIn(ids))).go();
  }

  Future<void> deletePhotosForOrder(String orderId) =>
      (delete(orderPhotos)..where((t) => t.orderId.equals(orderId))).go();

  /// Number of device photos per order, for the photo badge on job cards.
  Stream<Map<String, int>> watchDevicePhotoCounts() {
    final count = orderPhotos.id.count();
    final query = selectOnly(orderPhotos)
      ..addColumns([orderPhotos.orderId, count])
      ..where(orderPhotos.kind.equals(PhotoKind.device))
      ..groupBy([orderPhotos.orderId]);
    return query.watch().map((rows) => {for (final r in rows) r.read(orderPhotos.orderId)!: r.read(count) ?? 0});
  }

  // Offers

  Stream<List<Offer>> watchOffers() =>
      (select(offers)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();

  Future<void> upsertOffer(Offer offer) => into(offers).insert(offer, mode: InsertMode.insertOrReplace);

  Future<void> deleteOffer(String id) => (delete(offers)..where((t) => t.id.equals(id))).go();

  /// Removes everything belonging to the signed-in shop (explicit sign-out or a different shop signing in).
  Future<void> clearAllShopData() async {
    await transaction(() async {
      await delete(orders).go();
      await delete(orderPhotos).go();
      await delete(offers).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'repair_shop.db'));
    return NativeDatabase.createInBackground(file);
  });
}
