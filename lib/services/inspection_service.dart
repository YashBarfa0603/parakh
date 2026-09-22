import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../model/analysis_result_model.dart';
import '../model/declaration_model.dart';
import '../model/finding_model.dart';
import '../model/image_upload_response.dart';
import '../model/inspection_model.dart';
import '../model/report_model.dart';
import 'api_service.dart';

class InspectionService {
  static final InspectionService _instance = InspectionService._internal();
  factory InspectionService() => _instance;
  InspectionService._internal();

  final ApiService _apiService = ApiService();
  static const String _prefsKeyInspectionHistory = 'parakh_inspection_history';

  /// In-memory cache of inspections
  final List<InspectionModel> _cachedInspections = [];

  List<InspectionModel> get cachedInspections => List.unmodifiable(_cachedInspections);

  Future<void> init() async {
    await _loadFromLocal();
  }

  /// Create a new inspection
  Future<InspectionModel> createInspection() async {
    try {
      final response = await _apiService.dio.post('/inspections/', data: {});
      final data = response.data;
      final newInspection = InspectionModel.fromJson(data);
      _cachedInspections.insert(0, newInspection);
      await _saveToLocal();
      return newInspection;
    } on DioException catch (e) {
      String? detail;
      if (e.response?.data is Map) {
        final d = e.response?.data['detail'];
        if (d is String) {
          detail = d;
        } else if (d is List && d.isNotEmpty) {
          detail = d.map((x) => x is Map ? x['msg'] : x.toString()).join(', ');
        }
      }
      throw Exception(detail ?? e.message ?? 'Failed to initialize inspection session.');
    }
  }

  /// Upload package image with angle and capture source
  Future<ImageUploadResponse> uploadImage({
    required int inspectionId,
    required String imagePath,
    required ImageAngle angle,
    required CaptureSource source,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath, filename: fileName),
        'angle': angle.value,
        'capture_source': source.value,
      });

      final response = await _apiService.dio.post(
        '/inspections/$inspectionId/images',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      return ImageUploadResponse.fromJson(response.data);
    } on DioException catch (e) {
      String? detail;
      if (e.response?.data is Map) {
        final d = e.response?.data['detail'];
        if (d is String) {
          detail = d;
        } else if (d is List && d.isNotEmpty) {
          detail = d.map((x) => x is Map ? x['msg'] : x.toString()).join(', ');
        }
      }
      throw Exception(detail ?? e.message ?? 'Image upload failed. Please try again.');
    }
  }

  /// Get image status of inspection
  Future<Map<String, dynamic>> getImageStatus(int inspectionId) async {
    try {
      final response = await _apiService.dio.get('/inspections/$inspectionId/images/status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Failed to check image status.');
    }
  }

  /// Trigger OCR extraction and rule evaluation
  Future<AnalysisResultModel> analyzeInspection(int inspectionId) async {
    try {
      final response = await _apiService.dio.post(
        '/inspections/$inspectionId/analyze',
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final result = AnalysisResultModel.fromJson(response.data);

      // Refresh cached inspection data
      await getInspection(inspectionId);

      return result;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Label analysis failed. Please verify images and retry.');
    }
  }

  /// Fetch full inspection details
  Future<InspectionModel> getInspection(int inspectionId) async {
    try {
      final response = await _apiService.dio.get('/inspections/$inspectionId');
      final inspection = InspectionModel.fromJson(response.data);
      
      final idx = _cachedInspections.indexWhere((i) => i.id == inspectionId);
      if (idx >= 0) {
        _cachedInspections[idx] = inspection;
      } else {
        _cachedInspections.insert(0, inspection);
      }
      await _saveToLocal();
      return inspection;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Failed to retrieve inspection details.');
    }
  }

  /// Fetch extracted declarations
  Future<List<DeclarationModel>> getDeclarations(int inspectionId) async {
    try {
      final response = await _apiService.dio.get('/inspections/$inspectionId/declarations');
      final data = response.data;
      final rawList = (data['declarations'] as List<dynamic>?) ?? [];
      return rawList.map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Failed to retrieve declarations.');
    }
  }

  /// Update declarations after inspector review / edit
  Future<void> updateDeclarations(int inspectionId, List<DeclarationModel> declarations) async {
    try {
      final payload = {
        'declarations': declarations.map((d) => d.toJson()).toList(),
      };
      await _apiService.dio.put(
        '/inspections/$inspectionId/declarations',
        data: payload,
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Failed to save updated declarations.');
    }
  }

  /// Fetch compliance findings
  Future<List<FindingModel>> getFindings(int inspectionId) async {
    try {
      final response = await _apiService.dio.get('/inspections/$inspectionId/findings');
      final data = response.data;
      final rawList = (data['findings'] as List<dynamic>?) ?? [];
      return rawList.map((e) => FindingModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Failed to retrieve findings.');
    }
  }

  /// Finalize inspection and generate locked PDF report
  Future<ReportModel> finalizeInspection(int inspectionId) async {
    try {
      final response = await _apiService.dio.post('/inspections/$inspectionId/finalize');
      final report = ReportModel.fromJson(response.data);
      // Refresh inspection status
      await getInspection(inspectionId);
      return report;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Failed to finalize inspection.');
    }
  }

  // Download report
  Future<Uint8List> getReportBytes(int inspectionId, {String format = 'pdf'}) async {
    try {
      final response = await _apiService.dio.get<List<int>>(
        '/inspections/$inspectionId/report',
        queryParameters: {'format': format},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(detail ?? e.message ?? 'Failed to download report ($format).');
    }
  }

  Future<Uint8List> getReportPdfBytes(int inspectionId) =>
      getReportBytes(inspectionId, format: 'pdf');


  /// Helper to record local inspections and sync
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKeyInspectionHistory);
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        _cachedInspections.clear();
        for (final item in list) {
          _cachedInspections.add(InspectionModel.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('Error loading cached inspections: $e');
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _cachedInspections.map((i) => i.toJson()).toList();
      await prefs.setString(_prefsKeyInspectionHistory, jsonEncode(list));
    } catch (e) {
      debugPrint('Error caching inspections: $e');
    }
  }
}
