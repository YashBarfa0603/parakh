import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../model/auth_response_model.dart';
import '../model/inspector_model.dart';
import 'api_service.dart';

class AuthServices {
  static final AuthServices _instance = AuthServices._internal();
  factory AuthServices() => _instance;
  AuthServices._internal();

  final ApiService _apiService = ApiService();
  static const String _prefsKeyInspector = 'parakh_cached_inspector';
  InspectorModel? _currentInspector;

  InspectorModel? get currentInspector => _currentInspector;

  Future<void> init() async {
    await _apiService.initToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefsKeyInspector);
      if (cachedJson != null) {
        _currentInspector = InspectorModel.fromJson(jsonDecode(cachedJson));
      }
    } catch (_) {}
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );
      final authResponse = AuthResponseModel.fromJson(response.data);
      await _apiService.setToken(authResponse.accessToken);
      _currentInspector = authResponse.inspector;
      await _cacheInspector(authResponse.inspector);
      return authResponse;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot reach backend at ${AppConfig.apiBaseUrl}. Please ensure FastAPI is running on port 8000. Use 127.0.0.1 on Mac/iOS, or 10.0.2.2 on Android emulator.',
        );
      }
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Login failed. Please check your credentials.');
    } catch (e) {
      throw Exception('An unexpected error occurred during login: $e');
    }
  }

  Future<AuthResponseModel> signup({
    required String name,
    required String email,
    required String phone,
    required String inspectorId,
    required String department,
    required String designation,
    required String office,
    required String state,
    required String district,
    required String city,
    required String password,
  }) async {
    final data = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'inspector_id': inspectorId.trim(),
      'department': department.trim(),
      'designation': designation.trim(),
      'office': office.trim(),
      'state': state.trim(),
      'district': district.trim(),
      'city': city.trim(),
      'password': password,
    };
    try {
      final response = await _apiService.dio.post('/auth/signup', data: data);
      final authResponse = AuthResponseModel.fromJson(response.data);
      await _apiService.setToken(authResponse.accessToken);
      _currentInspector = authResponse.inspector;
      await _cacheInspector(authResponse.inspector);
      return authResponse;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Registration failed. Please check your details.');
    } catch (e) {
      throw Exception('An unexpected error occurred during registration: $e');
    }
  }

  Future<InspectorModel?> getCurrentInspector({bool forceRefresh = false}) async {
    if (_currentInspector != null && !forceRefresh) {
      return _currentInspector;
    }
    if (!_apiService.isAuthenticated) {
      _currentInspector = null;
      return null;
    }
    try {
      final response = await _apiService.dio.get('/auth/me');
      _currentInspector = InspectorModel.fromJson(response.data);
      await _cacheInspector(_currentInspector!);
      return _currentInspector;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _currentInspector = null;
        return null;
      }
      return _currentInspector;
    } catch (_) {
      if (!_apiService.isAuthenticated) {
        _currentInspector = null;
        return null;
      }
      return _currentInspector;
    }
  }

  Future<void> _cacheInspector(InspectorModel inspector) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyInspector, jsonEncode(inspector.toJson()));
    } catch (_) {}
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    _currentInspector = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyInspector);
    } catch (_) {}
  }

  bool get isAuthenticated => _apiService.isAuthenticated;
}
