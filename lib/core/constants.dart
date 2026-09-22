import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application configuration and constants for PARAKH
class AppConfig {
  static String get defaultApiBaseUrl => 'http://192.168.1.4:8000/api';

  static const String _prefsKeyApiBaseUrl = 'parakh_api_base_url';

  static String _activeApiBaseUrl = 'http://192.168.1.4:8000/api';

  /// Get current active API Base URL
  static String get apiBaseUrl => _activeApiBaseUrl;

  /// Initialize stored URL configuration
  static Future<void> init() async {
    _activeApiBaseUrl = defaultApiBaseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKeyApiBaseUrl);
      if (stored != null && stored.trim().isNotEmpty) {
        _activeApiBaseUrl = stored;
      } else {
        _activeApiBaseUrl = defaultApiBaseUrl;
      }
    } catch (e) {
      debugPrint('Error loading API URL from preferences: $e');
      _activeApiBaseUrl = defaultApiBaseUrl;
    }
  }

  /// Update the API Base URL (for device testing, staging, production)
  static Future<void> setApiBaseUrl(String url) async {
    var trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (!trimmed.endsWith('/api')) {
      trimmed = '$trimmed/api';
    }
    _activeApiBaseUrl = trimmed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyApiBaseUrl, _activeApiBaseUrl);
    } catch (e) {
      debugPrint('Error saving API URL to preferences: $e');
    }
  }

  /// Reset to default API Base URL
  static Future<void> resetApiBaseUrl() async {
    _activeApiBaseUrl = defaultApiBaseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyApiBaseUrl);
    } catch (e) {
      debugPrint('Error resetting API URL: $e');
    }
  }
}

/// Routes in PARAKH
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String shell = '/shell';
  static const String home = '/home';

  static const String scannedProducts = '/products/scanned';
  static const String compliantProducts = '/products/compliant';
  static const String nonCompliantProducts = '/products/non-compliant';

  static const String camera = '/scan/camera';
  static const String captureReview = '/scan/capture-review';
  static const String analysis = '/scan/analysis';
  static const String qrScan = '/scan/qr';

  static const String inspectionResult = '/inspection/result';
  static const String evidenceViewer = '/inspection/evidence';
  static const String declarationsReview = '/inspection/declarations';
  static const String inspectorReview = '/inspection/review';
  static const String inspectionComplete = '/inspection/complete';

  static const String reportsList = '/reports';
  static const String viewReport = '/reports/view';
  static const String editReport = '/reports/edit';

  static const String more = '/more';
  static const String profile = '/profile';
  static const String assistant = '/assistant';
}

/// Compliance status mapping backend PASS, FAIL, REVIEW
enum ComplianceStatus {
  compliant,
  nonCompliant,
  needsReview,
  pending;

  static ComplianceStatus fromBackend(String? value) {
    switch (value?.toUpperCase()) {
      case 'PASS':
      case 'COMPLIANT':
        return ComplianceStatus.compliant;
      case 'FAIL':
      case 'NON-COMPLIANT':
      case 'NON_COMPLIANT':
        return ComplianceStatus.nonCompliant;
      case 'REVIEW':
      case 'NEEDS_REVIEW':
      case 'FLAGGED':
        return ComplianceStatus.needsReview;
      default:
        return ComplianceStatus.pending;
    }
  }

  String toBackend() {
    switch (this) {
      case ComplianceStatus.compliant:
        return 'PASS';
      case ComplianceStatus.nonCompliant:
        return 'FAIL';
      case ComplianceStatus.needsReview:
        return 'REVIEW';
      case ComplianceStatus.pending:
        return 'PENDING';
    }
  }

  String get label {
    switch (this) {
      case ComplianceStatus.compliant:
        return 'COMPLIANT';
      case ComplianceStatus.nonCompliant:
        return 'NON-COMPLIANT';
      case ComplianceStatus.needsReview:
        return 'NEEDS REVIEW';
      case ComplianceStatus.pending:
        return 'PENDING';
    }
  }
}

/// Package image angles
enum ImageAngle {
  front('FRONT', 'Front Face'),
  back('BACK', 'Back Label / Nutrition'),
  top('TOP', 'Top Lid / Seal'),
  bottom('BOTTOM', 'Bottom / Expiry / MRP'),
  left('LEFT', 'Left Side'),
  right('RIGHT', 'Right Side');

  final String value;
  final String label;

  const ImageAngle(this.value, this.label);

  static ImageAngle fromString(String? val) {
    for (final angle in ImageAngle.values) {
      if (angle.value.toUpperCase() == val?.toUpperCase()) {
        return angle;
      }
    }
    return ImageAngle.front;
  }
}

/// Image capture source
enum CaptureSource {
  camera('CAMERA'),
  gallery('GALLERY');

  final String value;
  const CaptureSource(this.value);
}

/// Inspector account status
enum AccountStatus {
  pending('PENDING', 'Pending Approval'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected');

  final String value;
  final String label;
  const AccountStatus(this.value, this.label);

  static AccountStatus fromString(String? val) {
    for (final status in AccountStatus.values) {
      if (status.value.toUpperCase() == val?.toUpperCase()) {
        return status;
      }
    }
    return AccountStatus.pending;
  }
}
