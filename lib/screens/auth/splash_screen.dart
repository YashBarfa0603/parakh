import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/inspection_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    await AuthServices().init();
    await InspectionService().init();

    if (!mounted) return;

    if (AuthServices().isAuthenticated) {
      final inspector = await AuthServices().getCurrentInspector(forceRefresh: true);
      if (!mounted) return;
      if (inspector != null && inspector.isApproved) {
        await InspectionService().loadForInspector(inspector.id);
        await InspectionService().fetchMyInspections(inspectorId: inspector.id);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
        return;
      }
    }

    await AuthServices().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _showConfigDialog() {
    final textController = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Configure Backend API URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the base API URL for this device:',
              style: TextStyle(fontSize: 13, color: ParakhColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://10.0.2.2:8000/api',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppConfig.resetApiBaseUrl();
              Navigator.pop(dialogContext);
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.setApiBaseUrl(textController.text);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Top config icon
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: ParakhColors.textSecondary, size: 22),
                  onPressed: _showConfigDialog,
                  tooltip: 'Configure Backend URL',
                ),
              ),

              const Spacer(),

              // Center Official Emblem & Hierarchy
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/ashoka_stambh_transparent.png',
                      height: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/ashoka_stambh.jpg',
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'PARAKH',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.0,
                        color: ParakhColors.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Legal Metrology Inspection Platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: ParakhColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(ParakhColors.accent),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom official authority footer
              Column(
                children: [
                  const Text(
                    'GOVERNMENT OF INDIA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: ParakhColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Department of Consumer Affairs • Legal Metrology Division',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: ParakhColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
