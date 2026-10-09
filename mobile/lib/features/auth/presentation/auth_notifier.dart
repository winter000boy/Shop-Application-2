import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:repair_shop_app/core/network/api_client.dart';
import 'package:repair_shop_app/database/app_database.dart';
import 'package:repair_shop_app/database/local_cache.dart';
import 'package:repair_shop_app/services/sync_manager.dart';
import 'package:repair_shop_app/shared/providers.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String _networkError = 'Network error. Please check your internet connection';

  final ApiClient _api;
  final AppDatabase _db;
  final SyncManager _sync;
  late final StreamSubscription<void> _sessionExpirySub;

  AuthNotifier(this._api, this._db, this._sync) : super(AuthState(isAuthenticated: LocalCache.isAuthenticated())) {
    _sessionExpirySub = _api.onSessionExpired.listen((_) => _handleSessionExpired());
    if (state.isAuthenticated) {
      _sync.startAutoSync();
    }
  }

  Future<bool> login(String email, String password) {
    return _authenticate('/auth/login', {
      'email': email,
      'password': password,
    }, fallbackError: 'Invalid email or password');
  }

  Future<bool> signup({
    required String shopType,
    required String shopName,
    required String gstNumber,
    required String ownerName,
    required String username,
    required String mobileNumber,
    required String countryCode,
    required String shopAddress,
    required String email,
    required String password,
    required String currencySymbol,
  }) {
    return _authenticate('/auth/signup', {
      'shopType': shopType,
      'shopName': shopName,
      'gstNumber': gstNumber.isEmpty ? null : gstNumber,
      'ownerName': ownerName,
      'username': username,
      'mobileNumber': mobileNumber,
      'countryCode': countryCode,
      'shopAddress': shopAddress.isEmpty ? null : shopAddress,
      'email': email,
      'password': password,
      'currencySymbol': currencySymbol,
      'logoUrl': '',
    }, fallbackError: 'Sign up failed');
  }

  Future<bool> _authenticate(String path, Map<String, dynamic> body, {required String fallbackError}) async {
    state = state.copyWith(isLoading: true);
    try {
      final http.Response response = await _api.post(path, body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String shopId = (data['shop'] as Map<String, dynamic>)['id'] as String;

        await _prepareLocalDataFor(shopId);
        await LocalCache.saveSession(data);

        state = AuthState(isAuthenticated: true);
        _sync.startAutoSync();
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: response.statusCode == ApiClient.offlineStatusCode
            ? _networkError
            : ApiClient.errorMessage(response, fallbackError),
      );
    } catch (e) {
      debugPrint('Authentication failed: $e');
      state = state.copyWith(isLoading: false, errorMessage: fallbackError);
    }
    return false;
  }

  /// Local orders belong to one shop. Keep them when the same shop signs back in (e.g. after a session
  /// expired with unsynced edits), wipe them when a different shop signs in on this device.
  Future<void> _prepareLocalDataFor(String shopId) async {
    if (LocalCache.getDataOwnerShopId() != shopId) {
      await _db.clearAll();
      await LocalCache.clearLastSyncTime();
      await LocalCache.setDataOwnerShopId(shopId);
    }
  }

  /// Tries to push pending changes and returns how many are still not on the server.
  Future<int> syncBeforeLogout() async {
    await _sync.triggerSync();
    return _db.countUnsyncedOrders();
  }

  /// Signs out on this device: revokes the session on the server and removes all local shop data.
  Future<void> logout() async {
    _sync.stopAutoSync();

    final refreshToken = LocalCache.getRefreshToken();
    if (refreshToken != null) {
      // Best effort: if offline, the refresh token simply expires on its own
      await _api.post('/auth/logout', {'refreshToken': refreshToken});
    }

    await _db.clearAll();
    await LocalCache.clearSession();
    await LocalCache.clearDataOwnerShopId();
    state = AuthState(isAuthenticated: false);
  }

  // The server rejected our refresh token (expired, revoked or password changed elsewhere).
  // Local orders are kept so unsynced edits survive until the same shop signs in again.
  Future<void> _handleSessionExpired() async {
    if (!state.isAuthenticated) return;
    _sync.stopAutoSync();
    await LocalCache.clearSession();
    state = AuthState(isAuthenticated: false, errorMessage: 'Your session has expired. Please sign in again');
  }

  /// Emails a 6-digit reset code. Returns an error message, or null on success.
  Future<String?> requestPasswordReset(String email) async {
    final response = await _api.post('/auth/forgot-password', {'email': email});
    if (response.statusCode == 200) return null;
    if (response.statusCode == ApiClient.offlineStatusCode) return _networkError;
    return ApiClient.errorMessage(response, 'Could not send the reset code');
  }

  /// Sets a new password using the emailed code. Returns an error message, or null on success.
  Future<String?> resetPassword({required String email, required String code, required String newPassword}) async {
    final response = await _api.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
    if (response.statusCode == 200) return null;
    if (response.statusCode == ApiClient.offlineStatusCode) return _networkError;
    return ApiClient.errorMessage(response, 'Could not reset the password');
  }

  @override
  void dispose() {
    _sessionExpirySub.cancel();
    super.dispose();
  }
}

// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiClientProvider),
    ref.watch(databaseProvider),
    ref.watch(syncManagerProvider),
  );
});
