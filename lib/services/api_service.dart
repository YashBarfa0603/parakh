import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../main.dart' show navigatorKey;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  static const String _prefsKeyToken = 'parakh_auth_token';
  String? _authToken;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Normalize base URL so it ends with /api/
          var base = AppConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
          if (!base.endsWith('/api')) {
            base = '$base/api';
          }
          options.baseUrl = '$base/';

          // Strip any leading '/' or 'api/' so it resolves cleanly relative to baseUrl
          var path = options.path;
          if (path.startsWith('/api/')) {
            path = path.substring(5);
          } else if (path.startsWith('api/')) {
            path = path.substring(4);
          } else if (path.startsWith('/')) {
            path = path.substring(1);
          }
          options.path = path;

          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          } else {
            options.headers.remove('Authorization');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Auto-logout on 401 (expired/invalid token)
          if (error.response?.statusCode == 401) {
            final detail = error.response?.data is Map
                ? error.response?.data['detail']
                : null;
            // Only auto-logout for token-related 401s, not login failures
            if (detail == 'Invalid or expired token' ||
                detail == 'Invalid Token' ||
                detail == 'Inspector not Found') {
              debugPrint('Token expired/invalid — auto-logging out');
              _handleTokenExpired();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Handle expired token: clear storage and redirect to login
  Future<void> _handleTokenExpired() async {
    _authToken = null;
    dio.options.headers.remove('Authorization');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyToken);
      await prefs.remove('parakh_cached_inspector');
    } catch (_) {}

    // Navigate to login screen
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  /// Initialize token from storage
  Future<void> initToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_prefsKeyToken);
      if (_authToken != null && _authToken!.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $_authToken';
      } else {
        dio.options.headers.remove('Authorization');
      }
    } catch (_) {}
  }

  /// Save token in memory and preferences
  Future<void> setToken(String token) async {
    _authToken = token;
    dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyToken, token);
    } catch (_) {}
  }

  /// Clear token on logout
  Future<void> clearToken() async {
    _authToken = null;
    dio.options.headers.remove('Authorization');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyToken);
    } catch (_) {}
  }

  String? get token => _authToken;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
}