import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/services/notification_service.dart';
import 'package:repair_shop_app/shared/providers.dart';
import 'package:uuid/uuid.dart';

class OrderFilter {
  final String status; // 'All', 'PENDING', 'REPAIRED', 'DELIVERED', 'CANCELLED'
  final String searchQuery;

  OrderFilter({this.status = 'All', this.searchQuery = ''});

  OrderFilter copyWith({String? status, String? searchQuery}) {
    return OrderFilter(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Reactive Provider that streams lists of orders from Drift based on active filters
final ordersStreamProvider = StreamProvider.family<List<Order>, OrderFilter>((ref, filter) {
  final db = ref.watch(databaseProvider);
  
  final status = filter.status;
  final query = filter.searchQuery;

  if (status == 'All') {
    if (query.isEmpty) {
      return db.watchAllOrders();
    } else {
      return db.searchOrders(query);
    }
  } else {
    if (query.isEmpty) {
      return db.watchOrdersByStatus(status);
    } else {
      return db.searchOrdersByStatus(status, query);
    }
  }
});

// Provider to manage CRUD operations
final ordersOperationsProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  final syncMgr = ref.watch(syncManagerProvider);
  final notify = ref.watch(notificationProvider);

  return OrdersOperations(db, syncMgr, notify);
});

class OrdersOperations {
  final AppDatabase _db;
  final _uuid = const Uuid();
  final _syncMgr;
  final NotificationProvider _notify;

  OrdersOperations(this._db, this._syncMgr, this._notify);

  Future<void> createOrder({
    required String status,
    required DateTime repairDate,
    required String repairTime,
    required bool reminderEnabled,
    required String customerName,
    required String customerNumber,
    required String? customerAddress,
    required String deviceProblem,
    required double estimatePrice,
    required double paidPrice,
    required String? devicePassword,
    required String? devicePattern,
    required String? description,
    required bool accessoriesSim,
    required bool accessoriesSdCard,
    required bool accessoriesBackCover,
    required bool accessoriesCharger,
    required bool notifyWhatsapp,
    required bool notifyEmail,
  }) async {
    final String orderId = _uuid.v4();
    final now = DateTime.now();

    final order = Order(
      id: orderId,
      status: status,
      repairDate: repairDate,
      repairTime: repairTime,
      reminderEnabled: reminderEnabled,
      customerName: customerName,
      customerNumber: customerNumber,
      customerAddress: customerAddress,
      deviceProblem: deviceProblem,
      estimatePrice: estimatePrice,
      paidPrice: paidPrice,
      devicePassword: devicePassword,
      devicePattern: devicePattern,
      description: description,
      accessoriesSim: accessoriesSim,
      accessoriesSdCard: accessoriesSdCard,
      accessoriesBackCover: accessoriesBackCover,
      accessoriesCharger: accessoriesCharger,
      notifyWhatsapp: notifyWhatsapp,
      notifyEmail: notifyEmail,
      syncStatus: 'pending_create',
      createdAt: now,
      updatedAt: now,
    );

    // 1. Save locally in SQLite
    await _db.insertOrder(order);

    // 2. Mock sending notification if toggled
    if (notifyWhatsapp || notifyEmail) {
      final currency = LocalCache.getCurrencySymbol();
      await _notify.sendOrderReceived(
        customerName: customerName,
        customerNumber: customerNumber,
        orderId: orderId.substring(0, 8).toUpperCase(),
        estimatePrice: estimatePrice,
        currency: currency,
      );
    }

    // 3. Trigger server sync in background (fire and forget)
    _syncMgr.triggerSync();
  }

  Future<void> updateOrder({
    required String id,
    required String status,
    required DateTime repairDate,
    required String repairTime,
    required bool reminderEnabled,
    required String customerName,
    required String customerNumber,
    required String? customerAddress,
    required String deviceProblem,
    required double estimatePrice,
    required double paidPrice,
    required String? devicePassword,
    required String? devicePattern,
    required String? description,
    required bool accessoriesSim,
    required bool accessoriesSdCard,
    required bool accessoriesBackCover,
    required bool accessoriesCharger,
    required bool notifyWhatsapp,
    required bool notifyEmail,
    required DateTime createdAt,
  }) async {
    final existing = await _db.getOrderById(id);
    if (existing == null) return;

    // Check if status changed to REPAIRED to trigger completion notification
    final bool statusChangedToRepaired = (existing.status != 'REPAIRED' && status == 'REPAIRED');

    final now = DateTime.now();
    final order = Order(
      id: id,
      status: status,
      repairDate: repairDate,
      repairTime: repairTime,
      reminderEnabled: reminderEnabled,
      customerName: customerName,
      customerNumber: customerNumber,
      customerAddress: customerAddress,
      deviceProblem: deviceProblem,
      estimatePrice: estimatePrice,
      paidPrice: paidPrice,
      devicePassword: devicePassword,
      devicePattern: devicePattern,
      description: description,
      accessoriesSim: accessoriesSim,
      accessoriesSdCard: accessoriesSdCard,
      accessoriesBackCover: accessoriesBackCover,
      accessoriesCharger: accessoriesCharger,
      notifyWhatsapp: notifyWhatsapp,
      notifyEmail: notifyEmail,
      // If it was already pending_create, keep it as pending_create so we post it first!
      syncStatus: existing.syncStatus == 'pending_create' ? 'pending_create' : 'pending_update',
      createdAt: createdAt,
      updatedAt: now,
    );

    // 1. Update locally in SQLite
    await _db.updateOrder(order);

    // 2. Mock sending completed notification if status updated
    if (statusChangedToRepaired && (notifyWhatsapp || notifyEmail)) {
      final currency = LocalCache.getCurrencySymbol();
      await _notify.sendRepairCompleted(
        customerName: customerName,
        customerNumber: customerNumber,
        orderId: id.substring(0, 8).toUpperCase(),
        estimatePrice: estimatePrice,
        currency: currency,
      );
    }

    // 3. Trigger server sync in background
    _syncMgr.triggerSync();
  }

  Future<void> deleteOrder(String id) async {
    // 1. Mark as pending_delete or physical delete from SQLite
    await _db.softDeleteOrder(id);

    // 2. Trigger server sync in background
    _syncMgr.triggerSync();
  }
}
