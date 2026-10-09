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

  // Device details
  TextColumn get deviceProblem => text()();
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

@DriftDatabase(tables: [Orders])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

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
          }
        },
      );

  Future<void> _createIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_orders_status_created ON orders (status, created_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_orders_sync_status ON orders (sync_status)');
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'repair_shop.db'));
    return NativeDatabase.createInBackground(file);
  });
}
