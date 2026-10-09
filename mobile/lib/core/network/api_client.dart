import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:repair_shop_app/core/config/app_config.dart';
import 'package:repair_shop_app/database/local_cache.dart';

class ApiClient {
  // Generous because a sleeping server (e.g. Render's free plan) takes ~50s to wake up and answer.
  // Being offline still fails fast: DNS/connection errors don't wait for this timeout.
  static const Duration _timeout = Duration(seconds: 75);

  // Status code of the synthetic response returned when the server can't be reached
  static const int offlineStatusCode = 503;

  final http.Client _client;
  final String baseUrl;

  // Concurrent 401s share one refresh call instead of racing each other
  Future<bool>? _refreshInFlight;

  final StreamController<void> _sessionExpired = StreamController<void>.broadcast();

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Fires when the refresh token is rejected and the user must sign in again.
  Stream<void> get onSessionExpired => _sessionExpired.stream;

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(String method, String path, {Object? body, String? token}) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))..headers.addAll(_getHeaders(token));
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client.send(request).timeout(_timeout);
    return http.Response.fromStream(streamed).timeout(_timeout);
  }

  http.Response _offlineResponse(Object error) {
    // Return a simulated connection failure response for offline state
    return http.Response(
      jsonEncode({'error': 'Connection failed', 'message': 'Could not reach the server. Check your internet connection'}),
      offlineStatusCode,
    );
  }

  // Generic Request Handler
  Future<http.Response> _requestWithRetry(String method, String path, {Object? body}) async {
    final String? token = LocalCache.getJwtToken();

    http.Response response;
    try {
      response = await _send(method, path, body: body, token: token);
    } catch (e) {
      return _offlineResponse(e);
    }

    // Intercept 401 Unauthorized errors to attempt automatic session refreshing.
    // Auth endpoints return 401 for bad credentials, which a refresh can't fix.
    if (response.statusCode != 401 || token == null || path.startsWith('/auth/')) {
      return response;
    }

    if (!await _refreshSession()) {
      return response;
    }

    // Retry the original request with the newly issued access token
    try {
      return await _send(method, path, body: body, token: LocalCache.getJwtToken());
    } catch (e) {
      return _offlineResponse(e);
    }
  }

  Future<bool> _refreshSession() {
    return _refreshInFlight ??= _attemptTokenRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _attemptTokenRefresh() async {
    final String? refreshToken = LocalCache.getRefreshToken();
    if (refreshToken == null) {
      _sessionExpired.add(null);
      return false;
    }

    final http.Response response;
    try {
      response = await _send('POST', '/auth/refresh', body: {'refreshToken': refreshToken});
    } catch (e) {
      // Offline: keep the session, the next request will try again
      debugPrint('Automatic token refresh failed: $e');
      return false;
    }

    if (response.statusCode == 200) {
      // Refresh tokens are rotated: both tokens must be replaced
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      await LocalCache.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    }

    if (response.statusCode == 401 || response.statusCode == 400) {
      // Refresh token expired or revoked. Force session logout.
      _sessionExpired.add(null);
    }
    return false;
  }

  /// Fire-and-forget request that wakes a sleeping server while the user is still typing.
  void warmUp() {
    final healthUrl = Uri.parse(baseUrl).replace(path: '/actuator/health', query: null);
    _client.get(healthUrl).timeout(_timeout).then((_) {}, onError: (_) {});
  }

  /// Extracts the server's error message from a failed response.
  static String errorMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    } catch (_) {}
    return fallback;
  }

  // --- Exposed REST Call Interface ---

  Future<http.Response> get(String path) => _requestWithRetry('GET', path);

  Future<http.Response> post(String path, Object body) => _requestWithRetry('POST', path, body: body);

  Future<http.Response> put(String path, Object body) => _requestWithRetry('PUT', path, body: body);

  Future<http.Response> delete(String path) => _requestWithRetry('DELETE', path);

  void dispose() {
    _sessionExpired.close();
    _client.close();
  }
}
