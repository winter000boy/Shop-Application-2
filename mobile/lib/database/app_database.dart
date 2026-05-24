import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

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
  RealColumn get estimatePrice => real()();
  RealColumn get paidPrice => real()();
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
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))(); // synced, pending_create, pending_update, pending_delete
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Orders])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Query Operations
  Future<List<Order>> getAllOrders() => select(orders).get();
  
  Stream<List<Order>> watchAllOrders() {
    return (select(orders)
      ..where((t) => t.syncStatus.isNotValue('pending_delete'))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
      .watch();
  }

  Stream<List<Order>> watchOrdersByStatus(String status) {
    return (select(orders)
      ..where((t) => t.status.equals(status) & t.syncStatus.isNotValue('pending_delete'))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
      .watch();
  }

  Stream<List<Order>> searchOrders(String query) {
    return (select(orders)
      ..where((t) => (t.customerName.like('%$query%') | t.customerNumber.like('%$query%')) & t.syncStatus.isNotValue('pending_delete'))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
      .watch();
  }

  Stream<List<Order>> searchOrdersByStatus(String status, String query) {
    return (select(orders)
      ..where((t) => t.status.equals(status) & (t.customerName.like('%$query%') | t.customerNumber.like('%$query%')) & t.syncStatus.isNotValue('pending_delete'))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
      .watch();
  }

  Future<Order?> getOrderById(String id) =>
      (select(orders)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Write Operations
  Future<int> insertOrder(Order order) => into(orders).insert(order, mode: InsertMode.insertOrReplace);

  Future<bool> updateOrder(Order order) => update(orders).replace(order);

  // Soft delete locally (mark as pending_delete) so the sync manager can notify the backend
  Future<void> softDeleteOrder(String id) async {
    final existing = await getOrderById(id);
    if (existing != null) {
      if (existing.syncStatus == 'pending_create') {
        // If it was created offline and never synced, we can physically delete it now!
        await (delete(orders)..where((t) => t.id.equals(id))).go();
      } else {
        // Otherwise, mark it as pending_delete so we sync the deletion to the server
        await (update(orders)..where((t) => t.id.equals(id))).write(
          const OrdersCompanion(
            syncStatus: Value('pending_delete'),
          ),
        );
      }
    }
  }

  Future<int> hardDeleteOrder(String id) =>
      (delete(orders)..where((t) => t.id.equals(id))).go();

  // Sync Operations
  Future<List<Order>> getUnsyncedOrders() =>
      (select(orders)..where((t) => t.syncStatus.isNotValue('synced'))).get();

  Future<void> markAsSynced(String id) =>
      (update(orders)..where((t) => t.id.equals(id))).write(
        const OrdersCompanion(syncStatus: Value('synced')),
      );

  Future<void> clearAll() => delete(orders).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'repair_shop.db'));
    return NativeDatabase.createInBackground(file);
  });
}
