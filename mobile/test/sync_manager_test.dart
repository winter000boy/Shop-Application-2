import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repair_shop_app/core/network/api_client.dart';
import 'package:repair_shop_app/core/security/device_secret_cipher.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/services/sync_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DeviceSecretCipher cipher;
  late Directory hiveDir;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('fixmanager_test');
    await LocalCache.init(hivePath: hiveDir.path);
    await LocalCache.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cipher = DeviceSecretCipher(Uint8List.fromList(List<int>.filled(32, 7)));
  });

  tearDown(() async {
    await db.close();
    await LocalCache.clearSession();
    await hiveDir.delete(recursive: true);
  });

  Order localOrder(String id, {String syncStatus = SyncStatus.pendingCreate, int revision = 0, String status = 'PENDING'}) {
    return Order(
      id: id,
      status: status,
      repairDate: DateTime(2026, 10, 7),
      repairTime: '10:30',
      reminderEnabled: false,
      customerName: 'Ravi',
      customerNumber: '9876543210',
      deviceProblem: 'Screen',
      estimatePriceMinor: 150050,
      paidPriceMinor: 0,
      devicePassword: cipher.encrypt('1234'),
      accessoriesSim: false,
      accessoriesSdCard: false,
      accessoriesBackCover: false,
      accessoriesCharger: false,
      notifyWhatsapp: false,
      notifyEmail: false,
      syncStatus: syncStatus,
      localRevision: revision,
      createdAt: DateTime.utc(2026, 10, 7, 5),
      updatedAt: DateTime.utc(2026, 10, 7, 5),
    );
  }

  Map<String, dynamic> serverOrder(String id, {bool deleted = false, String name = 'From server'}) => {
        'id': id,
        'status': 'REPAIRED',
        'repairDate': '2026-10-07',
        'repairTime': '10:30:00',
        'reminderEnabled': false,
        'customerName': name,
        'customerNumber': '9876543210',
        'customerAddress': null,
        'deviceProblem': 'Screen',
        'estimatePrice': 1500.5,
        'paidPrice': 0,
        'devicePassword': '9999',
        'devicePattern': null,
        'description': null,
        'accessoriesSim': false,
        'accessoriesSdCard': false,
        'accessoriesBackCover': false,
        'accessoriesCharger': false,
        'notifyWhatsapp': false,
        'notifyEmail': false,
        'deleted': deleted,
        'createdAt': '2026-10-07T05:00:00Z',
        'updatedAt': '2026-10-07T06:00:00Z',
      };

  http.Response syncResponse(List<Map<String, dynamic>> orders) => http.Response(
        jsonEncode({'serverOrders': orders, 'serverSyncTime': '2026-10-07T07:00:00Z'}),
        200,
      );

  SyncManager managerWith(Future<http.Response> Function(http.Request) handler) {
    return SyncManager(db, ApiClient(client: MockClient(handler), baseUrl: 'http://test'), cipher);
  }

  test('pushes pending orders with decrypted secrets, decimal money and UTC times', () async {
    await db.insertOrder(localOrder('a'));
    late Map<String, dynamic> sent;

    final ok = await managerWith((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return syncResponse([]);
    }).triggerSync();

    expect(ok, isTrue);
    final pushed = (sent['localOrders'] as List).single as Map<String, dynamic>;
    expect(pushed['devicePassword'], '1234');
    expect(pushed['estimatePrice'], 1500.5);
    expect(pushed['updatedAt'], endsWith('Z'));
    expect((await db.getOrderById('a'))!.syncStatus, SyncStatus.synced);
    expect(LocalCache.getLastSyncTime(), DateTime.utc(2026, 10, 7, 7));
  });

  test('an edit made while the sync request is in flight stays pending', () async {
    await db.insertOrder(localOrder('a'));

    await managerWith((request) async {
      // User edits the order while the request is on the wire
      final current = (await db.getOrderById('a'))!;
      await db.updateOrder(current.copyWith(customerName: 'Edited', localRevision: current.localRevision + 1));
      return syncResponse([]);
    }).triggerSync();

    final order = (await db.getOrderById('a'))!;
    expect(order.customerName, 'Edited');
    expect(order.syncStatus, SyncStatus.pendingCreate);
  });

  test('server tombstones delete local rows; server versions do not clobber pending local edits', () async {
    await db.insertOrder(localOrder('gone', syncStatus: SyncStatus.synced));
    await db.insertOrder(localOrder('mine', syncStatus: SyncStatus.pendingUpdate));

    await managerWith((request) async {
      // Simulate the user editing 'mine' again mid-request so it is still pending when the pull is applied
      final mine = (await db.getOrderById('mine'))!;
      await db.updateOrder(mine.copyWith(localRevision: mine.localRevision + 1));
      return syncResponse([serverOrder('gone', deleted: true), serverOrder('mine'), serverOrder('new')]);
    }).triggerSync();

    expect(await db.getOrderById('gone'), isNull);
    expect((await db.getOrderById('mine'))!.customerName, 'Ravi');

    final pulled = (await db.getOrderById('new'))!;
    expect(pulled.repairTime, '10:30');
    expect(pulled.estimatePriceMinor, 150050);
    expect(pulled.devicePassword, startsWith('enc:v1:'));
    expect(cipher.decrypt(pulled.devicePassword), '9999');
  });

  test('accepted deletions are purged locally', () async {
    await db.insertOrder(localOrder('d', syncStatus: SyncStatus.synced));
    await db.softDeleteOrder('d');
    late Map<String, dynamic> sent;

    await managerWith((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return syncResponse([]);
    }).triggerSync();

    expect(sent['deletedOrderIds'], ['d']);
    expect(await db.getOrderById('d'), isNull);
  });

  test('concurrent triggers share one request and re-run once afterwards', () async {
    var requests = 0;
    final gate = Completer<void>();
    final manager = managerWith((request) async {
      requests++;
      if (requests == 1) await gate.future;
      return syncResponse([]);
    });

    final first = manager.triggerSync();
    final second = manager.triggerSync();
    expect(manager.isSyncing, isTrue);
    gate.complete();

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(requests, 2);
    expect(manager.isSyncing, isFalse);
  });

  test('failed sync keeps changes pending and the cursor unchanged', () async {
    await db.insertOrder(localOrder('a'));

    final ok = await managerWith((request) async => http.Response('{"message":"boom"}', 500)).triggerSync();

    expect(ok, isFalse);
    expect((await db.getOrderById('a'))!.syncStatus, SyncStatus.pendingCreate);
    expect(LocalCache.getLastSyncTime(), isNull);
  });

  test('watchOrders hides pending deletes and treats LIKE wildcards literally', () async {
    await db.insertOrder(localOrder('a', syncStatus: SyncStatus.synced));
    await db.insertOrder(localOrder('b', syncStatus: SyncStatus.synced).copyWith(customerName: '100% Mobiles'));
    await db.softDeleteOrder('a');

    expect((await db.watchOrders().first).map((o) => o.id), ['b']);
    expect((await db.watchOrders(searchQuery: '%').first).map((o) => o.id), ['b']);
    expect(await db.watchOrders(searchQuery: '_x').first, isEmpty);
    expect(await db.watchOrders(status: 'DELIVERED').first, isEmpty);
    expect(await db.countUnsyncedOrders(), 1);
  });

  test('an expired refresh token signals session expiry', () async {
    final api = ApiClient(
      client: MockClient((request) async =>
          request.url.path.endsWith('/auth/refresh') ? http.Response('{}', 401) : http.Response('{}', 401)),
      baseUrl: 'http://test',
    );
    final expired = expectLater(api.onSessionExpired, emits(null));
    final response = await api.get('/orders');
    expect(response.statusCode, 401);
    await expired;
  });

  test('concurrent 401s trigger a single token refresh and both requests are retried', () async {
    var refreshCalls = 0;
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(jsonEncode({'accessToken': 'new-access', 'refreshToken': 'new-refresh'}), 200);
        }
        return request.headers['Authorization'] == 'Bearer new-access'
            ? http.Response('{}', 200)
            : http.Response('{}', 401);
      }),
      baseUrl: 'http://test',
    );

    final results = await Future.wait([api.get('/orders'), api.get('/shop')]);

    expect(results.map((r) => r.statusCode), [200, 200]);
    expect(refreshCalls, 1);
    expect(LocalCache.getRefreshToken(), 'new-refresh');
  });
}
