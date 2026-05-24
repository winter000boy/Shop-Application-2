import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:repair_shop_app/core/network/api_client.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';

class SyncManager {
  final AppDatabase _db;
  final ApiClient _api = ApiClient();
  bool _isSyncing = false;

  SyncManager(this._db);

  bool get isSyncing => _isSyncing;

  // Triggers bi-directional synchronization
  Future<bool> triggerSync() async {
    // Prevent concurrent sync cycles
    if (_isSyncing) return false;
    
    // Check if user is logged in
    if (!LocalCache.isAuthenticated()) return false;

    _isSyncing = true;
    try {
      // 1. Fetch all local unsynced edits from SQLite
      final List<Order> localUnsynced = await _db.getUnsyncedOrders();
      
      // Separate changes
      final List<Order> localModified = localUnsynced.where((o) => o.syncStatus != 'pending_delete').toList();
      final List<String> deletedIds = localUnsynced
          .where((o) => o.syncStatus == 'pending_delete')
          .map((o) => o.id)
          .toList();

      // Convert local orders to DTO list for JSON payload
      final List<Map<String, dynamic>> localOrdersDto = localModified.map((order) {
        return {
          'id': order.id,
          'status': order.status,
          'repairDate': order.repairDate.toIso8601String().split('T')[0], // yyyy-MM-dd
          'repairTime': order.repairTime,
          'reminderEnabled': order.reminderEnabled,
          'customerName': order.customerName,
          'customerNumber': order.customerNumber,
          'customerAddress': order.customerAddress,
          'deviceProblem': order.deviceProblem,
          'estimatePrice': order.estimatePrice,
          'paidPrice': order.paidPrice,
          'devicePassword': order.devicePassword,
          'devicePattern': order.devicePattern,
          'description': order.description,
          'accessoriesSim': order.accessoriesSim,
          'accessoriesSdCard': order.accessoriesSdCard,
          'accessoriesBackCover': order.accessoriesBackCover,
          'accessoriesCharger': order.accessoriesCharger,
          'notifyWhatsapp': order.notifyWhatsapp,
          'notifyEmail': order.notifyEmail,
          'createdAt': order.createdAt.toIso8601String(),
          'updatedAt': order.updatedAt.toIso8601String(),
        };
      }).toList();

      // 2. Build sync packet
      final Map<String, dynamic> syncPayload = {
        'lastSyncTime': LocalCache.getLastSyncTime()?.toIso8601String(),
        'localOrders': localOrdersDto,
        'deletedOrderIds': deletedIds,
      };

      // 3. Post to backend sync endpoint
      final http.Response response = await _api.post('/orders/sync', syncPayload);
      
      if (response.statusCode != 200) {
        print('Sync request failed with status: ${response.statusCode}');
        _isSyncing = false;
        return false;
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> serverOrders = responseData['serverOrders'] as List<dynamic>;
      final String serverSyncTimeStr = responseData['serverSyncTime'] as String;
      final DateTime serverSyncTime = DateTime.parse(serverSyncTimeStr);

      // 4. Resolve local data based on server response
      // A. Physically delete items marked as pending_delete that the server processed
      for (final String delId in deletedIds) {
        await _db.hardDeleteOrder(delId);
      }

      // B. Mark local additions/updates as synced
      for (final Order order in localModified) {
        await _db.markAsSynced(order.id);
      }

      // C. Process server updates pulled down to the client
      for (final dynamic item in serverOrders) {
        final Map<String, dynamic> orderMap = item as Map<String, dynamic>;
        
        final String orderId = orderMap['id'] as String;
        final String status = orderMap['status'] as String;
        final DateTime repairDate = DateTime.parse(orderMap['repairDate'] as String);
        final String repairTime = orderMap['repairTime'] as String;
        final bool reminderEnabled = orderMap['reminderEnabled'] as bool;
        final String customerName = orderMap['customerName'] as String;
        final String customerNumber = orderMap['customerNumber'] as String;
        final String? customerAddress = orderMap['customerAddress'] as String?;
        final String deviceProblem = orderMap['deviceProblem'] as String;
        final double estimatePrice = (orderMap['estimatePrice'] as num).toDouble();
        final double paidPrice = (orderMap['paidPrice'] as num).toDouble();
        final String? devicePassword = orderMap['devicePassword'] as String?;
        final String? devicePattern = orderMap['devicePattern'] as String?;
        final String? description = orderMap['description'] as String?;
        final bool accessoriesSim = orderMap['accessoriesSim'] as bool;
        final bool accessoriesSdCard = orderMap['accessoriesSdCard'] as bool;
        final bool accessoriesBackCover = orderMap['accessoriesBackCover'] as bool;
        final bool accessoriesCharger = orderMap['accessoriesCharger'] as bool;
        final bool notifyWhatsapp = orderMap['notifyWhatsapp'] as bool;
        final bool notifyEmail = orderMap['notifyEmail'] as bool;
        final DateTime createdAt = DateTime.parse(orderMap['createdAt'] as String);
        final DateTime updatedAt = DateTime.parse(orderMap['updatedAt'] as String);

        // Map into Drift structure and upsert
        final Order serverOrder = Order(
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
          syncStatus: 'synced',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        await _db.insertOrder(serverOrder);
      }

      // 5. Update last synchronization timestamp in Hive
      await LocalCache.setLastSyncTime(serverSyncTime);
      _isSyncing = false;
      return true;
    } catch (e) {
      print('Sync Error: $e');
      _isSyncing = false;
      return false;
    }
  }
}
