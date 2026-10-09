import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/security/device_secret_cipher.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/services/notification_service.dart';
import 'package:repair_shop_app/services/sync_manager.dart';
import 'package:repair_shop_app/shared/providers.dart';
import 'package:uuid/uuid.dart';

class OrderFilter {
  static const String all = 'All';

  final String status; // 'All', 'PENDING', 'REPAIRED', 'DELIVERED', 'CANCELLED'
  final String searchQuery;

  const OrderFilter({this.status = all, this.searchQuery = ''});

  OrderFilter copyWith({String? status, String? searchQuery}) {
    return OrderFilter(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Value equality so the family provider below reuses one stream per distinct filter
  @override
  bool operator ==(Object other) =>
      other is OrderFilter && other.status == status && other.searchQuery == searchQuery;

  @override
  int get hashCode => Object.hash(status, searchQuery);
}

// Reactive Provider that streams lists of orders from Drift based on active filters.
// autoDispose: the database query stops when no screen is listening for that filter.
final ordersStreamProvider = StreamProvider.autoDispose.family<List<Order>, OrderFilter>((ref, filter) {
  final db = ref.watch(databaseProvider);
  return db.watchOrders(
    status: filter.status == OrderFilter.all ? null : filter.status,
    searchQuery: filter.searchQuery,
  );
});

/// Everything the order form captures. Amounts are in minor units; secrets are plaintext here.
class OrderInput {
  final String status;
  final DateTime repairDate;
  final String repairTime;
  final bool reminderEnabled;
  final String customerName;
  final String customerNumber;
  final String? customerAddress;
  final String deviceProblem;
  final int estimatePriceMinor;
  final int paidPriceMinor;
  final String? devicePassword;
  final String? devicePattern;
  final String? description;
  final bool accessoriesSim;
  final bool accessoriesSdCard;
  final bool accessoriesBackCover;
  final bool accessoriesCharger;
  final bool notifyWhatsapp;
  final bool notifyEmail;

  const OrderInput({
    required this.status,
    required this.repairDate,
    required this.repairTime,
    required this.reminderEnabled,
    required this.customerName,
    required this.customerNumber,
    required this.customerAddress,
    required this.deviceProblem,
    required this.estimatePriceMinor,
    required this.paidPriceMinor,
    required this.devicePassword,
    required this.devicePattern,
    required this.description,
    required this.accessoriesSim,
    required this.accessoriesSdCard,
    required this.accessoriesBackCover,
    required this.accessoriesCharger,
    required this.notifyWhatsapp,
    required this.notifyEmail,
  });
}

// Provider to manage CRUD operations
final ordersOperationsProvider = Provider((ref) {
  return OrdersOperations(
    ref.watch(databaseProvider),
    ref.watch(syncManagerProvider),
    ref.watch(notificationProvider),
    ref.watch(deviceSecretCipherProvider),
  );
});

class OrdersOperations {
  final AppDatabase _db;
  final _uuid = const Uuid();
  final SyncManager _syncMgr;
  final NotificationProvider _notify;
  final DeviceSecretCipher _cipher;

  OrdersOperations(this._db, this._syncMgr, this._notify, this._cipher);

  /// Decrypted device passcode and pattern for showing in the edit form.
  ({String? password, String? pattern}) revealDeviceSecrets(Order order) =>
      (password: _cipher.decrypt(order.devicePassword), pattern: _cipher.decrypt(order.devicePattern));

  Order _buildOrder({
    required String id,
    required OrderInput input,
    required String syncStatus,
    required int localRevision,
    required DateTime createdAt,
  }) {
    // Once the device has been handed back there's no reason to keep the customer's unlock secrets
    final bool keepSecrets = !OrderStatus.isDeviceReturned(input.status);
    return Order(
      id: id,
      status: input.status,
      repairDate: input.repairDate,
      repairTime: input.repairTime,
      reminderEnabled: input.reminderEnabled,
      customerName: input.customerName,
      customerNumber: input.customerNumber,
      customerAddress: input.customerAddress,
      deviceProblem: input.deviceProblem,
      estimatePriceMinor: input.estimatePriceMinor,
      paidPriceMinor: input.paidPriceMinor,
      devicePassword: keepSecrets ? _cipher.encrypt(input.devicePassword) : null,
      devicePattern: keepSecrets ? _cipher.encrypt(input.devicePattern) : null,
      description: input.description,
      accessoriesSim: input.accessoriesSim,
      accessoriesSdCard: input.accessoriesSdCard,
      accessoriesBackCover: input.accessoriesBackCover,
      accessoriesCharger: input.accessoriesCharger,
      notifyWhatsapp: input.notifyWhatsapp,
      notifyEmail: input.notifyEmail,
      syncStatus: syncStatus,
      localRevision: localRevision,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> createOrder(OrderInput input) async {
    final String orderId = _uuid.v4();
    final order = _buildOrder(
      id: orderId,
      input: input,
      syncStatus: SyncStatus.pendingCreate,
      localRevision: 0,
      createdAt: DateTime.now().toUtc(),
    );

    // 1. Save locally in SQLite
    await _db.insertOrder(order);

    // 2. Mock sending notification if toggled
    if (input.notifyWhatsapp || input.notifyEmail) {
      await _notify.sendOrderReceived(
        customerName: input.customerName,
        customerNumber: input.customerNumber,
        orderId: orderId.substring(0, 8).toUpperCase(),
        estimatePriceMinor: input.estimatePriceMinor,
        currency: LocalCache.getCurrencySymbol(),
      );
    }

    // 3. Push to the server shortly (coalesces rapid edits; works offline-first)
    _syncMgr.requestSync();
  }

  Future<void> updateOrder(String id, OrderInput input) async {
    final existing = await _db.getOrderById(id);
    if (existing == null) return;

    // Check if status changed to REPAIRED to trigger completion notification
    final bool statusChangedToRepaired =
        existing.status != OrderStatus.repaired && input.status == OrderStatus.repaired;

    final order = _buildOrder(
      id: id,
      input: input,
      // If it was never pushed, keep it as pending_create
      syncStatus: existing.syncStatus == SyncStatus.pendingCreate ? SyncStatus.pendingCreate : SyncStatus.pendingUpdate,
      localRevision: existing.localRevision + 1,
      createdAt: existing.createdAt,
    );

    // 1. Update locally in SQLite
    await _db.updateOrder(order);

    // 2. Mock sending completed notification if status updated
    if (statusChangedToRepaired && (input.notifyWhatsapp || input.notifyEmail)) {
      await _notify.sendRepairCompleted(
        customerName: input.customerName,
        customerNumber: input.customerNumber,
        orderId: id.substring(0, 8).toUpperCase(),
        estimatePriceMinor: input.estimatePriceMinor,
        currency: LocalCache.getCurrencySymbol(),
      );
    }

    // 3. Push to the server shortly
    _syncMgr.requestSync();
  }

  Future<void> deleteOrder(String id) async {
    // 1. Mark as pending_delete or physical delete from SQLite
    await _db.softDeleteOrder(id);

    // 2. Push to the server shortly
    _syncMgr.requestSync();
  }
}
