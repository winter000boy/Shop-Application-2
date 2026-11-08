import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/security/device_secret_cipher.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/services/notification_service.dart';
import 'package:repair_shop_app/services/photo_store.dart';
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
  final String? alternateNumber;
  final String? brand;
  final String? model;
  final String? imei;
  final String deviceProblem;
  final DateTime? estimatedDelivery;
  final int estimatePriceMinor;
  final int paidPriceMinor;
  final String? devicePassword;
  final String? devicePattern;
  final String? description;
  final bool accessoriesSim;
  final bool accessoriesSdCard;
  final bool accessoriesBackCover;
  final bool accessoriesCharger;
  final bool accessoriesBattery;
  final String? accessoriesOther;
  final String? kycDocType;
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
    this.alternateNumber,
    this.brand,
    this.model,
    this.imei,
    required this.deviceProblem,
    this.estimatedDelivery,
    required this.estimatePriceMinor,
    required this.paidPriceMinor,
    required this.devicePassword,
    required this.devicePattern,
    required this.description,
    required this.accessoriesSim,
    required this.accessoriesSdCard,
    required this.accessoriesBackCover,
    required this.accessoriesCharger,
    this.accessoriesBattery = false,
    this.accessoriesOther,
    this.kycDocType,
    required this.notifyWhatsapp,
    required this.notifyEmail,
  });
}

/// Photos added and removed in the job card form. New paths point at the picker's temporary files.
class PhotoChanges {
  final List<String> newDevicePhotos;
  final List<String> newKycPhotos;
  final List<OrderPhoto> removed;

  const PhotoChanges({this.newDevicePhotos = const [], this.newKycPhotos = const [], this.removed = const []});
}

// Photos of one job card, oldest first
final orderPhotosProvider = StreamProvider.autoDispose.family<List<OrderPhoto>, String>((ref, orderId) {
  return ref.watch(databaseProvider).watchPhotos(orderId);
});

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
      alternateNumber: input.alternateNumber,
      brand: input.brand,
      model: input.model,
      imei: input.imei,
      deviceProblem: input.deviceProblem,
      estimatedDelivery: input.estimatedDelivery,
      estimatePriceMinor: input.estimatePriceMinor,
      paidPriceMinor: input.paidPriceMinor,
      devicePassword: keepSecrets ? _cipher.encrypt(input.devicePassword) : null,
      devicePattern: keepSecrets ? _cipher.encrypt(input.devicePattern) : null,
      description: input.description,
      accessoriesSim: input.accessoriesSim,
      accessoriesSdCard: input.accessoriesSdCard,
      accessoriesBackCover: input.accessoriesBackCover,
      accessoriesCharger: input.accessoriesCharger,
      accessoriesBattery: input.accessoriesBattery,
      accessoriesOther: input.accessoriesOther,
      kycDocType: input.kycDocType,
      notifyWhatsapp: input.notifyWhatsapp,
      notifyEmail: input.notifyEmail,
      syncStatus: syncStatus,
      localRevision: localRevision,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Saves a new job card and returns it (for the WhatsApp message).
  Future<Order> createOrder(OrderInput input, {PhotoChanges photos = const PhotoChanges()}) async {
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
    await _applyPhotoChanges(orderId, photos);

    // 2. Email notification (mock). WhatsApp is opened by the screen so the shop can review and send it.
    if (input.notifyEmail) {
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
    return order;
  }

  /// Saves changes to a job card and returns the updated row (null if it no longer exists).
  Future<Order?> updateOrder(String id, OrderInput input, {PhotoChanges photos = const PhotoChanges()}) async {
    final existing = await _db.getOrderById(id);
    if (existing == null) return null;

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
    await _applyPhotoChanges(id, photos);

    // 2. Email notification (mock) when the repair is done
    if (statusChangedToRepaired && input.notifyEmail) {
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
    return order;
  }

  /// Quick status change from the job list (keeps every other field as it is).
  Future<Order?> updateStatus(Order order, String status) async {
    final secrets = revealDeviceSecrets(order);
    return updateOrder(order.id, OrderInput(
      status: status,
      repairDate: order.repairDate,
      repairTime: order.repairTime,
      reminderEnabled: order.reminderEnabled,
      customerName: order.customerName,
      customerNumber: order.customerNumber,
      customerAddress: order.customerAddress,
      alternateNumber: order.alternateNumber,
      brand: order.brand,
      model: order.model,
      imei: order.imei,
      deviceProblem: order.deviceProblem,
      estimatedDelivery: order.estimatedDelivery,
      estimatePriceMinor: order.estimatePriceMinor,
      paidPriceMinor: order.paidPriceMinor,
      devicePassword: secrets.password,
      devicePattern: secrets.pattern,
      description: order.description,
      accessoriesSim: order.accessoriesSim,
      accessoriesSdCard: order.accessoriesSdCard,
      accessoriesBackCover: order.accessoriesBackCover,
      accessoriesCharger: order.accessoriesCharger,
      accessoriesBattery: order.accessoriesBattery,
      accessoriesOther: order.accessoriesOther,
      kycDocType: order.kycDocType,
      notifyWhatsapp: order.notifyWhatsapp,
      notifyEmail: order.notifyEmail,
    ));
  }

  Future<void> _applyPhotoChanges(String orderId, PhotoChanges changes) async {
    for (final photo in changes.removed) {
      await PhotoStore.delete(photo.filePath);
    }
    await _db.deletePhotosByIds(changes.removed.map((p) => p.id).toList());

    Future<void> add(List<String> paths, String kind) async {
      for (final source in paths) {
        final stored = await PhotoStore.persist(source);
        await _db.insertPhoto(OrderPhoto(
          id: _uuid.v4(),
          orderId: orderId,
          kind: kind,
          filePath: stored,
          createdAt: DateTime.now().toUtc(),
        ));
      }
    }

    await add(changes.newDevicePhotos, PhotoKind.device);
    await add(changes.newKycPhotos, PhotoKind.kyc);
  }

  Future<void> deleteOrder(String id) async {
    // 1. Mark as pending_delete or physical delete from SQLite
    await _db.softDeleteOrder(id);

    // Photos are only on this device; remove them with the job card
    final photos = await _db.getPhotos(id);
    for (final photo in photos) {
      await PhotoStore.delete(photo.filePath);
    }
    await _db.deletePhotosForOrder(id);

    // 2. Push to the server shortly
    _syncMgr.requestSync();
  }
}
