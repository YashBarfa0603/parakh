import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/ashoka_emblem.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'test.inspector@example.com');
  final _passwordController = TextEditingController(text: 'Password123!');

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AuthServices().login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      final inspector = res.inspector;
      if (inspector.isPending) {
        _showPendingAccountDialog();
      } else if (inspector.isRejected) {
        _showRejectedAccountDialog(inspector.rejectionReason);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPendingAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: ParakhColors.needsReview),
            SizedBox(width: 8),
            Text('Account Pending'),
          ],
        ),
        content: const Text(
          'Your inspector account is awaiting administrative approval from the State Legal Metrology Controller.\n\nYou will be authorized to log in once your credentials have been verified.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showRejectedAccountDialog(String? reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: ParakhColors.nonCompliant),
            SizedBox(width: 8),
            Text('Account Rejected'),
          ],
        ),
        content: Text(
          'Your inspector registration was not approved.\n\nReason: ${reason ?? "Administrative review did not match department records."}',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog() {
    final textController = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Server Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend API URL:',
              style: TextStyle(fontSize: 13, color: ParakhColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: const InputDecoration(hintText: 'http://192.168.1.4:8000/api'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Quick Presets:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ParakhColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Mac Wi-Fi (192.168.1.4)'),
                  onPressed: () => textController.text = 'http://192.168.1.4:8000/api',
                ),
                ActionChip(
                  label: const Text('Simulator (127.0.0.1)'),
                  onPressed: () => textController.text = 'http://127.0.0.1:8000/api',
                ),
                ActionChip(
                  label: const Text('Android (10.0.2.2)'),
                  onPressed: () => textController.text = 'http://10.0.2.2:8000/api',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppConfig.resetApiBaseUrl();
              Navigator.pop(dialogContext);
              setState(() {});
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.setApiBaseUrl(textController.text);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerChip(String label, String url) {
    final isSelected = AppConfig.apiBaseUrl == url;
    return InkWell(
      onTap: () async {
        await AppConfig.setApiBaseUrl(url);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? ParakhColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? ParakhColors.accent : ParakhColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : ParakhColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Authenticating credentials with Legal Metrology portal...',
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle background government building / courthouse watermark silhouette
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.04,
                  child: CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _GovernmentSilhouettePainter(),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          // Ashoka Lion Capital Emblem with Satyameva Jayate
                          const Center(
                            child: AshokaEmblem(size: 84, color: ParakhColors.accent),
                          ),
                          const SizedBox(height: 14),

                          // Brand Title: PARAKH
                          const Text(
                            'PARAKH',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: ParakhColors.accent,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Subtitle: Digital Inspection for a Fairer Marketplace
                          const Text(
                            'Digital Inspection for a Fairer Marketplace',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: ParakhColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Error Message Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ParakhColors.nonCompliantLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ParakhColors.nonCompliant.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: ParakhColors.nonCompliant,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: ParakhColors.nonCompliant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email Address Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: ParakhColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              hintStyle: const TextStyle(
                                color: ParakhColors.textTertiary,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                                color: ParakhColors.textSecondary,
                              ),
                              fillColor: ParakhColors.background,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: ParakhColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: ParakhColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: ParakhColors.accent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: ParakhColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(
                                color: ParakhColors.textTertiary,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: ParakhColors.textSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: ParakhColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              fillColor: ParakhColors.background,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: ParakhColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: ParakhColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: ParakhColors.accent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Login Primary Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ParakhColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Forgot Password Link
                          Center(
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please contact your State Department Admin to reset credentials.'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ParakhColors.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // OR Line Divider
                          Row(
                            children: [
                              const Expanded(child: Divider(color: ParakhColors.divider)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ParakhColors.textTertiary,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: ParakhColors.divider)),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Create New Account Button
                          SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(AppRoutes.signup);
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: ParakhColors.accent,
                                side: const BorderSide(color: ParakhColors.border, width: 1.2),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Create New Account',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Server Switcher
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildServerChip('USB / Local (127.0.0.1)', 'http://127.0.0.1:8000/api'),
                                _buildServerChip('Wi-Fi (10.126.150.17)', 'http://10.126.150.17:8000/api'),
                                _buildServerChip('Emulator (10.0.2.2)', 'http://10.0.2.2:8000/api'),
                                InkWell(
                                  onTap: _showConfigDialog,
                                  child: const Icon(Icons.settings_outlined, size: 16, color: ParakhColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Government Footer
                          Column(
                            children: const [
                              Text(
                                'Government of India',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ParakhColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Legal Metrology Department',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: ParakhColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GovernmentSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ParakhColors.accent
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Draw classical facade dome and columns outline
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.7)
      ..lineTo(w * 0.1, h * 0.7)
      ..lineTo(w * 0.1, h * 0.5)
      ..lineTo(w * 0.3, h * 0.5)
      ..lineTo(w * 0.35, h * 0.4)
      ..lineTo(w * 0.45, h * 0.4)
      ..cubicTo(w * 0.46, h * 0.15, w * 0.54, h * 0.15, w * 0.55, h * 0.4)
      ..lineTo(w * 0.65, h * 0.4)
      ..lineTo(w * 0.7, h * 0.5)
      ..lineTo(w * 0.9, h * 0.5)
      ..lineTo(w * 0.9, h * 0.7)
      ..lineTo(w, h * 0.7)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
