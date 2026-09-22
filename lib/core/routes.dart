import 'package:flutter/material.dart';
import '../model/report_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/compliant_products_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/non_compliant_products_screen.dart';
import '../screens/home/scanned_products_screen.dart';
import '../screens/main_shell.dart';
import '../screens/more/assistant_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/more/profile_screen.dart';
import '../screens/reports/edit_report_screen.dart';
import '../screens/reports/reports_list_screen.dart';
import '../screens/reports/view_report_screen.dart';
import '../screens/result/declarations_review_screen.dart';
import '../screens/result/evidence_screen.dart';
import '../screens/result/inspection_result_screen.dart';
import '../screens/review/inspection_complete_screen.dart';
import '../screens/review/inspector_review_screen.dart';
import '../screens/scan/analysis_screen.dart';
import '../screens/scan/camera_screen.dart';
import '../screens/scan/capture_review_screen.dart';
import '../screens/scan/qr_scan_screen.dart';
import 'constants.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const RegistrationScreen());

      case AppRoutes.shell:
        return MaterialPageRoute(
          builder: (_) => MainShell(
            initialTab: args is int ? args : 0,
          ),
        );

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.scannedProducts:
        return MaterialPageRoute(
          builder: (_) => ScannedProductsScreen(
            initialFilter: args is ComplianceStatus ? args : null,
          ),
        );

      case AppRoutes.compliantProducts:
        return MaterialPageRoute(builder: (_) => const CompliantProductsScreen());

      case AppRoutes.nonCompliantProducts:
        return MaterialPageRoute(builder: (_) => const NonCompliantProductsScreen());

      case AppRoutes.camera:
        return MaterialPageRoute(
          builder: (_) => CameraScreen(
            existingInspectionId: args is int ? args : null,
          ),
        );

      case AppRoutes.captureReview:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CaptureReviewScreen(
            imagePath: map['imagePath'] as String,
            angle: map['angle'] as ImageAngle,
            source: map['source'] as CaptureSource,
            inspectionId: map['inspectionId'] as int,
          ),
        );

      case AppRoutes.analysis:
        return MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            inspectionId: args as int,
          ),
        );

      case AppRoutes.qrScan:
        return MaterialPageRoute(builder: (_) => const QrScanScreen());

      case AppRoutes.inspectionResult:
        return MaterialPageRoute(
          builder: (_) => InspectionResultScreen(
            inspectionId: args as int,
          ),
        );

      case AppRoutes.evidenceViewer:
        return MaterialPageRoute(
          builder: (_) => EvidenceScreen(
            inspectionId: args as int,
          ),
        );

      case AppRoutes.declarationsReview:
        return MaterialPageRoute(
          builder: (_) => DeclarationsReviewScreen(
            inspectionId: args as int,
          ),
        );

      case AppRoutes.inspectorReview:
        return MaterialPageRoute(
          builder: (_) => InspectorReviewScreen(
            inspectionId: args as int,
          ),
        );

      case AppRoutes.inspectionComplete:
        return MaterialPageRoute(
          builder: (_) => InspectionCompleteScreen(
            report: args as ReportModel,
          ),
        );

      case AppRoutes.reportsList:
        return MaterialPageRoute(builder: (_) => const ReportsListScreen());

      case AppRoutes.viewReport:
        return MaterialPageRoute(
          builder: (_) => ViewReportScreen(
            inspectionId: args as int,
          ),
        );

      case AppRoutes.editReport:
        return MaterialPageRoute(
          builder: (_) => EditReportScreen(
            inspectionId: args as int,
          ),
        );

      case AppRoutes.more:
        return MaterialPageRoute(builder: (_) => const MoreScreen());

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppRoutes.assistant:
        return MaterialPageRoute(builder: (_) => const AssistantScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
