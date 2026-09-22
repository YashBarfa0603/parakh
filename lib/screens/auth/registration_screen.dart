import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/ashoka_emblem.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/parakh_app_bar.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _inspectorIdController = TextEditingController();
  final _departmentController = TextEditingController(text: 'Legal Metrology Department');
  final _designationController = TextEditingController(text: 'Inspector of Legal Metrology');
  final _officeController = TextEditingController();
  final _stateController = TextEditingController(text: 'Delhi');
  final _districtController = TextEditingController(text: 'Central Delhi');
  final _cityController = TextEditingController(text: 'New Delhi');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _inspectorIdController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _officeController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthServices().signup(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        inspectorId: _inspectorIdController.text,
        department: _departmentController.text,
        designation: _designationController.text,
        office: _officeController.text,
        state: _stateController.text,
        district: _districtController.text,
        city: _cityController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: ParakhColors.compliant),
              SizedBox(width: 8),
              Text('Registration Submitted'),
            ],
          ),
          content: const Text(
            'Your inspector account registration has been submitted and approved successfully.\n\nYou can now sign in immediately with your email and password.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              child: const Text('Return to Sign In'),
            ),
          ],
        ),
      );
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ParakhColors.accent,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.backgroundDarker,
      appBar: const ParakhAppBar(
        title: 'Inspector Registration',
        subtitle: 'Government of India • Legal Metrology',
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Submitting inspector profile to Legal Metrology portal...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: ParakhColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: AshokaEmblem(size: 72, color: ParakhColors.accent),
                          ),
                        ),
                        const Text(
                          'Register Official Inspector Profile',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ParakhColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Please provide your official department credentials for administrative verification.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: ParakhColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ParakhColors.nonCompliantLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ParakhColors.nonCompliant.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: ParakhColors.nonCompliant, size: 18),
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
                          const SizedBox(height: 12),
                        ],

                        // Personal Details
                        _buildSectionHeader('1. Personal Details'),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Official Email *',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Phone Number *',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                        ),

                        // Official Department Details
                        _buildSectionHeader('2. Official Department Details'),
                        TextFormField(
                          controller: _inspectorIdController,
                          decoration: const InputDecoration(
                            labelText: 'Government Inspector ID / Badge No. *',
                            hintText: 'e.g. LM-DL-2024-001',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Inspector ID is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _departmentController,
                          decoration: const InputDecoration(
                            labelText: 'Department Name *',
                            prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Department is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _designationController,
                          decoration: const InputDecoration(
                            labelText: 'Designation *',
                            prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Designation is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _officeController,
                          decoration: const InputDecoration(
                            labelText: 'Office Location / Branch *',
                            hintText: 'e.g. Zonal Office North',
                            prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Office location is required' : null,
                        ),

                        // Jurisdiction / Location
                        _buildSectionHeader('3. Jurisdiction / Location'),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(labelText: 'State *'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _districtController,
                                decoration: const InputDecoration(labelText: 'District *'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'City is required' : null,
                        ),

                        // Security
                        _buildSectionHeader('4. Security & Access'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password (min 8 characters) *',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 8 ? 'Minimum 8 characters' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password *',
                            prefixIcon: Icon(Icons.lock_reset_rounded, size: 20),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Please confirm password' : null,
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleRegister,
                            child: const Text(
                              'Submit Registration for Verification',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
