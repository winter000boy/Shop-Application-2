import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:repair_shop_app/database/local_cache.dart';

class ApiClient {
  // Base API endpoint configuration
  // Note: 10.0.2.2 points to localhost on host machine from standard Android Emulator
  static const String _defaultBaseUrl = 'http://10.0.2.2:8080/api/v1';
  static String baseUrl = _defaultBaseUrl;

  final http.Client _client = http.Client();
  bool _isRefreshing = false;

  Map<String, String> _getHeaders(String? customJwt) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = customJwt ?? LocalCache.getJwtToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Generic Request Handler
  Future<http.Response> _requestWithRetry(
    String method,
    String path, {
    Object? body,
  }) async {
    final Uri url = Uri.parse('$baseUrl$path');
    final String? token = LocalCache.getJwtToken();
    
    http.Response response;
    try {
      if (method == 'GET') {
        response = await _client.get(url, headers: _getHeaders(token));
      } else if (method == 'POST') {
        response = await _client.post(url, headers: _getHeaders(token), body: jsonEncode(body));
      } else if (method == 'PUT') {
        response = await _client.put(url, headers: _getHeaders(token), body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await _client.delete(url, headers: _getHeaders(token));
      } else {
        throw UnsupportedError('HTTP method $method not supported');
      }
    } catch (e) {
      // Return a simulated connection failure response for offline state
      return http.Response(jsonEncode({'error': 'Connection failed', 'message': e.toString()}), 503);
    }

    // Intercept 401 Unauthorized errors to attempt automatic session refreshing
    if (response.statusCode == 401 && token != null && !_isRefreshing) {
      _isRefreshing = true;
      final bool refreshSuccess = await _attemptTokenRefresh();
      _isRefreshing = false;

      if (refreshSuccess) {
        // Retry the original query with the newly generated JWT token
        final String? newToken = LocalCache.getJwtToken();
        if (method == 'GET') {
          return await _client.get(url, headers: _getHeaders(newToken));
        } else if (method == 'POST') {
          return await _client.post(url, headers: _getHeaders(newToken), body: jsonEncode(body));
        } else if (method == 'PUT') {
          return await _client.put(url, headers: _getHeaders(newToken), body: jsonEncode(body));
        } else if (method == 'DELETE') {
          return await _client.delete(url, headers: _getHeaders(newToken));
        }
      } else {
        // Refresh token expired or revoked. Force session logout.
        await LocalCache.clearSession();
      }
    }

    return response;
  }

  Future<bool> _attemptTokenRefresh() async {
    final String? refreshToken = LocalCache.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final Uri url = Uri.parse('$baseUrl/auth/refresh');
      final http.Response response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String newJwt = data['accessToken'] as String;
        await LocalCache.saveAccessToken(newJwt);
        return true;
      }
    } catch (e) {
      print('Automatic token refresh failed: $e');
    }
    return false;
  }

  // --- Exposed REST Call Interface ---

  Future<http.Response> get(String path) => _requestWithRetry('GET', path);

  Future<http.Response> post(String path, Object body) => _requestWithRetry('POST', path, body: body);

  Future<http.Response> put(String path, Object body) => _requestWithRetry('PUT', path, body: body);

  Future<http.Response> delete(String path) => _requestWithRetry('DELETE', path);
}
