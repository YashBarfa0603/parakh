import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants.dart';
import 'core/routes.dart';
import 'core/theme.dart';

/// Global navigator key for programmatic navigation (e.g. 401 auto-logout)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set official system chrome styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ParakhColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize stored configuration
  await AppConfig.init();

  runApp(const ParakhApp());
}

class ParakhApp extends StatelessWidget {
  const ParakhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PARAKH Legal Metrology',
      debugShowCheckedModeBanner: false,
      theme: ParakhTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
