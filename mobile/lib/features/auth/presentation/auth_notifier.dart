import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:repair_shop_app/core/network/api_client.dart';
import 'package:repair_shop_app/database/local_cache.dart';
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
  final ApiClient _api;

  AuthNotifier(this._api) : super(AuthState(isAuthenticated: LocalCache.isAuthenticated()));

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final http.Response response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String accessToken = data['accessToken'] as String;
        final String refreshToken = data['refreshToken'] as String;
        final Map<String, dynamic> shop = data['shop'] as Map<String, dynamic>;

        await LocalCache.saveSession(
          jwtToken: accessToken,
          refreshToken: refreshToken,
          shopId: shop['id'] as String,
          shopName: shop['shopName'] as String,
          shopType: shop['shopType'] as String,
          ownerName: shop['ownerName'] as String,
          username: shop['username'] as String,
          email: shop['email'] as String,
          currencySymbol: shop['currencySymbol'] as String,
          logoUrl: (shop['logoUrl'] as String?) ?? '',
        );

        state = AuthState(isAuthenticated: true);
        return true;
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorData['message'] as String? ?? 'Invalid email or password',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please check your internet connection',
      );
    }
    return false;
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
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final http.Response response = await _api.post('/auth/signup', {
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
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String accessToken = data['accessToken'] as String;
        final String refreshToken = data['refreshToken'] as String;
        final Map<String, dynamic> shop = data['shop'] as Map<String, dynamic>;

        await LocalCache.saveSession(
          jwtToken: accessToken,
          refreshToken: refreshToken,
          shopId: shop['id'] as String,
          shopName: shop['shopName'] as String,
          shopType: shop['shopType'] as String,
          ownerName: shop['ownerName'] as String,
          username: shop['username'] as String,
          email: shop['email'] as String,
          currencySymbol: shop['currencySymbol'] as String,
          logoUrl: (shop['logoUrl'] as String?) ?? '',
        );

        state = AuthState(isAuthenticated: true);
        return true;
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorData['message'] as String? ?? 'Sign up failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please check your internet connection',
      );
    }
    return false;
  }

  Future<void> logout() async {
    await LocalCache.clearSession();
    state = AuthState(isAuthenticated: false);
  }
}

// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(api);
});
