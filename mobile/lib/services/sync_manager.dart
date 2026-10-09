import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:repair_shop_app/core/money.dart';
import 'package:repair_shop_app/core/network/api_client.dart';
import 'package:repair_shop_app/core/security/device_secret_cipher.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';

/// Bi-directional sync between the local SQLite cache and the backend.
///
/// Push: every row whose syncStatus isn't `synced` (creates, edits, deletions).
/// Pull: everything the server changed since the last sync cursor, including tombstones for deletions.
/// Conflicts are resolved on the server (last edit wins); local edits made while a sync is in flight are kept.
class SyncManager {
  static const int _batchSize = 200;
  static const int _maxRoundsPerSync = 10;
  static const Duration _periodicInterval = Duration(minutes: 5);
  static const Duration _debounce = Duration(seconds: 2);

  final AppDatabase _db;
  final ApiClient _api;
  final DeviceSecretCipher _cipher;

  Future<bool>? _inFlight;
  bool _rerunRequested = false;
  bool _lastBatchWasFull = false;

  Timer? _periodicTimer;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  AppLifecycleListener? _lifecycleListener;

  SyncManager(this._db, this._api, this._cipher);

  bool get isSyncing => _inFlight != null;

  /// Starts automatic syncing: now, when the app returns to the foreground, when the network comes back,
  /// and every few minutes while the app is open.
  void startAutoSync() {
    stopAutoSync();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) triggerSync();
    });
    _lifecycleListener = AppLifecycleListener(onResume: triggerSync);
    _periodicTimer = Timer.periodic(_periodicInterval, (_) => triggerSync());
    triggerSync();
  }

  void stopAutoSync() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Schedules a sync shortly after local edits, coalescing bursts of changes into one request.
  void requestSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, triggerSync);
  }

  /// Runs a sync now. If one is already running, another round runs right after it so nothing edited
  /// in the meantime is left behind. Returns whether the sync this call waited for succeeded.
  Future<bool> triggerSync() {
    final inFlight = _inFlight;
    if (inFlight != null) {
      _rerunRequested = true;
      return inFlight;
    }
    return _inFlight = _runSyncLoop().whenComplete(() => _inFlight = null);
  }

  Future<bool> _runSyncLoop() async {
    bool success = true;
    var rounds = 0;
    do {
      _rerunRequested = false;
      success = await _syncOnce();
      rounds++;
      // Keep going while there is more queued (large backlog) or edits were made during the request
    } while (success && (_rerunRequested || _lastBatchWasFull) && rounds < _maxRoundsPerSync);
    return success;
  }

  Future<bool> _syncOnce() async {
    if (!LocalCache.isAuthenticated()) return false;

    try {
      // 1. Collect local changes that the server hasn't seen yet
      final List<Order> localUnsynced = await _db.getUnsyncedOrders(limit: _batchSize);
      _lastBatchWasFull = localUnsynced.length == _batchSize;
      final List<Order> localModified =
          localUnsynced.where((o) => o.syncStatus != SyncStatus.pendingDelete).toList();
      final List<String> deletedIds =
          localUnsynced.where((o) => o.syncStatus == SyncStatus.pendingDelete).map((o) => o.id).toList();

      final Map<String, dynamic> syncPayload = {
        'lastSyncTime': LocalCache.getLastSyncTime()?.toIso8601String(),
        'localOrders': localModified.map((o) => orderToJson(o, _cipher)).toList(),
        'deletedOrderIds': deletedIds,
      };

      // 2. Push local changes and pull server changes in one round trip
      final http.Response response = await _api.post('/orders/sync', syncPayload);
      if (response.statusCode != 200) {
        debugPrint('Sync request failed with status: ${response.statusCode}');
        return false;
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> serverOrders = responseData['serverOrders'] as List<dynamic>;
      final DateTime serverSyncTime = DateTime.parse(responseData['serverSyncTime'] as String);

      // 3. Acknowledge what the server accepted (rows edited again during the request stay pending)
      await _db.purgeDeleted(deletedIds);
      await _db.markPushedAsSynced(localModified);

      // 4. Apply server changes
      final upserts = <Order>[];
      final removed = <String>[];
      for (final item in serverOrders) {
        final map = item as Map<String, dynamic>;
        if (map['deleted'] == true) {
          removed.add(map['id'] as String);
        } else {
          upserts.add(orderFromJson(map, _cipher));
        }
      }
      await _db.applyServerChanges(upserts: upserts, deletedIds: removed);

      // 5. Advance the cursor (server clock, so device clock errors don't matter)
      await LocalCache.setLastSyncTime(serverSyncTime);
      return true;
    } catch (e) {
      debugPrint('Sync Error: $e');
      _lastBatchWasFull = false;
      return false;
    }
  }

  void dispose() => stopAutoSync();
}

/// Serializes a local order for the API. Device secrets are decrypted here; TLS protects them in transit
/// and the server re-encrypts them at rest.
Map<String, dynamic> orderToJson(Order order, DeviceSecretCipher cipher) {
  return {
    'id': order.id,
    'status': order.status,
    'repairDate': _formatDate(order.repairDate),
    'repairTime': order.repairTime,
    'reminderEnabled': order.reminderEnabled,
    'customerName': order.customerName,
    'customerNumber': order.customerNumber,
    'customerAddress': order.customerAddress,
    'deviceProblem': order.deviceProblem,
    'estimatePrice': Money.toApi(order.estimatePriceMinor),
    'paidPrice': Money.toApi(order.paidPriceMinor),
    'devicePassword': cipher.decrypt(order.devicePassword),
    'devicePattern': cipher.decrypt(order.devicePattern),
    'description': order.description,
    'accessoriesSim': order.accessoriesSim,
    'accessoriesSdCard': order.accessoriesSdCard,
    'accessoriesBackCover': order.accessoriesBackCover,
    'accessoriesCharger': order.accessoriesCharger,
    'notifyWhatsapp': order.notifyWhatsapp,
    'notifyEmail': order.notifyEmail,
    'createdAt': order.createdAt.toUtc().toIso8601String(),
    'updatedAt': order.updatedAt.toUtc().toIso8601String(),
  };
}

Order orderFromJson(Map<String, dynamic> map, DeviceSecretCipher cipher) {
  final String repairTime = map['repairTime'] as String;
  return Order(
    id: map['id'] as String,
    status: map['status'] as String,
    repairDate: DateTime.parse(map['repairDate'] as String),
    // The server sends HH:mm:ss; the app works with HH:mm
    repairTime: repairTime.length > 5 ? repairTime.substring(0, 5) : repairTime,
    reminderEnabled: map['reminderEnabled'] as bool,
    customerName: map['customerName'] as String,
    customerNumber: map['customerNumber'] as String,
    customerAddress: map['customerAddress'] as String?,
    deviceProblem: map['deviceProblem'] as String,
    estimatePriceMinor: Money.fromApi(map['estimatePrice'] as num),
    paidPriceMinor: Money.fromApi(map['paidPrice'] as num),
    devicePassword: cipher.encrypt(map['devicePassword'] as String?),
    devicePattern: cipher.encrypt(map['devicePattern'] as String?),
    description: map['description'] as String?,
    accessoriesSim: map['accessoriesSim'] as bool,
    accessoriesSdCard: map['accessoriesSdCard'] as bool,
    accessoriesBackCover: map['accessoriesBackCover'] as bool,
    accessoriesCharger: map['accessoriesCharger'] as bool,
    notifyWhatsapp: map['notifyWhatsapp'] as bool,
    notifyEmail: map['notifyEmail'] as bool,
    syncStatus: SyncStatus.synced,
    localRevision: 0,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
