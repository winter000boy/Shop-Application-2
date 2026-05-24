import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/network/api_client.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/services/notification_service.dart';
import 'package:repair_shop_app/services/sync_manager.dart';

// SQLite Database Singleton Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// REST API Client Singleton Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// WhatsApp Mock Notification Provider
final notificationProvider = Provider<NotificationProvider>((ref) {
  return MockNotificationProvider();
});

// Offline-first Sync Manager Provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncManager(db);
});
