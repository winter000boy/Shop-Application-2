import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/network/api_client.dart';
import 'package:repair_shop_app/core/security/device_secret_cipher.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/services/notification_service.dart';
import 'package:repair_shop_app/services/sync_manager.dart';

// SQLite Database Singleton Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// REST API Client Singleton Provider (shared so token refreshes are coordinated across all callers)
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.dispose);
  return client;
});

// Encrypts customer device passcodes/patterns stored in SQLite
final deviceSecretCipherProvider = Provider<DeviceSecretCipher>((ref) {
  return DeviceSecretCipher(LocalCache.deviceSecretKey);
});

// WhatsApp Mock Notification Provider
final notificationProvider = Provider<NotificationProvider>((ref) {
  return MockNotificationProvider();
});

// Offline-first Sync Manager Provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    ref.watch(databaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(deviceSecretCipherProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});
