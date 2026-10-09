import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Key-value storage. Secrets (session tokens, the device-secret encryption key) live in the platform
/// keystore via flutter_secure_storage and are mirrored in memory so reads stay synchronous.
/// Non-sensitive shop profile and preferences live in Hive.
class LocalCache {
  static const String _preferencesBoxName = 'app_preferences';
  static const String _authBoxName = 'auth_session';

  // Preference Keys
  static const String keyDarkMode = 'is_dark_mode';
  static const String keyLanguage = 'app_language';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyDataOwnerShopId = 'data_owner_shop_id';
  static const String _keyInitialized = 'initialized';

  // Secure Keys
  static const String keyJwtToken = 'jwt_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyDeviceSecretKey = 'device_secret_key';

  // Shop Profile Keys
  static const String keyShopId = 'shop_id';
  static const String keyShopName = 'shop_name';
  static const String keyShopType = 'shop_type';
  static const String keyOwnerName = 'owner_name';
  static const String keyUsername = 'username';
  static const String keyEmail = 'email';
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyLogoUrl = 'logo_url';
  static const String keyMobileNumber = 'mobile_number';
  static const String keyCountryCode = 'country_code';
  static const String keyAddress = 'address';
  static const String keyGstNumber = 'gst_number';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static String? _jwtToken;
  static String? _refreshToken;
  static late Uint8List _deviceSecretKey;

  /// [hivePath] is only for tests; the app uses the platform documents directory.
  static Future<void> init({String? hivePath}) async {
    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }
    final prefsBox = await Hive.openBox(_preferencesBoxName);
    final authBox = await Hive.openBox(_authBoxName);

    // The iOS keychain survives an uninstall while Hive doesn't: drop stale tokens on a fresh install
    if (prefsBox.get(_keyInitialized) != true) {
      await _secure.deleteAll();
      await prefsBox.put(_keyInitialized, true);
    }

    // Builds before secure storage kept tokens in plain Hive: move them into the keystore
    final legacyJwt = authBox.get(keyJwtToken) as String?;
    final legacyRefresh = authBox.get(keyRefreshToken) as String?;
    if (legacyJwt != null && legacyRefresh != null) {
      await saveTokens(accessToken: legacyJwt, refreshToken: legacyRefresh);
    }
    await authBox.deleteAll([keyJwtToken, keyRefreshToken]);

