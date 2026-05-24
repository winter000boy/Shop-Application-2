import 'package:hive_flutter/hive_flutter.dart';

class LocalCache {
  static const String _preferencesBoxName = 'app_preferences';
  static const String _authBoxName = 'auth_session';

  // Preference Keys
  static const String keyDarkMode = 'is_dark_mode';
  static const String keyLanguage = 'app_language';
  static const String keyLastSyncTime = 'last_sync_time';

  // Auth Keys
  static const String keyJwtToken = 'jwt_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyShopId = 'shop_id';
  static const String keyShopName = 'shop_name';
  static const String keyShopType = 'shop_type';
  static const String keyOwnerName = 'owner_name';
  static const String keyUsername = 'username';
  static const String keyEmail = 'email';
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyLogoUrl = 'logo_url';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_preferencesBoxName);
    await Hive.openBox(_authBoxName);
  }

  static Box _getPrefsBox() => Hive.box(_preferencesBoxName);
  static Box _getAuthBox() => Hive.box(_authBoxName);

  // --- Auth Session Accessors ---

  static Future<void> saveSession({
    required String jwtToken,
    required String refreshToken,
    required String shopId,
    required String shopName,
    required String shopType,
    required String ownerName,
    required String username,
    required String email,
    required String currencySymbol,
    required String logoUrl,
  }) async {
    final box = _getAuthBox();
    await box.put(keyJwtToken, jwtToken);
    await box.put(keyRefreshToken, refreshToken);
    await box.put(keyShopId, shopId);
    await box.put(keyShopName, shopName);
    await box.put(keyShopType, shopType);
    await box.put(keyOwnerName, ownerName);
    await box.put(keyUsername, username);
    await box.put(keyEmail, email);
    await box.put(keyCurrencySymbol, currencySymbol);
    await box.put(keyLogoUrl, logoUrl);
  }

  static Future<void> updateShopDetails({
    required String shopName,
    required String shopType,
    required String ownerName,
    required String currencySymbol,
    required String logoUrl,
  }) async {
    final box = _getAuthBox();
    await box.put(keyShopName, shopName);
    await box.put(keyShopType, shopType);
    await box.put(keyOwnerName, ownerName);
    await box.put(keyCurrencySymbol, currencySymbol);
    await box.put(keyLogoUrl, logoUrl);
  }

  static Future<void> saveAccessToken(String jwtToken) async {
    await _getAuthBox().put(keyJwtToken, jwtToken);
  }

  static String? getJwtToken() => _getAuthBox().get(keyJwtToken) as String?;
  static String? getRefreshToken() => _getAuthBox().get(keyRefreshToken) as String?;
  static String? getShopId() => _getAuthBox().get(keyShopId) as String?;
  static String? getShopName() => _getAuthBox().get(keyShopName) as String?;
  static String? getShopType() => _getAuthBox().get(keyShopType) as String?;
  static String? getOwnerName() => _getAuthBox().get(keyOwnerName) as String?;
  static String? getUsername() => _getAuthBox().get(keyUsername) as String?;
  static String? getEmail() => _getAuthBox().get(keyEmail) as String?;
  static String getCurrencySymbol() => (_getAuthBox().get(keyCurrencySymbol) as String?) ?? '₹';
  static String? getLogoUrl() => _getAuthBox().get(keyLogoUrl) as String?;

  static bool isAuthenticated() => getJwtToken() != null;

  static Future<void> clearSession() async {
    await _getAuthBox().clear();
    await _getPrefsBox().delete(keyLastSyncTime);
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

  static Future<void> setLastSyncTime(DateTime time) async {
    await _getPrefsBox().put(keyLastSyncTime, time.toIso8601String());
  }

  static DateTime? getLastSyncTime() {
    final str = _getPrefsBox().get(keyLastSyncTime) as String?;
    return str != null ? DateTime.tryParse(str) : null;
  }
}
