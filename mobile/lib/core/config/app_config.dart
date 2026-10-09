import 'dart:io';

class AppConfig {
  // Override per build: flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    // The Android emulator reaches the host machine via 10.0.2.2; the iOS simulator shares the host's localhost
    return Platform.isAndroid ? 'http://10.0.2.2:8080/api/v1' : 'http://localhost:8080/api/v1';
  }
}