    _jwtToken = await _secure.read(key: keyJwtToken);
    _refreshToken = await _secure.read(key: keyRefreshToken);
    _deviceSecretKey = await _loadOrCreateDeviceSecretKey();
  }

  static Box _getPrefsBox() => Hive.box(_preferencesBoxName);
  static Box _getAuthBox() => Hive.box(_authBoxName);

  static Future<Uint8List> _loadOrCreateDeviceSecretKey() async {
    final existing = await _secure.read(key: keyDeviceSecretKey);
    if (existing != null) return base64Decode(existing);
    final random = Random.secure();
    final key = Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
    await _secure.write(key: keyDeviceSecretKey, value: base64Encode(key));
    return key;
  }

  static Uint8List get deviceSecretKey => _deviceSecretKey;

  // --- Auth Session Accessors ---

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _jwtToken = accessToken;
    _refreshToken = refreshToken;
    await _secure.write(key: keyJwtToken, value: accessToken);
    await _secure.write(key: keyRefreshToken, value: refreshToken);
  }

  /// Persists the tokens and shop profile from an /auth/login, /auth/signup or /auth/refresh response.
  static Future<void> saveSession(Map<String, dynamic> authResponse) async {
    await saveTokens(
      accessToken: authResponse['accessToken'] as String,
      refreshToken: authResponse['refreshToken'] as String,
    );
    await saveShopProfile(authResponse['shop'] as Map<String, dynamic>);
  }

  /// Caches a shop profile as returned by the API (AuthResponse.ShopDto).
  static Future<void> saveShopProfile(Map<String, dynamic> shop) async {
    await _getAuthBox().putAll({
      keyShopId: shop['id'] as String?,
      keyShopName: shop['shopName'] as String?,
      keyShopType: shop['shopType'] as String?,
      keyOwnerName: shop['ownerName'] as String?,
      keyUsername: shop['username'] as String?,
      keyEmail: shop['email'] as String?,
      keyCurrencySymbol: shop['currencySymbol'] as String?,
      keyLogoUrl: (shop['logoUrl'] as String?) ?? '',
      keyMobileNumber: shop['mobileNumber'] as String?,
      keyCountryCode: shop['countryCode'] as String?,
      keyAddress: shop['address'] as String?,
      keyGstNumber: shop['gstNumber'] as String?,
    });
  }

  static Future<void> updateShopDetails({
    required String shopName,
    required String shopType,
    required String ownerName,
    required String mobileNumber,
    required String countryCode,
    required String address,
    required String currencySymbol,
  }) async {
    await _getAuthBox().putAll({
      keyShopName: shopName,
      keyShopType: shopType,
      keyOwnerName: ownerName,
      keyMobileNumber: mobileNumber,
      keyCountryCode: countryCode,
      keyAddress: address,
      keyCurrencySymbol: currencySymbol,
    });
  }

  static String? getJwtToken() => _jwtToken;
  static String? getRefreshToken() => _refreshToken;
  static String? getShopId() => _getAuthBox().get(keyShopId) as String?;
  static String? getShopName() => _getAuthBox().get(keyShopName) as String?;
  static String? getShopType() => _getAuthBox().get(keyShopType) as String?;
  static String? getOwnerName() => _getAuthBox().get(keyOwnerName) as String?;
  static String? getUsername() => _getAuthBox().get(keyUsername) as String?;
  static String? getEmail() => _getAuthBox().get(keyEmail) as String?;
  static String getCurrencySymbol() => (_getAuthBox().get(keyCurrencySymbol) as String?) ?? '₹';
  static String? getLogoUrl() => _getAuthBox().get(keyLogoUrl) as String?;
  static String? getMobileNumber() => _getAuthBox().get(keyMobileNumber) as String?;
  static String getCountryCode() => (_getAuthBox().get(keyCountryCode) as String?) ?? '+91';
  static String? getAddress() => _getAuthBox().get(keyAddress) as String?;
  static String? getGstNumber() => _getAuthBox().get(keyGstNumber) as String?;

  static bool isAuthenticated() => _jwtToken != null && _refreshToken != null;

  static Future<void> clearSession() async {
    _jwtToken = null;
    _refreshToken = null;
    await _secure.delete(key: keyJwtToken);
    await _secure.delete(key: keyRefreshToken);
    await _getAuthBox().clear();
    await clearLastSyncTime();
  }

  // --- App Preference Accessors ---

  static Future<void> setDarkMode(bool isEnabled) async {
    await _getPrefsBox().put(keyDarkMode, isEnabled);
  }

  static bool isDarkMode() => (_getPrefsBox().get(keyDarkMode) as bool?) ?? false;

  static Future<void> setLanguage(String langCode) async {
    await _getPrefsBox().put(keyLanguage, langCode);
  }

  static String getLanguage() => (_getPrefsBox().get(keyLanguage) as String?) ?? 'en';

  // Server time of the last successful sync (UTC); the cursor for delta sync
  static Future<void> setLastSyncTime(DateTime time) async {
    await _getPrefsBox().put(keyLastSyncTime, time.toUtc().toIso8601String());
  }

  static DateTime? getLastSyncTime() {
    final str = _getPrefsBox().get(keyLastSyncTime) as String?;
    return str != null ? DateTime.tryParse(str)?.toUtc() : null;
  }

  static Future<void> clearLastSyncTime() async {
    await _getPrefsBox().delete(keyLastSyncTime);
  }

  // Which shop the orders in the local database belong to. Kept across session expiry (unlike the
  // session itself) so unsynced edits survive a forced sign-out; cleared on an explicit sign-out.
  static String? getDataOwnerShopId() => _getPrefsBox().get(keyDataOwnerShopId) as String?;

  static Future<void> setDataOwnerShopId(String shopId) async {
    await _getPrefsBox().put(keyDataOwnerShopId, shopId);
  }

  static Future<void> clearDataOwnerShopId() async {
    await _getPrefsBox().delete(keyDataOwnerShopId);
  }
}
